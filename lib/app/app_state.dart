import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage.dart';

class AppState {
  final bool isReady;
  final bool isLoggedIn;

  final bool needsOnboarding;

  final String? email;
  final String? nickname;

  final String? learningLanguage;
  final String? level;
  final Set<int> completedChapters;

  final int avatarId;

  const AppState({
    required this.isReady,
    required this.isLoggedIn,
    required this.needsOnboarding,
    required this.email,
    required this.nickname,
    required this.learningLanguage,
    required this.level,
    required this.completedChapters,
    required this.avatarId,
  });

  const AppState.initial()
      : isReady = false,
        isLoggedIn = false,
        needsOnboarding = false,
        email = null,
        nickname = null,
        learningLanguage = null,
        level = null,
        completedChapters = const <int>{},
        // ✅ 1 = domyślny avatar
        avatarId = 1;

  AppState copyWith({
    bool? isReady,
    bool? isLoggedIn,
    bool? needsOnboarding,
    String? email,
    String? nickname,
    String? learningLanguage,
    String? level,
    Set<int>? completedChapters,
    int? avatarId,
  }) {
    return AppState(
      isReady: isReady ?? this.isReady,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      level: level ?? this.level,
      completedChapters: completedChapters ?? this.completedChapters,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final storageProvider = FutureProvider<AppStorage>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return AppStorage(prefs);
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  StreamSubscription<User?>? _authSub;

  AppStateNotifier(this._ref) : super(const AppState.initial()) {
    _init();
  }

  String _normLevel(String? lvl) {
    final v = (lvl ?? 'A').trim().toUpperCase();
    if (v == 'A' || v == 'B' || v == 'C') return v;
    return 'A';
  }

  Set<int> _parseChapters(List<String> raw) {
    return raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Future<void> _init() async {
    await loadFromStorage();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    final storage = await _ref.read(storageProvider.future);

    final localNick = storage.nickname;
    final displayName = user?.displayName;

    final lvl = _normLevel(storage.level);
    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    final uid = user?.uid;
    // ✅ 1 = domyślny avatar gdy brak uid
    final avatar = (uid == null) ? 1 : storage.getAvatarIdForUid(uid);

    state = state.copyWith(
      isReady: true,
      isLoggedIn: user != null,
      email: user?.email,
      nickname: user == null
          ? null
          : (displayName?.trim().isNotEmpty == true ? displayName!.trim() : localNick),
      learningLanguage: storage.learningLanguage,
      level: storage.level,
      completedChapters: completed,
      needsOnboarding: user != null && !storage.onboardingDone,
      avatarId: avatar,
    );
  }

  Future<void> loadFromStorage() async {
    final storage = await _ref.read(storageProvider.future);
    final user = FirebaseAuth.instance.currentUser;

    final lvl = _normLevel(storage.level);
    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    final localNick = storage.nickname;
    final displayName = user?.displayName;

    final uid = user?.uid;
    final avatar = (uid == null) ? 1 : storage.getAvatarIdForUid(uid);

    state = AppState(
      isReady: true,
      isLoggedIn: user != null,
      needsOnboarding: user != null && !storage.onboardingDone,
      email: user?.email,
      nickname: user == null
          ? null
          : (displayName?.trim().isNotEmpty == true ? displayName!.trim() : localNick),
      learningLanguage: storage.learningLanguage,
      level: storage.level,
      completedChapters: completed,
      avatarId: avatar,
    );
  }

  Future<void> markLoggedInFromLogin(User? user) async {
    final storage = await _ref.read(storageProvider.future);

    final lvl = _normLevel(storage.level);
    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    final uid = user?.uid;
    final avatar = (uid == null) ? 1 : storage.getAvatarIdForUid(uid);

    state = state.copyWith(
      isLoggedIn: user != null,
      email: user?.email,
      nickname: user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : storage.nickname,
      needsOnboarding: user != null && !storage.onboardingDone,
      learningLanguage: storage.learningLanguage,
      level: storage.level,
      completedChapters: completed,
      avatarId: avatar,
    );
  }

  Future<void> startOnboardingAfterRegister(User? user) async {
    final storage = await _ref.read(storageProvider.future);

    await storage.setOnboardingDone(false);
    await storage.setLearningLanguage('');
    await storage.setLevel('');
    await storage.clearAllCompletedChapters();

    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      await storage.setNickname(displayName);
    }

    // ✅ nowy user dostaje domyślny avatar (1)
    if (user != null) {
      await storage.setAvatarIdForUid(user.uid, 1);
    }

    state = state.copyWith(
      isLoggedIn: user != null,
      email: user?.email,
      nickname: displayName?.isNotEmpty == true ? displayName : storage.nickname,
      learningLanguage: null,
      level: null,
      completedChapters: <int>{},
      needsOnboarding: user != null,
      avatarId: 1,
    );
  }

  Future<void> setAvatarId(int id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storage = await _ref.read(storageProvider.future);
    await storage.setAvatarIdForUid(user.uid, id);

    state = state.copyWith(avatarId: id);
  }

  Future<void> setLearningLanguage(String langCode) async {
    final storage = await _ref.read(storageProvider.future);
    await storage.setLearningLanguage(langCode);
    state = state.copyWith(learningLanguage: langCode);
  }

  Future<void> setLevelAndFinishOnboarding(String level) async {
    final storage = await _ref.read(storageProvider.future);
    final lvl = _normLevel(level);

    await storage.setLevel(lvl);
    await storage.setOnboardingDone(true);

    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    state = state.copyWith(
      level: lvl,
      needsOnboarding: false,
      completedChapters: completed,
    );
  }

  Future<void> switchLevelKeepProgress(String level) async {
    final storage = await _ref.read(storageProvider.future);
    final lvl = _normLevel(level);

    await storage.setLevel(lvl);
    await storage.setOnboardingDone(true);

    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    state = state.copyWith(
      level: lvl,
      needsOnboarding: false,
      completedChapters: completed,
    );
  }

  Future<void> setNickname(String nick) async {
    final trimmed = nick.trim();
    if (trimmed.isEmpty) return;

    final storage = await _ref.read(storageProvider.future);
    await storage.setNickname(trimmed);

    state = state.copyWith(nickname: trimmed);
  }

  Future<void> markChapterCompleted(int chapter) async {
    if (state.completedChapters.contains(chapter)) return;

    final lvl = _normLevel(state.level);
    final updated = {...state.completedChapters, chapter};

    final storage = await _ref.read(storageProvider.future);
    await storage.setCompletedChaptersForLevel(lvl, updated.map((e) => e.toString()).toList());

    state = state.copyWith(completedChapters: updated);
  }

  Future<void> resetChapterProgress() async {
    final lvl = _normLevel(state.level);
    final storage = await _ref.read(storageProvider.future);

    await storage.clearCompletedChaptersForLevel(lvl);

    state = state.copyWith(completedChapters: <int>{});
  }

  Future<String?> advanceLevelAndResetChapters() async {
    final current = _normLevel(state.level);
    if (current == 'C') return null;

    final next = current == 'A' ? 'B' : 'C';

    final storage = await _ref.read(storageProvider.future);
    await storage.setLevel(next);
    await storage.setOnboardingDone(true);

    final completedNext = _parseChapters(storage.getCompletedChaptersForLevel(next));

    state = state.copyWith(
      level: next,
      needsOnboarding: false,
      completedChapters: completedNext,
    );

    return next;
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final storage = await _ref.read(storageProvider.future);
    await storage.logoutLocalOnly();

    state = state.copyWith(
      isReady: true,
      isLoggedIn: false,
      email: null,
      nickname: null,
      needsOnboarding: false,
      avatarId: 1,
    );
  }

  Future<void> logoutAfterAccountDeletion() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final storage = await _ref.read(storageProvider.future);

    if (uid != null) {
      await storage.clearAvatarForUid(uid);
    }

    await storage.deleteAccountLocalCleanup();

    state = state.copyWith(
      isReady: true,
      isLoggedIn: false,
      email: null,
      nickname: null,
      needsOnboarding: false,
      learningLanguage: null,
      level: null,
      completedChapters: <int>{},
      avatarId: 1,
    );
  }
}