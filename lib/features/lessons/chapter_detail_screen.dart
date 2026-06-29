import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../shared/back_app_bar.dart';
import 'lesson_data.dart';

class ChapterDetailScreen extends ConsumerStatefulWidget {
  final int chapterNumber;
  const ChapterDetailScreen({super.key, required this.chapterNumber});

  @override
  ConsumerState<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends ConsumerState<ChapterDetailScreen> {
  static const Color kBlue = Color(0xFF4A90E2);

  int _taskIndex = 0;
  int _score = 0;

  final _inputCtrl = TextEditingController();
  bool _examExpanded = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  String get _level => (ref.watch(appStateProvider).level ?? 'A').toUpperCase();
  String _normalize(String s) => s.trim().toLowerCase();

  int _passScoreFor(int total) {
    final needed = (total * 0.75).ceil();
    return needed < 1 ? 1 : needed;
  }

  void _restart() {
    setState(() {
      _taskIndex = 0;
      _score = 0;
    });
    _inputCtrl.clear();
  }

  void _goNextOrFinish({required int totalTasks, required bool passed}) async {
    if (_taskIndex < totalTasks - 1) {
      setState(() => _taskIndex++);
      return;
    }

    if (passed) {
      await ref.read(appStateProvider.notifier).markChapterCompleted(widget.chapterNumber);
    }

    if (!mounted) return;

    final passScore = _passScoreFor(totalTasks);
    final pageContext = context;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(passed ? 'Gratulacje! Zaliczone 🎉' : 'Nie zaliczone'),
          content: Text('Wynik: $_score/$totalTasks (próg: $passScore)'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                pageContext.go('/chapter-list');
              },
              // ✅ niebieski tekst
              style: TextButton.styleFrom(foregroundColor: kBlue),
              child: const Text('Wróć do lekcji'),
            ),
            if (!passed)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                  _restart();
                },
                child: const Text('Spróbuj ponownie'),
              ),
          ],
        );
      },
    );
  }

  void _answerInput(LessonTask task, int totalTasks) {
    final user = _normalize(_inputCtrl.text);
    final correct = _normalize(task.correct);

    if (user.isNotEmpty && user == correct) {
      _score++;
    }

    _inputCtrl.clear();

    final passed = _score >= _passScoreFor(totalTasks);
    _goNextOrFinish(totalTasks: totalTasks, passed: passed);
  }

  void _answerAbcd(LessonTask task, String chosen, int totalTasks) {
    if (_normalize(chosen) == _normalize(task.correct)) {
      _score++;
    }

    final passed = _score >= _passScoreFor(totalTasks);
    _goNextOrFinish(totalTasks: totalTasks, passed: passed);
  }

  @override
  Widget build(BuildContext context) {
    final pack = LessonData.getPack(level: _level, chapter: widget.chapterNumber);
    final lesson = pack.content;
    final tasks = pack.tasks;

    final totalTasks = tasks.length;
    final idx = _taskIndex.clamp(0, totalTasks - 1);
    final task = tasks[idx];

    final alreadyCompleted =
        ref.watch(appStateProvider).completedChapters.contains(widget.chapterNumber);

    return Scaffold(
      appBar: BackAppBar(
        context: context,
        title: 'Lekcja ${widget.chapterNumber}',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(lesson.title),
                    subtitle: Text('Poziom: $_level'),
                    trailing: alreadyCompleted
                        ? const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white, size: 18),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lekcja',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(lesson.theory),
                        const SizedBox(height: 12),
                        const Text('Przykłady:', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        ...lesson.examples.map((e) => Text('• $e')),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (alreadyCompleted)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Egzamin zaliczony ✅',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _examExpanded,
                      onExpansionChanged: (v) => setState(() => _examExpanded = v),
                      title: const Text(
                        'Egzamin (zaliczenie)',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('Zadanie ${idx + 1}/$totalTasks • Wynik: $_score/$totalTasks'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        const SizedBox(height: 6),
                        Text(task.prompt),
                        const SizedBox(height: 12),

                        if (task.type == TaskType.input) ...[
                          TextField(
                            controller: _inputCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Odpowiedź',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _answerInput(task, totalTasks),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () => _answerInput(task, totalTasks),
                            child: const Text('Dalej'),
                          ),
                        ] else ...[
                          ...(task.options ?? []).map((opt) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () => _answerAbcd(task, opt, totalTasks),
                                  child: Text(opt),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}