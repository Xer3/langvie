import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flashcard_model.dart';
import 'flashfolder_model.dart';
import 'flashcards_repo.dart';

final flashcardsRepoProvider = Provider<FlashcardsRepo>((ref) {
  return FlashcardsRepo();
});

final authUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

final flashcardsProvider =
    StateNotifierProvider<FlashcardsNotifier, AsyncValue<FlashcardsData>>((ref) {
  final repo = ref.read(flashcardsRepoProvider);
  final uidAsync = ref.watch(authUidProvider);
  final uid = uidAsync.asData?.value ?? FirebaseAuth.instance.currentUser?.uid;

  return FlashcardsNotifier(repo, uid)..init();
});

class FlashcardsNotifier extends StateNotifier<AsyncValue<FlashcardsData>> {
  final FlashcardsRepo _repo;
  final String? _uid;

  FlashcardsNotifier(this._repo, this._uid) : super(const AsyncValue.loading());

  Future<void> init() async {
    final uid = _uid;

    if (uid == null) {
      state = const AsyncValue.data(
        FlashcardsData(folders: [], cards: []),
      );
      return;
    }

    try {
      final data = await _repo.load(uid);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  FlashcardsData _current() {
    return state.value ?? const FlashcardsData(folders: [], cards: []);
  }

  Future<void> _save(FlashcardsData data) async {
    final uid = _uid;

    state = AsyncValue.data(data);

    if (uid == null) return;

    await _repo.save(uid, data);
  }

  Future<void> addFolder({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final cur = _current();

    final folder = FlashFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = FlashcardsData(
      folders: [folder, ...cur.folders],
      cards: cur.cards,
    );

    await _save(updated);
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final cur = _current();

    final folders = cur.folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(name: trimmed);
    }).toList();

    final updated = FlashcardsData(
      folders: folders,
      cards: cur.cards,
    );

    await _save(updated);
  }

  Future<void> deleteFolder(String folderId) async {
    final cur = _current();

    final folders = cur.folders.where((f) => f.id != folderId).toList();

    // Usuwamy też fiszki przypisane do usuwanego folderu.
    final cards = cur.cards.where((c) => c.folderId != folderId).toList();

    final updated = FlashcardsData(
      folders: folders,
      cards: cards,
    );

    await _save(updated);
  }

  Future<void> addCard({
    required String front,
    required String back,
    String? imagePath,
    String? folderId,
  }) async {
    final frontTrimmed = front.trim();
    final backTrimmed = back.trim();

    if (frontTrimmed.isEmpty || backTrimmed.isEmpty) return;

    final cur = _current();

    final card = Flashcard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      front: frontTrimmed,
      back: backTrimmed,
      imagePath: imagePath,
      folderId: folderId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = FlashcardsData(
      folders: cur.folders,
      cards: [card, ...cur.cards],
    );

    await _save(updated);
  }

  Future<void> updateCard(
    Flashcard card, {
    required String front,
    required String back,
    String? imagePath,
    String? folderId,
  }) async {
    final frontTrimmed = front.trim();
    final backTrimmed = back.trim();

    if (frontTrimmed.isEmpty || backTrimmed.isEmpty) return;

    final cur = _current();

    final cards = cur.cards.map((c) {
      if (c.id != card.id) return c;

      return c.copyWith(
        front: frontTrimmed,
        back: backTrimmed,
        imagePath: imagePath,
        folderId: folderId,
      );
    }).toList();

    final updated = FlashcardsData(
      folders: cur.folders,
      cards: cards,
    );

    await _save(updated);
  }

  Future<void> removeCard(String id) async {
    final cur = _current();

    final cards = cur.cards.where((c) => c.id != id).toList();

    final updated = FlashcardsData(
      folders: cur.folders,
      cards: cards,
    );

    await _save(updated);
  }
}