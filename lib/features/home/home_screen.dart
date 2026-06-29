// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color kPrimaryBlue = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    final lessons = [1, 2, 3, 4];
    final doneAll = lessons.every(state.completedChapters.contains);

    final level = (state.level ?? 'A').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langvie — Home'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: InkWell(
            onTap: () => context.push('/chapter-list'),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      doneAll ? Icons.verified : Icons.menu_book,
                      size: 58,
                      color: doneAll ? Colors.greenAccent : Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Poziom $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doneAll ? 'Kliknij, aby przejść do lekcji' : 'Kliknij, aby przejść do lekcji',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
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