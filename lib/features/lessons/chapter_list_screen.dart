import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';

class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({super.key});

  static const int lessonsPerLevel = 4;
  static const Color kBlue = Color(0xFF4A90E2);

  bool _isLevelDone(Set<int> completed) {
    for (var i = 1; i <= lessonsPerLevel; i++) {
      if (!completed.contains(i)) return false;
    }
    return true;
  }

  bool _isChapterDone(Set<int> completed, int chapterIndex) {
    if (chapterIndex == 1) return completed.contains(1) && completed.contains(2);
    return completed.contains(3) && completed.contains(4);
  }

  Widget _lessonTile({
    required BuildContext context,
    required Set<int> completed,
    required int lessonNo,
    required String level,
  }) {
    final isDone = completed.contains(lessonNo);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.book_outlined),
        title: Text('Lekcja $lessonNo', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Poziom $level • Lekcja + zadania'),
        trailing: isDone
            ? const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 18),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => context.push('/chapter/$lessonNo'),
      ),
    );
  }

  Widget _chapterAccordion({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool chapterDone,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.layers_outlined),
          title: Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              if (chapterDone)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
            ],
          ),
          subtitle: Text(subtitle),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    final completed = state.completedChapters;
    final level = (state.level ?? 'A').toUpperCase();

    final isMaxLevel = level == 'C';
    final levelDone = _isLevelDone(completed);

    final doneCh1 = completed.where((x) => x == 1 || x == 2).length;
    final doneCh2 = completed.where((x) => x == 3 || x == 4).length;

    final chapter1Done = _isChapterDone(completed, 1);
    final chapter2Done = _isChapterDone(completed, 2);

    final nextLevelLabel = isMaxLevel
        ? 'Ukończono wszystkie poziomy ✅'
        : 'Przejdź do poziomu ${level == "A" ? "B" : "C"}';

    return Scaffold(
      appBar: AppBar(title: const Text('Lekcje')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ WRACA NIEBIESKI GÓRNY PANEL (jak chciałeś)
            Card(
              elevation: 0,
              color: kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined, color: Colors.white),
                title: Text(
                  'Poziom $level • 2 rozdziały • 4 lekcje',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  levelDone
                      ? 'Poziom zaliczony'
                      : 'Zalicz wszystkie lekcje, aby ukończyć poziom',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: levelDone
                    ? const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white, size: 18),
                      )
                    : null,
              ),
            ),

            if (levelDone) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isMaxLevel
                      ? null
                      : () async {
                          final newLevel =
                              await ref.read(appStateProvider.notifier).advanceLevelAndResetChapters();

                          if (!context.mounted) return;

                          if (newLevel == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nie można już awansować poziomu')),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Poziom zmieniony na $newLevel')),
                          );

                          context.go('/chapter-list');
                        },
                  child: Text(nextLevelLabel),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  _chapterAccordion(
                    context: context,
                    title: 'Rozdział 1',
                    subtitle: 'Lekcje 1–2 • $doneCh1/2 zaliczone',
                    chapterDone: chapter1Done,
                    children: [
                      _lessonTile(context: context, completed: completed, lessonNo: 1, level: level),
                      const SizedBox(height: 10),
                      _lessonTile(context: context, completed: completed, lessonNo: 2, level: level),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _chapterAccordion(
                    context: context,
                    title: 'Rozdział 2',
                    subtitle: 'Lekcje 3–4 • $doneCh2/2 zaliczone',
                    chapterDone: chapter2Done,
                    children: [
                      _lessonTile(context: context, completed: completed, lessonNo: 3, level: level),
                      const SizedBox(height: 10),
                      _lessonTile(context: context, completed: completed, lessonNo: 4, level: level),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}