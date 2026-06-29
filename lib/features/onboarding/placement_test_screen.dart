import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/ui/app_colors.dart';
import 'questions_bank_en.dart';

class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  static const int _totalQuestions = 10;
  static const int _needInput = 6;
  static const int _needAbcd = 4;

  // krok 1: wybór języków, krok 2: egzamin
  bool _started = false;

  // języki (UI)
  final String _sourceLang = 'pl'; // tylko PL (domyślnie)
  String? _targetLang; // null = nie wybrano

  // egzamin
  late List<QuizQuestion> _selected;
  int _index = 0;
  int _score = 0;
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  List<QuizQuestion> _pickQuestions(List<QuizQuestion> pool) {
    final rng = Random();

    final inputs = pool.where((q) => q.type == QuestionType.input).toList()..shuffle(rng);
    final abcds = pool.where((q) => q.type == QuestionType.abcd).toList()..shuffle(rng);

    final pickedInputs = inputs.take(_needInput).toList();
    final pickedAbcds = abcds.take(_needAbcd).toList();

    final picked = [...pickedInputs, ...pickedAbcds]..shuffle(rng);

    // bezpieczeństwo: jeśli ktoś zmieni pulę i zabraknie pytań
    if (picked.length != _totalQuestions) {
      final indices = <int>{};
      while (indices.length < min(_totalQuestions, pool.length)) {
        indices.add(rng.nextInt(pool.length));
      }
      final fallback = indices.map((i) => pool[i]).toList()..shuffle(rng);
      return fallback;
    }

    return picked;
  }

  QuizQuestion get _q => _selected[_index];
  String _normalize(String s) => s.trim().toLowerCase();

  Future<void> _startExam() async {
    if (_targetLang == null) return;

    // zapis “języka do nauki” (u Ciebie to learningLanguage)
    await ref.read(appStateProvider.notifier).setLearningLanguage(_targetLang!);

    setState(() {
      _started = true;
      _index = 0;
      _score = 0;
      _inputCtrl.clear();

      // na start: EN (PL -> EN)
      _selected = _pickQuestions(QuestionsBankEn.pool);
    });
  }

  void _answerInput() {
    final userAnswer = _normalize(_inputCtrl.text);
    final correct = _normalize(_q.correct);

    if (userAnswer.isNotEmpty && userAnswer == correct) {
      _score += 1;
    }

    _inputCtrl.clear();
    _nextOrFinish();
  }

  void _answerAbcd(String chosen) {
    if (_normalize(chosen) == _normalize(_q.correct)) {
      _score += 1;
    }
    _nextOrFinish();
  }

  Future<void> _finish() async {
    final level = (_score >= 8)
        ? 'C'
        : (_score >= 4)
            ? 'B'
            : 'A';

    await ref.read(appStateProvider.notifier).setLevelAndFinishOnboarding(level);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ustawiono poziom: $level')),
    );
  }

  void _nextOrFinish() {
    if (_index >= _totalQuestions - 1) {
      _finish();
      return;
    }
    setState(() => _index += 1);
  }

  Widget _languagePickerCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.language, size: 30),
            const SizedBox(height: 10),
            const Text(
              'Wybierz języki',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Wybierz język, który rozumiesz oraz język, którego chcesz się nauczyć.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // 1) język, który rozumiesz (tylko PL)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Język, który rozumiesz',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sourceLang,
              items: const [
                DropdownMenuItem(
                  value: 'pl',
                  child: Text('🇵🇱  Polski'),
                ),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(
                labelText: 'Wybierz język',
              ),
            ),

            const SizedBox(height: 16),

            // 2) język do nauki (domyślnie pusty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Język, którego chcesz się nauczyć',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _targetLang,
              hint: const Text('Wybierz język'),
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('🇬🇧  English'),
                ),
              ],
              onChanged: (v) => setState(() => _targetLang = v),
              decoration: const InputDecoration(
                labelText: 'Wybierz język',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _examView() {
    final progress = (_index + 1) / _totalQuestions;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(value: progress, minHeight: 10),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_index + 1}/$_totalQuestions',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(Icons.quiz_outlined, size: 28),
                const SizedBox(height: 10),
                Text(
                  _q.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _q.type == QuestionType.input ? 'Odpowiedź wpisz niżej' : 'Wybierz jedną odpowiedź',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (_q.type == QuestionType.input) ...[
          TextField(
            controller: _inputCtrl,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Twoja odpowiedź',
            ),
            onSubmitted: (_) => _answerInput(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _answerInput,
              child: const Text('Dalej'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ListView.separated(
              itemCount: (_q.options ?? []).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final opt = _q.options![i];
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: () => _answerAbcd(opt),
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // ✅ USUNIĘTE: "Aktualny wynik: ..."
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _targetLang != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test poziomujący'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _started
              ? _examView()
              : Column(
                  children: [
                    const SizedBox(height: 6),
                    _languagePickerCard(),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        onPressed: canStart ? _startExam : null,
                        child: const Text('Przejdź do egzaminu'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}