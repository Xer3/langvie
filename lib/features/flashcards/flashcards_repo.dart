import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _db;

  FlashcardsRepo({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  String _localKeyV2(String uid) => 'flashcards_v2_$uid';

  CollectionReference<Map<String, dynamic>> _foldersCol(String uid) {
    return _db.collection('users').doc(uid).collection('flashcardFolders');
  }

  CollectionReference<Map<String, dynamic>> _cardsCol(String uid) {
    return _db.collection('users').doc(uid).collection('flashcards');
  }

  Future<FlashcardsData> load(String uid) async {
    try {
      final remote = await _loadRemote(uid);

      // Lokalny cache tylko dla konkretnego UID.
      await _saveLocal(uid, remote);

      return remote;
    } catch (_) {
      // Awaryjnie, gdy np. chwilowo nie ma internetu.
      return _loadLocal(uid);
    }
  }

  Future<void> save(String uid, FlashcardsData data) async {
    await _saveLocal(uid, data);
    await _saveRemote(uid, data);
  }

  Future<FlashcardsData> _loadLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKeyV2(uid));

    if (raw == null || raw.isEmpty) {
      return const FlashcardsData(folders: [], cards: []);
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return const FlashcardsData(folders: [], cards: []);
      }

      final map = Map<String, dynamic>.from(decoded);

      final foldersRaw = (map['folders'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final cardsRaw = (map['cards'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final folders = foldersRaw.map(FlashFolder.fromMap).toList();
      final cards = cardsRaw.map(Flashcard.fromMap).toList();

      return FlashcardsData(folders: folders, cards: cards);
    } catch (_) {
      return const FlashcardsData(folders: [], cards: []);
    }
  }

  Future<void> _saveLocal(String uid, FlashcardsData data) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = jsonEncode({
      'folders': data.folders.map((f) => f.toMap()).toList(),
      'cards': data.cards.map((c) => c.toMap()).toList(),
    });

    await prefs.setString(_localKeyV2(uid), raw);
  }

  Future<FlashcardsData> _loadRemote(String uid) async {
    final foldersSnap = await _foldersCol(uid)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .get();

    final cardsSnap = await _cardsCol(uid)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .get();

    final folders = foldersSnap.docs.map((doc) {
      final data = doc.data();

      return FlashFolder.fromMap({
        ...data,
        'id': data['id'] ?? doc.id,
      });
    }).toList();

    final cards = cardsSnap.docs.map((doc) {
      final data = doc.data();

      return Flashcard.fromMap({
        ...data,
        'id': data['id'] ?? doc.id,
      });
    }).toList();

    return FlashcardsData(folders: folders, cards: cards);
  }

  Future<void> _saveRemote(String uid, FlashcardsData data) async {
    final batch = _db.batch();

    final foldersRef = _foldersCol(uid);
    final cardsRef = _cardsCol(uid);

    final existingFolders = await foldersRef.get();
    final existingCards = await cardsRef.get();

    final wantedFolderIds = data.folders.map((f) => f.id).toSet();
    final wantedCardIds = data.cards.map((c) => c.id).toSet();

    for (final doc in existingFolders.docs) {
      if (!wantedFolderIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final doc in existingCards.docs) {
      if (!wantedCardIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final folder in data.folders) {
      batch.set(
        foldersRef.doc(folder.id),
        folder.toMap(),
        SetOptions(merge: true),
      );
    }

    for (final card in data.cards) {
      batch.set(
        cardsRef.doc(card.id),
        card.toMap(),
        SetOptions(merge: true),
      );
    }

    batch.set(
      _db.collection('users').doc(uid),
      {
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}