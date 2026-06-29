// lib/features/lessons/chapter_result_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChapterResultScreen extends StatelessWidget {
  final int chapterNumber; // tu: numer lekcji 1..4
  final bool passed;
  final int score;
  final int total;
  final int passScore;

  const ChapterResultScreen({
    super.key,
    required this.chapterNumber,
    required this.passed,
    required this.score,
    required this.total,
    required this.passScore,
  });

  @override
  Widget build(BuildContext context) {
    final nextLesson = (chapterNumber + 1 <= 4) ? chapterNumber + 1 : chapterNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wynik — Lekcja $chapterNumber'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      passed ? Icons.emoji_events_outlined : Icons.error_outline,
                      size: 56,
                      color: passed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      passed ? 'Gratulacje! Zaliczone 🎉' : 'Nie zaliczone',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text('Wynik: $score/$total (próg: $passScore)'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => context.go('/chapter-list'),
                          child: const Text('Wróć do lekcji'),
                        ),
                        if (passed)
                          FilledButton(
                            onPressed: () => context.push('/chapter/$nextLesson'),
                            child: const Text('Następna lekcja'),
                          )
                        else
                          FilledButton(
                            onPressed: () => context.go('/chapter/$chapterNumber'),
                            child: const Text('Spróbuj ponownie'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}