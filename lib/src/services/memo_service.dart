import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/hobby_memo.dart';

class MemoService {
  static const _fileName = 'memos.json';

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<HobbyMemo>> loadMemos() async {
    try {
      final file = await _getLocalFile();
      if (!(await file.exists())) return [];

      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.map((e) => HobbyMemo.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<HobbyMemo>> loadMemosForHobby(String hobbyId) async {
    final allMemos = await loadMemos();
    final hobbyMemos = allMemos.where((memo) => memo.hobbyId == hobbyId).toList();

    // ピン留めメモを先に、その後は作成日時の新しい順にソート
    hobbyMemos.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return hobbyMemos;
  }

  static Future<void> saveMemos(List<HobbyMemo> memos) async {
    final file = await _getLocalFile();
    final jsonData = memos.map((m) => m.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  static Future<void> addMemo(HobbyMemo memo) async {
    final memos = await loadMemos();
    memos.add(memo);
    await saveMemos(memos);
  }

  static Future<void> updateMemo(HobbyMemo updatedMemo) async {
    final memos = await loadMemos();
    final index = memos.indexWhere((m) => m.id == updatedMemo.id);
    if (index != -1) {
      memos[index] = updatedMemo;
      await saveMemos(memos);
    }
  }

  static Future<void> deleteMemo(String memoId) async {
    final memos = await loadMemos();
    memos.removeWhere((m) => m.id == memoId);
    await saveMemos(memos);
  }

  static Future<void> togglePinMemo(String memoId) async {
    final memos = await loadMemos();
    final index = memos.indexWhere((m) => m.id == memoId);
    if (index != -1) {
      memos[index] = memos[index].copyWith(isPinned: !memos[index].isPinned);
      await saveMemos(memos);
    }
  }

  static Future<int> getMemoCountForHobby(String hobbyId) async {
    final memos = await loadMemosForHobby(hobbyId);
    return memos.length;
  }
}