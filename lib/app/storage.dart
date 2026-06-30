import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _kEmail = 'email_local';
  static const _kNickname = 'nickname';
  static const _kLearningLanguage = 'learning_language';
  static const _kLevel = 'level';
  static const _kOnboardingDone = 'onboarding_done';

  static const _kCompletedChaptersLegacy = 'completed_chapters';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  String? get emailLocal => _prefs.getString(_kEmail);

  Future<void> setEmailLocal(String value) async {
    await _prefs.setString(_kEmail, value);
  }

  String? get nickname => _prefs.getString(_kNickname);

  Future<void> setNickname(String value) async {
    await _prefs.setString(_kNickname, value);
  }

  String _nicknameKeyForUid(String uid) => 'nickname_$uid';

  String? getNicknameForUid(String uid) {
    final v = _prefs.getString(_nicknameKeyForUid(uid));
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<void> setNicknameForUid(String uid, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    await _prefs.setString(_nicknameKeyForUid(uid), trimmed);

    // Zostawiamy też stary klucz jako fallback dla starszych danych.
    await _prefs.setString(_kNickname, trimmed);
  }

  Future<void> clearNicknameForUid(String uid) async {
    await _prefs.remove(_nicknameKeyForUid(uid));
  }

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_kOnboardingDone, value);
  }

  String? get learningLanguage {
    final v = _prefs.getString(_kLearningLanguage);
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  Future<void> setLearningLanguage(String value) async {
    await _prefs.setString(_kLearningLanguage, value);
  }

  String? get level {
    final v = _prefs.getString(_kLevel);
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  Future<void> setLevel(String value) async {
    await _prefs.setString(_kLevel, value);
  }

  String _avatarKeyForUid(String uid) => 'avatar_id_$uid';

  int getAvatarIdForUid(String uid) {
    return _prefs.getInt(_avatarKeyForUid(uid)) ?? 1;
  }

  Future<void> setAvatarIdForUid(String uid, int id) async {
    await _prefs.setInt(_avatarKeyForUid(uid), id);
  }

  Future<void> clearAvatarForUid(String uid) async {
    await _prefs.remove(_avatarKeyForUid(uid));
  }

  String _chaptersKeyForLevel(String level) {
    return 'completed_chapters_${level.toUpperCase()}';
  }

  List<String> getCompletedChaptersForLevel(String level) {
    final key = _chaptersKeyForLevel(level);
    final v = _prefs.getStringList(key);

    if (v != null) return v;

    final legacy = _prefs.getStringList(_kCompletedChaptersLegacy);

    if (legacy != null && legacy.isNotEmpty) {
      _prefs.setStringList(key, legacy);
      _prefs.remove(_kCompletedChaptersLegacy);
      return legacy;
    }

    return <String>[];
  }

  Future<void> setCompletedChaptersForLevel(
    String level,
    List<String> chapters,
  ) async {
    final key = _chaptersKeyForLevel(level);
    await _prefs.setStringList(key, chapters);
  }

  Future<void> clearCompletedChaptersForLevel(String level) async {
    final key = _chaptersKeyForLevel(level);
    await _prefs.remove(key);
  }

  Future<void> clearAllCompletedChapters() async {
    await _prefs.remove(_chaptersKeyForLevel('A'));
    await _prefs.remove(_chaptersKeyForLevel('B'));
    await _prefs.remove(_chaptersKeyForLevel('C'));
    await _prefs.remove(_kCompletedChaptersLegacy);
  }

  Future<void> logoutLocalOnly() async {
    await _prefs.remove(_kEmail);
    await _prefs.remove(_kNickname);
  }

  Future<void> clearUserProgress() async {
    await _prefs.remove(_kLearningLanguage);
    await _prefs.remove(_kLevel);
    await _prefs.remove(_kOnboardingDone);
    await clearAllCompletedChapters();
  }

  Future<void> deleteAccountLocalCleanup({String? uid}) async {
    await logoutLocalOnly();
    await clearUserProgress();

    if (uid != null) {
      await clearAvatarForUid(uid);
      await clearNicknameForUid(uid);
    }
  }
}