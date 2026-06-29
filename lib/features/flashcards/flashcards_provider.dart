import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flashcard_model.dart';
import 'flashfolder_model.dart';
import 'flashcards_repo.dart';

final flashcardsRepoProvider = Provider<FlashcardsRepo>((ref) {
  return FlashcardsRepo();
});

final flashcardsProvider =
    StateNotifierProvider<FlashcardsNotifier, AsyncValue<FlashcardsData>>((ref) {
  final repo = ref.read(flashcardsRepoProvider);
  return FlashcardsNotifier(repo)..init();
});

class FlashcardsNotifier extends StateNotifier<AsyncValue<FlashcardsData>> {
  final FlashcardsRepo _repo;
  FlashcardsNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> init() async {
    try {
      final data = await _repo.load();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  FlashcardsData _current() => state.value ?? const FlashcardsData(folders: [], cards: []);

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

    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final cur = _current();
    final folders = cur.folders.map((f) {
      if (f.id != folderId) return f;
      return f.copyWith(name: trimmed);
    }).toList();

    final updated = FlashcardsData(folders: folders, cards: cur.cards);
    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }

  Future<void> deleteFolder(String folderId) async {
    final cur = _current();
    final folders = cur.folders.where((f) => f.id != folderId).toList();
    final cards = cur.cards.where((c) => c.folderId != folderId).toList(); // usuń fiszki z folderu

    final updated = FlashcardsData(folders: folders, cards: cards);
    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }

  Future<void> addCard({
    required String front,
    required String back,
    String? imagePath,
    String? folderId, // null = bez folderu
  }) async {
    final cur = _current();

    final card = Flashcard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      front: front.trim(),
      back: back.trim(),
      imagePath: imagePath,
      folderId: folderId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = FlashcardsData(
      folders: cur.folders,
      cards: [card, ...cur.cards],
    );

    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }

  Future<void> updateCard(
    Flashcard card, {
    required String front,
    required String back,
    String? imagePath, // null = usuń obrazek
    String? folderId, // null = bez folderu
  }) async {
    final cur = _current();
    final cards = cur.cards.map((c) {
      if (c.id != card.id) return c;
      return c.copyWith(
        front: front.trim(),
        back: back.trim(),
        imagePath: imagePath,
        folderId: folderId,
      );
    }).toList();

    final updated = FlashcardsData(folders: cur.folders, cards: cards);
    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }

  Future<void> removeCard(String id) async {
    final cur = _current();
    final cards = cur.cards.where((c) => c.id != id).toList();

    final updated = FlashcardsData(folders: cur.folders, cards: cards);
    state = AsyncValue.data(updated);
    await _repo.save(updated);
  }
}