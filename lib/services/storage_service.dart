import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';

class StorageService {
  
  static Future<String?> pickSavePath({String? suggestedName}) async {
    final typeGroup = const XTypeGroup(label: 'json', extensions: ['json']);
    final path = await getSavePath(
      acceptedTypeGroups: [typeGroup],
      suggestedName: suggestedName != null ? '$suggestedName.json' : 'project.json',
      confirmButtonText: 'Lưu',
    );
    return path;
  }

  static Future<String?> pickOpenPath() async {
    final typeGroup = const XTypeGroup(label: 'json', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    return file?.path;
  }

  static Future<Map<String, dynamic>> readJson(String path) async {
    final f = File(path);
    final text = await f.readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Future<void> writeJson(String path, Map<String, dynamic> data) async {
    final f = File(path);
    await f.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }
}
