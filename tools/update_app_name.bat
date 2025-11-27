@echo off
REM Simple wrapper to call the PowerShell script from cmd
REM Usage: update_app_name.bat "Meu App PGA"

if "%~1"=="" (
  echo Uso: update_app_name.bat "Novo Nome do App"
  exit /b 1
)

REM Support both: update_app_name.bat -NewName "Name"  OR update_app_name.bat "Name"
if /I "%~1"=="-NewName" (
  if "%~2"=="" (
    echo Uso: update_app_name.bat -NewName "Novo Nome do App"
    exit /b 1
  )
  set "NAME=%~2"
) else (
  set "NAME=%~1"
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_app_name.ps1" -NewName "%NAME%"
if %ERRORLEVEL% EQU 0 (
  echo Nome atualizado com sucesso.
) else (
  echo Ocorreu um erro ao atualizar o nome do app. Codigo: %ERRORLEVEL%
)
