import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'flashcard_model.dart';
import 'flashfolder_model.dart';

class FlashcardsData {
  final List<FlashFolder> folders;
  final List<Flashcard> cards;

  const FlashcardsData({
    required this.folders,
    required this.cards,
  });
}

class FlashcardsRepo {
  static const _kKeyV2 = 'flashcards_v2';
  static const _kKeyV1 = 'flashcards_v1';

  Future<FlashcardsData> load() async {
    final prefs = await SharedPreferences.getInstance();

    // MIGRACJA z v1 -> v2
    final v2raw = prefs.getString(_kKeyV2);
    if (v2raw == null || v2raw.isEmpty) {
      final v1raw = prefs.getString(_kKeyV1);
      if (v1raw != null && v1raw.isNotEmpty) {
        final list = (jsonDecode(v1raw) as List).cast<Map<String, dynamic>>();
        final cards = list.map(Flashcard.fromMap).toList(); // folderId będzie null
        final data = FlashcardsData(folders: const [], cards: cards);
        await save(data);
        await prefs.remove(_kKeyV1);
        return data;
      }

      return const FlashcardsData(folders: [], cards: []);
    }

    final decoded = jsonDecode(v2raw);
    if (decoded is! Map<String, dynamic>) {
      return const FlashcardsData(folders: [], cards: []);
    }

    final foldersRaw = (decoded['folders'] as List? ?? []).cast<Map<String, dynamic>>();
    final cardsRaw = (decoded['cards'] as List? ?? []).cast<Map<String, dynamic>>();

    final folders = foldersRaw.map(FlashFolder.fromMap).toList();
    final cards = cardsRaw.map(Flashcard.fromMap).toList();

    return FlashcardsData(folders: folders, cards: cards);
  }

  Future<void> save(FlashcardsData data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode({
      'folders': data.folders.map((f) => f.toMap()).toList(),
      'cards': data.cards.map((c) => c.toMap()).toList(),
    });
    await prefs.setString(_kKeyV2, raw);
  }
}