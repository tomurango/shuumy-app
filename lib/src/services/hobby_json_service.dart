import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../models/hobby.dart';

class HobbyJsonService {
  static const _fileName = 'hobbies.json';

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Hobby>> loadHobbies() async {
    try {
      final file = await _getLocalFile();
      if (!(await file.exists())) return [];

      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.map((e) => Hobby.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHobbies(List<Hobby> hobbies) async {
    final file = await _getLocalFile();
    final jsonData = hobbies.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }
}
