/// lib/features/onboarding/questions_bank_en.dart
/// Bank pytań (PL -> EN).
/// Test losuje 10 UNIKALNYCH pytań: 6 INPUT + 4 ABCD (bez powtórek).

enum QuestionType { input, abcd }

class QuizQuestion {
  final QuestionType type;
  final String prompt;

  final List<String>? options;
  final String correct;

  const QuizQuestion.input({
    required this.prompt,
    required this.correct,
  })  : type = QuestionType.input,
        options = null;

  const QuizQuestion.abcd({
    required this.prompt,
    required this.options,
    required this.correct,
  }) : type = QuestionType.abcd;
}

class QuestionsBankEn {
  static const List<QuizQuestion> pool = [
    // ===== INPUT (15) =====
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "dom"', correct: 'house'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "kot"', correct: 'cat'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "pies"', correct: 'dog'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "samochód"', correct: 'car'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "woda"', correct: 'water'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "książka"', correct: 'book'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "jabłko"', correct: 'apple'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "szkoła"', correct: 'school'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "przyjaciel"', correct: 'friend'),
    QuizQuestion.input(prompt: 'Przetłumacz na Angielski: "miasto"', correct: 'city'),

    QuizQuestion.input(prompt: 'Uzupełnij: I ___ a student.', correct: 'am'),
    QuizQuestion.input(prompt: 'Uzupełnij: She ___ coffee every day.', correct: 'drinks'),
    QuizQuestion.input(prompt: 'Uzupełnij: They ___ happy.', correct: 'are'),
    QuizQuestion.input(prompt: 'Uzupełnij: He ___ to school.', correct: 'goes'),
    QuizQuestion.input(prompt: 'Uzupełnij: We ___ English now.', correct: 'are learning'),

    // ===== ABCD (15) =====
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "I ___ from Poland."',
      options: ['are', 'is', 'am', 'be'],
      correct: 'am',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "She ___ English."',
      options: ['speak', 'speaks', 'speaking', 'spoke'],
      correct: 'speaks',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "We ___ football now."',
      options: ['play', 'plays', 'are playing', 'played'],
      correct: 'are playing',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne tłumaczenie "dzień dobry":',
      options: ['Good night', 'Good morning', 'Good bye', 'Thank you'],
      correct: 'Good morning',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "There ___ a book on the table."',
      options: ['are', 'is', 'am', 'be'],
      correct: 'is',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "He has ___ car."',
      options: ['a', 'an', 'the', 'no article'],
      correct: 'a',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "I don’t ___ coffee."',
      options: ['drinks', 'drink', 'drinking', 'drank'],
      correct: 'drink',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "They ___ yesterday."',
      options: ['go', 'went', 'going', 'gone'],
      correct: 'went',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "Can you ___ me?"',
      options: ['help', 'helps', 'helped', 'helping'],
      correct: 'help',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "I have lived here ___ 2020."',
      options: ['since', 'for', 'from', 'at'],
      correct: 'since',
    ),

    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "She ___ to work every day."',
      options: ['go', 'goes', 'going', 'gone'],
      correct: 'goes',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "We ___ a new phone."',
      options: ['have', 'has', 'having', 'had'],
      correct: 'have',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "He ___ not like pizza."',
      options: ['do', 'does', 'did', 'done'],
      correct: 'does',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "___ you speak English?"',
      options: ['Do', 'Does', 'Did', 'Done'],
      correct: 'Do',
    ),
    QuizQuestion.abcd(
      prompt: 'Wybierz poprawne: "My name ___ Dawid."',
      options: ['are', 'is', 'am', 'be'],
      correct: 'is',
    ),
  ];
}