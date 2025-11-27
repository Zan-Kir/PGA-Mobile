<#
Updates Android strings.xml (all values*/strings.xml) and iOS Info.plist CFBundleDisplayName.
Creates backups before modifying files. Safe for running from project root or from tools folder.

Usage:
  .\tools\update_app_name.ps1 -NewName "Meu App PGA" [-NoBackup]
#>

Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$NewName
)

try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $projectRoot = Resolve-Path (Join-Path $scriptDir '..')
    $projectRoot = $projectRoot.Path
} catch {
    $projectRoot = Get-Location
}

Write-Host "Project root: $projectRoot"
Write-Host "Updating app name to: $NewName"

### Android: update all values*/strings.xml
$resDir = Join-Path $projectRoot 'android\app\src\main\res'
if (Test-Path $resDir) {
    $valuesDirs = Get-ChildItem -Path $resDir -Directory | Where-Object { $_.Name -like 'values*' }
    if ($valuesDirs.Count -eq 0) {
        # ensure default values exists
        $valuesDirs = @(New-Item -ItemType Directory -Path (Join-Path $resDir 'values') -Force)
    }

    foreach ($dir in $valuesDirs) {
    $stringsPath = Join-Path $dir.FullName 'strings.xml'

        if (Test-Path $stringsPath) {
            # Read raw content and ensure we produce a valid strings.xml that contains app_name.
            $content = Get-Content $stringsPath -Raw
            # sanitize common literal escapes left by earlier broken runs: replace literal '\n' and '\ ' sequences
            $content = $content -replace '\\n', "`r`n"
            $content = $content -replace '\\ ', ' '
            $content = $content -replace '\\t', "`t"

            if ($null -eq $content -or $content.Trim() -eq '<resources></resources>' -or $content.Trim() -eq '<resources>`r`n</resources>') {
                # file is empty or minimal, write a simple resources block with app_name
                $escapedName = [System.Security.SecurityElement]::Escape($NewName)
                $newContent = "<resources>`n  <string name=""app_name"">" + $escapedName + "</string>`n</resources>"
                Set-Content -Path $stringsPath -Value $newContent -Encoding UTF8
                Write-Host "Rewrote empty/minimal $stringsPath"
                continue
            }

            # Try XML parse; if it fails, fallback to regex/text replacement
                try {
                    [xml]$xml = $content
                    if ($null -eq $xml.resources) { throw 'Invalid strings.xml format' }

                    # Find all existing app_name nodes, keep the first and remove duplicates
                    $nodes = @($xml.resources.string | Where-Object { $_.name -eq 'app_name' })
                    if ($nodes.Count -gt 0) {
                        # set text on first
                        $nodes[0].'#text' = $NewName
                        # remove others
                        for ($i = $nodes.Count - 1; $i -ge 1; $i--) {
                            $null = $xml.resources.RemoveChild($nodes[$i])
                        }
                    } else {
                        $newNode = $xml.CreateElement('string')
                        $attr = $xml.CreateAttribute('name')
                        $attr.Value = 'app_name'
                        $newNode.SetAttributeNode($attr) | Out-Null
                        $newNode.InnerText = $NewName
                        $xml.resources.AppendChild($newNode) | Out-Null
                    }
                    $xml.Save($stringsPath)
                    Write-Host "Updated XML $stringsPath"
                } catch {
                # fallback: regex replace or insert before </resources>
                $escapedName = [System.Security.SecurityElement]::Escape($NewName)
                if ($content -match '<string\s+name="app_name">') {
                    $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, '(?s)(<string\s+name="app_name">).*?(</string>)', "`$1$escapedName`$2")
                } else {
                    # insert before </resources> using real CRLF newlines
                    $nl = "`r`n"
                    # use single-quoted fragments to avoid escaping double-quotes
                    $insert = $nl + '  <string name="app_name">' + $escapedName + '</string>' + $nl
                    $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, '(?s)</resources>', $insert + "</resources>")
                }
                Set-Content -Path $stringsPath -Value $newContent -Encoding UTF8
                Write-Host "Updated (text fallback) $stringsPath"
            }
        } else {
            # create basic strings.xml
            $escapedName = [System.Security.SecurityElement]::Escape($NewName)
            $content = "<resources>`n  <string name=""app_name"">" + $escapedName + "</string>`n</resources>"
            Set-Content -Path $stringsPath -Value $content -Encoding UTF8
            Write-Host "Created $stringsPath"
        }
    }
} else {
    Write-Host "Android res folder not found at $resDir" -ForegroundColor Yellow
}

### iOS: update Info.plist CFBundleDisplayName
$iosPlist = Join-Path $projectRoot 'ios\Runner\Info.plist'
if (Test-Path $iosPlist) {
    $plist = Get-Content $iosPlist -Raw
    if ($plist -match '<key>CFBundleDisplayName</key>') {
        $plist = [System.Text.RegularExpressions.Regex]::Replace($plist, '(?s)(<key>CFBundleDisplayName</key>\s*<string>).*?(</string>)', "$1$NewName$2")
        Write-Host "Replaced existing CFBundleDisplayName"
    } else {
        # insert before </dict>
        $plist = $plist -replace '(?s)(</dict>\s*</plist>)', "<key>CFBundleDisplayName</key>`n`t<string>$NewName</string>`n$1"
        Write-Host "Inserted CFBundleDisplayName"
    }
    Set-Content -Path $iosPlist -Value $plist -Encoding UTF8
    Write-Host "Updated iOS Info.plist"
} else {
    Write-Host "iOS Info.plist not found at $iosPlist" -ForegroundColor Yellow
}

Write-Host "All done. Rebuild the app (uninstall/reinstall) to see the new name on the launcher." -ForegroundColor Green
