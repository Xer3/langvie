import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/app_state.dart';
import '../../app/ui/app_colors.dart';
import '../../shared/back_app_bar.dart';
import 'avatar_picker_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const int lessonsPerLevel = 4;

  static const Color dangerRed = Color(0xFFE0565B);

  static const double _profileAvatarScale = 1.12;
  static const double _profileAvatarSize = 112;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _levelRank(String lvl) {
    switch (lvl.toUpperCase()) {
      case 'A':
        return 1;
      case 'B':
        return 2;
      case 'C':
        return 3;
      default:
        return 1;
    }
  }

  bool _allLessonsDoneForCurrent(AppState state) {
    for (var i = 1; i <= lessonsPerLevel; i++) {
      if (!state.completedChapters.contains(i)) return false;
    }
    return true;
  }

  Future<void> _changeNick(AppState state) async {
    final controller = TextEditingController(text: state.nickname ?? '');

    final newNick = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmień nick'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nowy nick'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (newNick != null && newNick.trim().isNotEmpty) {
      await ref.read(appStateProvider.notifier).setNickname(newNick.trim());
      _snack('Nick zapisany');
    }
  }

  Future<void> _resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    _snack('Link do zmiany hasła został wysłany');
  }

  Future<void> _resetCourseProgress() async {
    await ref.read(appStateProvider.notifier).resetChapterProgress();
    _snack('Postęp poziomu zresetowany');
  }

  Future<void> _pickLevel(AppState state, String pickedLevel) async {
    final currentLevel = (state.level ?? 'A').toUpperCase();
    final pick = pickedLevel.toUpperCase();

    if (pick == currentLevel) return;

    final curRank = _levelRank(currentLevel);
    final pickRank = _levelRank(pick);

    if (pickRank < curRank) {
      await ref.read(appStateProvider.notifier).switchLevelKeepProgress(pick);
      _snack('Przełączono poziom na: $pick');
      return;
    }

    if (!_allLessonsDoneForCurrent(state)) {
      _snack('Najpierw ukończ wszystkie lekcje na poziomie $currentLevel.');
      return;
    }

    final newLevel =
        await ref.read(appStateProvider.notifier).advanceLevelAndResetChapters();
    if (newLevel == null) {
      _snack('Nie można już awansować poziomu.');
      return;
    }

    _snack('Poziom zmieniony na $newLevel');
  }

  Future<void> _deleteAccountWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _snack('Brak zalogowanego użytkownika');
        return;
      }

      final cred = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      await user.reauthenticateWithCredential(cred);
      await user.delete();

      await ref.read(appStateProvider.notifier).logoutAfterAccountDeletion();
      _snack('Konto usunięte');
    } on FirebaseAuthException catch (e) {
      final code = e.code;

      if (code == 'wrong-password' || code == 'invalid-credential') {
        _snack('Nieprawidłowe hasło');
        return;
      }
      if (code == 'requires-recent-login') {
        _snack('Zaloguj się ponownie i spróbuj jeszcze raz');
        return;
      }

      _snack('Nie udało się usunąć konta: ${e.message ?? e.code}');
    } catch (e) {
      _snack('Nie udało się usunąć konta: $e');
    }
  }

  Future<void> _showDeleteDialog(AppState state) async {
    final email = state.email;
    if (email == null) {
      _snack('Brak emaila użytkownika');
      return;
    }

    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń konto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aby usunąć konto, potwierdź hasłem.'),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Hasło',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final pass = passCtrl.text;
      if (pass.trim().isEmpty) {
        _snack('Podaj hasło');
        return;
      }
      await _deleteAccountWithPassword(email: email, password: pass);
    }
  }

  Future<void> _openAvatarPicker(int currentId) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return AvatarPickerSheet(
          selectedId: currentId,
          onPick: (id) async {
            await ref.read(appStateProvider.notifier).setAvatarId(id);
            if (mounted) Navigator.pop(context);
            _snack('Avatar zapisany');
          },
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback? onTap,
    bool enabled = true,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Set<int> _parseSet(List<String> raw) =>
      raw.map((e) => int.tryParse(e)).whereType<int>().toSet();

  bool _levelCompleted(Set<int> completed) {
    for (var i = 1; i <= lessonsPerLevel; i++) {
      if (!completed.contains(i)) return false;
    }
    return true;
  }

  int _countCompleted(Set<int> completed) =>
      completed.where((x) => x >= 1 && x <= lessonsPerLevel).length;

  Widget _statsTile({
    required String level,
    required Set<int> completed,
    required bool isCurrent,
  }) {
    final doneCount = _countCompleted(completed);
    final doneAll = _levelCompleted(completed);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(level, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        title: Text(
          isCurrent ? 'Poziom $level (aktualny)' : 'Poziom $level',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('Zaliczone lekcje: $doneCount/$lessonsPerLevel'),
        trailing: doneAll
            ? const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 18),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    final displayName =
        (state.nickname != null && state.nickname!.trim().isNotEmpty)
            ? state.nickname!.trim()
            : (state.email ?? 'Użytkownik');

    final currentLevel = (state.level ?? 'A').toUpperCase();
    final storageAsync = ref.watch(storageProvider);

    final avatarId = state.avatarId;

    // ✅ TO JEST TEN SAM NIEBIESKI CO NAV BAR (spójność)
    final primaryBlue = AppColors.blue;

    return Scaffold(
      appBar: BackAppBar(context: context, title: 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  SizedBox(
                    width: _profileAvatarSize,
                    height: _profileAvatarSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Transform.scale(
                        scale: _profileAvatarScale,
                        child: Image.asset(
                          'assets/avatars/avatar$avatarId.png',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Witaj, $displayName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text('Poziom: $currentLevel'),
                  if (state.email != null) ...[
                    const SizedBox(height: 4),
                    Text(state.email!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _openAvatarPicker(avatarId),
                      child: const Text('Zmień avatar'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.query_stats_outlined),
                title: const Text('Statystyki', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Postęp A / B / C'),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  storageAsync.when(
                    data: (storage) {
                      final a = _parseSet(storage.getCompletedChaptersForLevel('A'));
                      final b = _parseSet(storage.getCompletedChaptersForLevel('B'));
                      final c = _parseSet(storage.getCompletedChaptersForLevel('C'));

                      return Column(
                        children: [
                          _statsTile(level: 'A', completed: a, isCurrent: currentLevel == 'A'),
                          const SizedBox(height: 10),
                          _statsTile(level: 'B', completed: b, isCurrent: currentLevel == 'B'),
                          const SizedBox(height: 10),
                          _statsTile(level: 'C', completed: c, isCurrent: currentLevel == 'C'),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Nie udało się wczytać statystyk: $e'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _sectionTitle('Ustawienia kursu'),
          _tile(
            icon: Icons.edit_outlined,
            title: 'Zmień nick',
            onTap: () => _changeNick(state),
          ),
          const SizedBox(height: 10),
          _tile(
            icon: Icons.restart_alt,
            title: 'Zresetuj postęp poziomu',
            subtitle: 'Czyści zaliczone lekcje na bieżącym poziomie',
            onTap: _resetCourseProgress,
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Zmień poziom kursu', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Aktualnie: $currentLevel'),
              trailing: DropdownButton<String>(
                value: currentLevel,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _pickLevel(state, v);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          _sectionTitle('Konto'),
          _tile(
            icon: Icons.lock_reset_outlined,
            title: 'Zmień hasło',
            subtitle: 'Wyśle link na maila',
            enabled: state.email != null,
            onTap: state.email == null ? null : () => _resetPassword(state.email!),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              enabled: state.email != null,
              leading: const Icon(Icons.delete_outline, color: dangerRed),
              title: const Text(
                'Usuń konto',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: dangerRed,
                ),
              ),
              subtitle: const Text('Wymaga potwierdzenia hasłem'),
              trailing: const Icon(Icons.chevron_right, color: dangerRed),
              onTap: (state.email != null) ? () => _showDeleteDialog(state) : null,
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Wyloguj', style: TextStyle(fontWeight: FontWeight.w900)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await ref.read(appStateProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}