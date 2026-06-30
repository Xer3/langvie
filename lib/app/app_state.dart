import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage.dart';

class AppState {
  static const Object _unset = Object();

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
        avatarId = 1;

  AppState copyWith({
    bool? isReady,
    bool? isLoggedIn,
    bool? needsOnboarding,
    Object? email = _unset,
    Object? nickname = _unset,
    Object? learningLanguage = _unset,
    Object? level = _unset,
    Set<int>? completedChapters,
    int? avatarId,
  }) {
    return AppState(
      isReady: isReady ?? this.isReady,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      email: identical(email, _unset) ? this.email : email as String?,
      nickname:
          identical(nickname, _unset) ? this.nickname : nickname as String?,
      learningLanguage: identical(learningLanguage, _unset)
          ? this.learningLanguage
          : learningLanguage as String?,
      level: identical(level, _unset) ? this.level : level as String?,
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

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  String _normLevel(String? lvl) {
    final v = (lvl ?? 'A').trim().toUpperCase();
    if (v == 'A' || v == 'B' || v == 'C') return v;
    return 'A';
  }

  String _chaptersField(String level) {
    return 'completedChapters${_normLevel(level)}';
  }

  Set<int> _parseChapters(List<String> raw) {
    return raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Set<int> _toIntSet(dynamic raw) {
    if (raw is! Iterable) return <int>{};

    return raw
        .map((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        })
        .whereType<int>()
        .toSet();
  }

  List<int> _sortedList(Set<int> value) {
    final list = value.toList()..sort();
    return list;
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String? _asNullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _bestNickname({
    required User? user,
    required String? firestoreNick,
    required String? localNick,
  }) {
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final remote = firestoreNick?.trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }

    final local = localNick?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    return null;
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

  Future<Map<String, dynamic>> _localDataForNewFirestoreUser({
    required User user,
    required AppStorage storage,
  }) async {
    final displayName = user.displayName?.trim();
    final localNick = storage.nickname?.trim();

    final nickname = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (localNick != null && localNick.isNotEmpty ? localNick : '');

    final completedA = _parseChapters(storage.getCompletedChaptersForLevel('A'));
    final completedB = _parseChapters(storage.getCompletedChaptersForLevel('B'));
    final completedC = _parseChapters(storage.getCompletedChaptersForLevel('C'));

    return {
      'email': user.email,
      'nickname': nickname,
      'avatarId': storage.getAvatarIdForUid(user.uid),
      'learningLanguage': storage.learningLanguage ?? '',
      'level': storage.level ?? '',
      'onboardingDone': storage.onboardingDone,
      'completedChaptersA': _sortedList(completedA),
      'completedChaptersB': _sortedList(completedB),
      'completedChaptersC': _sortedList(completedC),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _createFirestoreUserIfMissing({
    required User user,
    required AppStorage storage,
  }) async {
    final doc = _userDoc(user.uid);
    final snap = await doc.get();

    if (snap.exists) return;

    final data = await _localDataForNewFirestoreUser(
      user: user,
      storage: storage,
    );

    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> _syncLocalCacheFromFirestore({
    required User user,
    required AppStorage storage,
    required Map<String, dynamic> data,
  }) async {
    final nickname = _asNullableString(data['nickname']);
    final learningLanguage = _asNullableString(data['learningLanguage']);
    final level = _asNullableString(data['level']);
    final onboardingDone = data['onboardingDone'] == true;
    final avatarId = _asInt(data['avatarId'], 1);

    await storage.setAvatarIdForUid(user.uid, avatarId);
    await storage.setOnboardingDone(onboardingDone);
    await storage.setLearningLanguage(learningLanguage ?? '');
    await storage.setLevel(level ?? '');

    if (nickname != null && nickname.isNotEmpty) {
      await storage.setNickname(nickname);
    }

    await storage.setCompletedChaptersForLevel(
      'A',
      _toIntSet(data['completedChaptersA'])
          .map((e) => e.toString())
          .toList(),
    );

    await storage.setCompletedChaptersForLevel(
      'B',
      _toIntSet(data['completedChaptersB'])
          .map((e) => e.toString())
          .toList(),
    );

    await storage.setCompletedChaptersForLevel(
      'C',
      _toIntSet(data['completedChaptersC'])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Future<AppState> _stateFromFirestoreUser(User user) async {
    final storage = await _ref.read(storageProvider.future);

    try {
      await user.reload();
    } catch (_) {}

    final refreshedUser = FirebaseAuth.instance.currentUser ?? user;

    await _createFirestoreUserIfMissing(
      user: refreshedUser,
      storage: storage,
    );

    final snap = await _userDoc(refreshedUser.uid).get();
    final data = snap.data() ?? <String, dynamic>{};

    await _syncLocalCacheFromFirestore(
      user: refreshedUser,
      storage: storage,
      data: data,
    );

    final firestoreNick = _asNullableString(data['nickname']);
    final learningLanguage = _asNullableString(data['learningLanguage']);
    final level = _asNullableString(data['level']);
    final currentLevel = _normLevel(level);
    final completed = _toIntSet(data[_chaptersField(currentLevel)]);

    final onboardingDone = data['onboardingDone'] == true;
    final avatarId = _asInt(data['avatarId'], 1);

    return AppState(
      isReady: true,
      isLoggedIn: true,
      needsOnboarding: !onboardingDone,
      email: refreshedUser.email,
      nickname: _bestNickname(
        user: refreshedUser,
        firestoreNick: firestoreNick,
        localNick: storage.nickname,
      ),
      learningLanguage: learningLanguage,
      level: level,
      completedChapters: completed,
      avatarId: avatarId,
    );
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = const AppState.initial().copyWith(isReady: true);
      return;
    }

    state = await _stateFromFirestoreUser(user);
  }

  Future<void> loadFromStorage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      state = const AppState.initial().copyWith(isReady: true);
      return;
    }

    state = await _stateFromFirestoreUser(user);
  }

  Future<void> markLoggedInFromLogin(User? user) async {
    if (user == null) {
      state = const AppState.initial().copyWith(isReady: true);
      return;
    }

    state = await _stateFromFirestoreUser(user);
  }

  Future<void> startOnboardingAfterRegister(User? user) async {
    if (user == null) return;

    final storage = await _ref.read(storageProvider.future);

    try {
      await user.reload();
    } catch (_) {}

    final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
    final displayName = refreshedUser.displayName?.trim();

    await storage.setOnboardingDone(false);
    await storage.setLearningLanguage('');
    await storage.setLevel('');
    await storage.clearAllCompletedChapters();
    await storage.setAvatarIdForUid(refreshedUser.uid, 1);

    if (displayName != null && displayName.isNotEmpty) {
      await storage.setNickname(displayName);
    }

    await _userDoc(refreshedUser.uid).set({
      'email': refreshedUser.email,
      'nickname': displayName ?? '',
      'avatarId': 1,
      'learningLanguage': '',
      'level': '',
      'onboardingDone': false,
      'completedChaptersA': <int>[],
      'completedChaptersB': <int>[],
      'completedChaptersC': <int>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    state = AppState(
      isReady: true,
      isLoggedIn: true,
      email: refreshedUser.email,
      nickname:
          displayName != null && displayName.isNotEmpty ? displayName : null,
      learningLanguage: null,
      level: null,
      completedChapters: <int>{},
      needsOnboarding: true,
      avatarId: 1,
    );
  }

  Future<void> setAvatarId(int id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storage = await _ref.read(storageProvider.future);
    await storage.setAvatarIdForUid(user.uid, id);

    await _userDoc(user.uid).set({
      'avatarId': id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    state = state.copyWith(avatarId: id);
  }

  Future<void> setLearningLanguage(String langCode) async {
    final user = FirebaseAuth.instance.currentUser;
    final storage = await _ref.read(storageProvider.future);

    await storage.setLearningLanguage(langCode);

    if (user != null) {
      await _userDoc(user.uid).set({
        'learningLanguage': langCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    state = state.copyWith(learningLanguage: langCode);
  }

  Future<void> setLevelAndFinishOnboarding(String level) async {
    final user = FirebaseAuth.instance.currentUser;
    final storage = await _ref.read(storageProvider.future);
    final lvl = _normLevel(level);

    await storage.setLevel(lvl);
    await storage.setOnboardingDone(true);

    if (user != null) {
      await _userDoc(user.uid).set({
        'level': lvl,
        'onboardingDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final completed = _parseChapters(storage.getCompletedChaptersForLevel(lvl));

    state = state.copyWith(
      level: lvl,
      needsOnboarding: false,
      completedChapters: completed,
    );
  }

  Future<void> switchLevelKeepProgress(String level) async {
    final user = FirebaseAuth.instance.currentUser;
    final storage = await _ref.read(storageProvider.future);
    final lvl = _normLevel(level);

    await storage.setLevel(lvl);
    await storage.setOnboardingDone(true);

    if (user != null) {
      await _userDoc(user.uid).set({
        'level': lvl,
        'onboardingDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

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

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.updateDisplayName(trimmed);
      await user.reload();
    }

    final storage = await _ref.read(storageProvider.future);
    await storage.setNickname(trimmed);

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null) {
      await _userDoc(refreshedUser.uid).set({
        'nickname': trimmed,
        'email': refreshedUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final firebaseNick = refreshedUser?.displayName?.trim();

    state = state.copyWith(
      nickname: firebaseNick != null && firebaseNick.isNotEmpty
          ? firebaseNick
          : trimmed,
    );
  }

  Future<void> markChapterCompleted(int chapter) async {
    if (state.completedChapters.contains(chapter)) return;

    final user = FirebaseAuth.instance.currentUser;
    final lvl = _normLevel(state.level);
    final updated = {...state.completedChapters, chapter};

    final storage = await _ref.read(storageProvider.future);
    await storage.setCompletedChaptersForLevel(
      lvl,
      updated.map((e) => e.toString()).toList(),
    );

    if (user != null) {
      await _userDoc(user.uid).set({
        _chaptersField(lvl): FieldValue.arrayUnion([chapter]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    state = state.copyWith(completedChapters: updated);
  }

  Future<void> resetChapterProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    final lvl = _normLevel(state.level);
    final storage = await _ref.read(storageProvider.future);

    await storage.clearCompletedChaptersForLevel(lvl);

    if (user != null) {
      await _userDoc(user.uid).set({
        _chaptersField(lvl): <int>[],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    state = state.copyWith(completedChapters: <int>{});
  }

  Future<String?> advanceLevelAndResetChapters() async {
    final current = _normLevel(state.level);
    if (current == 'C') return null;

    final next = current == 'A' ? 'B' : 'C';

    final user = FirebaseAuth.instance.currentUser;
    final storage = await _ref.read(storageProvider.future);

    await storage.setLevel(next);
    await storage.setOnboardingDone(true);

    if (user != null) {
      await _userDoc(user.uid).set({
        'level': next,
        'onboardingDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final completedNext =
        _parseChapters(storage.getCompletedChaptersForLevel(next));

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

    state = const AppState.initial().copyWith(isReady: true);
  }

  Future<void> logoutAfterAccountDeletion() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      try {
        await _userDoc(uid).delete();
      } catch (_) {}

      try {
        await storageProvider.future;
      } catch (_) {}
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final storage = await _ref.read(storageProvider.future);

    if (uid != null) {
      await storage.clearAvatarForUid(uid);
    }

    await storage.deleteAccountLocalCleanup();

    state = const AppState.initial().copyWith(isReady: true);
  }
}