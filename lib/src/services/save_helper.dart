import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class SaveHelper {
  static Future<String> saveBytesToDownloads(Uint8List bytes, String fileName) async {
    Directory? targetDir;
    try {
      final exts = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (exts != null && exts.isNotEmpty) targetDir = exts.first;
    } catch (_) {
      targetDir = null;
    }

    if (targetDir != null) {
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
