import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

class FileSaveService {
  static Future<String?> saveFileWithDialog({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/$fileName';
    final file = File(tempPath);
    await file.writeAsBytes(bytes, flush: true);

    final params = SaveFileDialogParams(
      sourceFilePath: tempPath,
      fileName: fileName,
    );

    try {
      final result = await FlutterFileDialog.saveFile(params: params);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao abrir diálogo de salvar: $e');
      }
      rethrow;
    }
  }
}
