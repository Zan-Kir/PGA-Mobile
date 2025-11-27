import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../services/file_save_service.dart';

class SaveShareDialog extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const SaveShareDialog({super.key, required this.bytes, required this.fileName});

  @override
  State<SaveShareDialog> createState() => _SaveShareDialogState();
}

class _SaveShareDialogState extends State<SaveShareDialog> {
  bool _loading = false;

  Future<void> _onSave() async {
    setState(() => _loading = true);
    try {
      final result = await FileSaveService.saveFileWithDialog(bytes: widget.bytes, fileName: widget.fileName);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onShare() async {
    setState(() => _loading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.fileName}');
      await tempFile.writeAsBytes(widget.bytes, flush: true);
      // shareXFiles está deprecado em algumas versões, usar SharePlus.instance.share quando migrarmos.
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(tempFile.path)], text: widget.fileName);
      if (mounted) {
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Exportar arquivo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.iconTheme.color),
                  onPressed: _loading ? null : () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(widget.fileName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (_loading) LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  icon: Icon(Icons.share, color: theme.colorScheme.primary),
                  label: Text('Compartilhar', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  onPressed: _loading ? null : _onShare,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 6,
                  ),
                  icon: Icon(Icons.save, color: theme.colorScheme.onPrimary),
                  label: Text('Salvar', style: TextStyle(color: theme.colorScheme.onPrimary)),
                  onPressed: _loading ? null : _onSave,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(null),
              child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}
