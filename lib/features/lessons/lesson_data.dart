// lib/features/lessons/lesson_data.dart

enum TaskType { input, abcd }

class LessonTask {
  final TaskType type;
  final String prompt;
  final List<String>? options;
  final String correct;

  const LessonTask.input({
    required this.prompt,
    required this.correct,
  })  : type = TaskType.input,
        options = null;

  const LessonTask.abcd({
    required this.prompt,
    required this.options,
    required this.correct,
  }) : type = TaskType.abcd;
}

class LessonContent {
  final String title;
  final String theory;
  final List<String> examples;

  const LessonContent({
    required this.title,
    required this.theory,
    required this.examples,
  });
}

class LessonPack {
  final LessonContent content;
  final List<LessonTask> tasks;

  const LessonPack({
    required this.content,
    required this.tasks,
  });
}

/// level: 'A' | 'B' | 'C'
/// chapter: 1..4  (2 rozdziały × 2 lekcje)
class LessonData {
  static const int chaptersPerLevel = 4;

  static LessonPack getPack({required String level, required int chapter}) {
    final lvl = (level.isEmpty ? 'A' : level).toUpperCase();
    final ch = chapter.clamp(1, chaptersPerLevel);

    final byLevel = _data[lvl] ?? _data['A']!;
    return byLevel[ch]!;
  }

  static final Map<String, Map<int, LessonPack>> _data = {
    // ===================== LEVEL A =====================
    'A': {
      1: LessonPack(
        content: const LessonContent(
          title: 'To be + basic sentences',
          theory:
              'Czasownik "to be" oznacza "być". Używamy go do opisu osoby, stanu i miejsca.\n'
              'I am, You are, He/She/It is, We are, They are.',
          examples: [
            'I am Dawid.',
            'She is tired.',
            'They are in Kraków.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: I ___ happy.',
            options: ['is', 'are', 'am', 'be'],
            correct: 'am',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: He ___ my friend.',
            options: ['am', 'is', 'are', 'be'],
            correct: 'is',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: They ___ at home.',
            correct: 'are',
          ),
          LessonTask.input(
            prompt: 'Przetłumacz na EN: "Jestem studentem" → I ___ a student.',
            correct: 'am',
          ),
        ],
      ),

      2: LessonPack(
        content: const LessonContent(
          title: 'Present Simple — routines',
          theory:
              'Present Simple używamy do rutyn i faktów.\n'
              'He/She/It: do czasownika dodajemy -s/-es.',
          examples: [
            'I work on Mondays.',
            'She reads books.',
            'We play games.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: She ___ coffee every morning.',
            options: ['drink', 'drinks', 'drinking', 'drank'],
            correct: 'drinks',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: We ___ to the gym on Friday.',
            options: ['go', 'goes', 'going', 'gone'],
            correct: 'go',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij (3 os.): He ___ (watch) TV.',
            correct: 'watches',
          ),
          LessonTask.input(
            prompt: 'EN: "uczyć się" (w zdaniu: I ___ English.)',
            correct: 'study',
          ),
        ],
      ),

      3: LessonPack(
        content: const LessonContent(
          title: 'There is / There are + places',
          theory:
              'There is = jest (liczba pojedyncza).\n'
              'There are = są (liczba mnoga).\n'
              'Używamy do opisu, co gdzie się znajduje.',
          examples: [
            'There is a bank near my house.',
            'There are two chairs in the room.',
            'There is a phone on the desk.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: There ___ a shop on this street.',
            options: ['is', 'are', 'am', 'be'],
            correct: 'is',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: There ___ three windows.',
            options: ['is', 'are', 'am', 'be'],
            correct: 'are',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: There ___ a car in the parking lot.',
            correct: 'is',
          ),
          LessonTask.input(
            prompt:
                'Przetłumacz na EN: "Są dwie książki na stole" → There ___ two books on the table.',
            correct: 'are',
          ),
        ],
      ),

      4: LessonPack(
        content: const LessonContent(
          title: 'Have got + possessives',
          theory:
              'Have got używamy do mówienia, co posiadamy.\n'
              'I have got / You have got / He has got.\n'
              'Zaimek dzierżawczy: my, your, his, her, our, their.',
          examples: [
            'I have got a car.',
            'He has got a new phone.',
            'This is my book. That is her bag.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: He ___ got a laptop.',
            options: ['have', 'has', 'is', 'are'],
            correct: 'has',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: This is ___ phone (ja).',
            options: ['my', 'me', 'mine', 'I'],
            correct: 'my',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: I have ___ got a dog. (wstaw: got / - )',
            correct: 'got',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: They have got ___ tickets.',
            correct: 'their',
          ),
        ],
      ),
    },

    // ===================== LEVEL B =====================
    'B': {
      1: LessonPack(
        content: const LessonContent(
          title: 'Past Simple — yesterday',
          theory:
              'Past Simple używamy do zakończonych czynności w przeszłości.\n'
              'Regular: work → worked\n'
              'Irregular: go → went',
          examples: [
            'I visited my friend yesterday.',
            'She went to work.',
            'We played football.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: I ___ to Warsaw last week.',
            options: ['go', 'went', 'gone', 'going'],
            correct: 'went',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: They ___ a movie yesterday.',
            options: ['watch', 'watched', 'watching', 'watches'],
            correct: 'watched',
          ),
          LessonTask.input(
            prompt: 'Regular verb: clean → ___ (Past Simple)',
            correct: 'cleaned',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: She ___ (have) a meeting yesterday.',
            correct: 'had',
          ),
        ],
      ),

      2: LessonPack(
        content: const LessonContent(
          title: 'Present Continuous — now',
          theory:
              'Present Continuous: am/is/are + verb-ing.\n'
              'Używamy do czynności dziejących się teraz.',
          examples: [
            'I am writing now.',
            'He is working today.',
            'They are playing outside.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: I ___ dinner right now.',
            options: ['cook', 'cooks', 'am cooking', 'cooked'],
            correct: 'am cooking',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: She ___ on the phone.',
            options: ['talks', 'is talking', 'talked', 'talking'],
            correct: 'is talking',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: We are ___ (study) for the test.',
            correct: 'studying',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: They are ___ (run) in the park.',
            correct: 'running',
          ),
        ],
      ),

      3: LessonPack(
        content: const LessonContent(
          title: 'Comparatives — comparing things',
          theory:
              'Porównania: fast → faster, big → bigger.\n'
              'Dłuższe przymiotniki: more interesting.',
          examples: [
            'This car is faster than that one.',
            'Kraków is bigger than my town.',
            'This book is more interesting.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt:
                'Wybierz poprawnie: This task is ___ than the previous one.',
            options: ['easy', 'easier', 'easiest', 'more easy'],
            correct: 'easier',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: My phone is ___ than yours.',
            options: ['new', 'newer', 'newest', 'more new'],
            correct: 'newer',
          ),
          LessonTask.input(
            prompt:
                'Uzupełnij: This movie is more ___ (interesting) than that one.',
            correct: 'interesting',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: Warsaw is ___ (big) than my city.',
            correct: 'bigger',
          ),
        ],
      ),

      4: LessonPack(
        content: const LessonContent(
          title: 'Must / Have to — obligation',
          theory:
              'Must / have to = musieć.\n'
              'Must: bardziej "wewnętrzny obowiązek".\n'
              'Have to: obowiązek z zewnątrz (zasady, praca).',
          examples: [
            'I must study today.',
            'I have to go to work at 8.',
            'You must wear a seatbelt.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: I ___ to pay the bill today.',
            options: ['must', 'am', 'have', 'has'],
            correct: 'must',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: She ___ to wake up early for work.',
            options: ['have to', 'has to', 'musts', 'is to'],
            correct: 'has to',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: We ___ follow the rules.',
            correct: 'have to',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: You ___ be careful.',
            correct: 'must',
          ),
        ],
      ),
    },

    // ===================== LEVEL C =====================
    'C': {
      1: LessonPack(
        content: const LessonContent(
          title: 'Present Perfect vs Past Simple',
          theory:
              'Present Perfect: have/has + V3 — efekt teraz / czas nieokreślony.\n'
              'Past Simple — gdy podajesz konkretny czas (yesterday, last week).',
          examples: [
            'I have seen this movie.',
            'I saw it yesterday.',
            'She has lived here for two years.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie (PP): I ___ this app before.',
            options: ['have used', 'used', 'use', 'am using'],
            correct: 'have used',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie (PS): I ___ it yesterday.',
            options: ['have tried', 'tried', 'try', 'am trying'],
            correct: 'tried',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: She has ___ (finish) her work.',
            correct: 'finished',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: We ___ (meet) last Friday.',
            correct: 'met',
          ),
        ],
      ),

      2: LessonPack(
        content: const LessonContent(
          title: 'First Conditional — real future',
          theory:
              'If + Present Simple, will + verb.\n'
              'Używamy do realnych sytuacji w przyszłości.',
          examples: [
            'If I have time, I will call you.',
            'If it rains, we will stay home.',
            'If you study, you will pass.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: If you ___ now, you will be late.',
            options: [
              'don’t leave',
              'won’t leave',
              'didn’t leave',
              'aren’t leave'
            ],
            correct: 'don’t leave',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: If it rains, we ___ at home.',
            options: ['will stay', 'stay', 'stayed', 'are staying'],
            correct: 'will stay',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: If I finish early, I ___ (go) to the gym.',
            correct: 'will go',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: If you study, you ___ (pass) the exam.',
            correct: 'will pass',
          ),
        ],
      ),

      3: LessonPack(
        content: const LessonContent(
          title: 'Passive voice — basic',
          theory:
              'Strona bierna: be + V3.\n'
              'Używamy, gdy ważna jest czynność lub obiekt, a nie wykonawca.',
          examples: [
            'The room is cleaned every day.',
            'This phone was made in China.',
            'The email is sent automatically.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: The room ___ every day.',
            options: ['cleans', 'is cleaned', 'cleaned', 'is cleaning'],
            correct: 'is cleaned',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: This car ___ in Japan.',
            options: ['makes', 'is made', 'made', 'is making'],
            correct: 'is made',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: The report is ___ (prepare) weekly.',
            correct: 'prepared',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: The message was ___ (send) yesterday.',
            correct: 'sent',
          ),
        ],
      ),

      4: LessonPack(
        content: const LessonContent(
          title: 'Reported Speech — basics',
          theory:
              'Mowa zależna: gdy relacjonujesz czyjeś słowa.\n'
              'Najprościej: "He said (that)..." i często cofamy czas.\n'
              'Present → Past, will → would.',
          examples: [
            'He said that he was tired.',
            'She said she would call me.',
            'They said they had time.',
          ],
        ),
        tasks: const [
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: He said he ___ tired.',
            options: ['is', 'was', 'will be', 'being'],
            correct: 'was',
          ),
          LessonTask.abcd(
            prompt: 'Wybierz poprawnie: She said she ___ call me.',
            options: ['will', 'would', 'is', 'was'],
            correct: 'would',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: They said they ___ time.',
            correct: 'had',
          ),
          LessonTask.input(
            prompt: 'Uzupełnij: I said I ___ ready.',
            correct: 'was',
          ),
        ],
      ),
    },
  };
}