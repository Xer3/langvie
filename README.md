# Langvie

Langvie to aplikacja mobilna do nauki języka angielskiego przygotowana jako projekt inżynierski. Aplikacja umożliwia rejestrację i logowanie użytkownika, wykonanie testu poziomującego, korzystanie z fiszek, śledzenie profilu użytkownika oraz rozmowę z asystentem AI wspierającym naukę języka.

## Główne funkcjonalności

* rejestracja i logowanie użytkownika przez Firebase Authentication,
* resetowanie hasła przez email,
* onboarding użytkownika,
* test poziomujący z pytaniami zamkniętymi i otwartymi,
* system poziomu użytkownika,
* fiszki językowe z możliwością dodawania i edycji,
* tryb nauki fiszek,
* profil użytkownika z awatarem,
* asystent AI do nauki języka angielskiego,
* przechowywanie danych w Firebase,
* obsługa zapytań AI przez Firebase Cloud Functions.

## Technologie

Projekt został wykonany z użyciem:

* Flutter,
* Dart,
* Firebase Authentication,
* Cloud Firestore,
* Firebase Cloud Functions,
* Firebase Secret Manager,
* Riverpod,
* GoRouter,
* Dio,
* Google Fonts.

## Wymagane środowisko

Projekt był uruchamiany i testowany w następującym środowisku:

* System operacyjny: Windows 11, wersja 25H2
* Flutter: 3.41.1, channel stable
* Dart: 3.11.0
* DevTools: 2.54.1
* Android SDK: 36.0.0
* Git: 2.52.0.windows.1
* Node.js: 24.13.1
* npm: 11.8.0
* Firebase CLI: 15.6.0
* Visual Studio Build Tools: 2022, wersja 17.14.27

Polecenie `flutter doctor` nie wykazało problemów ze środowiskiem.

## Urządzenie testowe

Aplikacja była testowana na urządzeniu:

* motorola edge 30 pro
* Android 14
* API 34
* architektura: android-arm64

Aplikację można uruchamiać również na emulatorze Androida skonfigurowanym w Android Studio.

## Instalacja projektu

1. Sklonuj repozytorium:

```bash
git clone LINK_DO_REPOZYTORIUM
cd langvie
```

2. Pobierz zależności Fluttera:

```bash
flutter pub get
```

3. Sprawdź środowisko:

```bash
flutter doctor
```

4. Uruchom emulator Androida albo podłącz telefon z włączonym debugowaniem USB.

5. Sprawdź dostępne urządzenia:

```bash
flutter devices
```

6. Uruchom aplikację:

```bash
flutter run
```

W przypadku kilku dostępnych urządzeń można wskazać konkretne urządzenie:

```bash
flutter run -d ID_URZADZENIA
```

## Firebase

Projekt korzysta z Firebase do obsługi logowania, resetowania hasła, przechowywania danych oraz funkcji backendowych.

Wykorzystywane usługi Firebase:

* Firebase Authentication,
* Cloud Firestore,
* Firebase Cloud Functions,
* Firebase Secret Manager.

Pliki konfiguracyjne Firebase dla aplikacji mobilnej zostały wygenerowane przy użyciu FlutterFire CLI.

## Asystent AI

Aplikacja nie przechowuje klucza OpenAI API po stronie aplikacji mobilnej. Zapytania z aplikacji są wysyłane do Firebase Cloud Function, a dopiero funkcja backendowa komunikuje się z API OpenAI.

Schemat działania:

```txt
Aplikacja Flutter → Firebase Cloud Function → OpenAI API
```

Klucz API jest zapisany jako sekret Firebase i nie znajduje się w kodzie aplikacji ani w repozytorium.

## Uruchomienie Firebase Functions

Aby wdrożyć funkcję backendową we własnym projekcie Firebase:

1. Zaloguj się do Firebase CLI:

```bash
firebase login
```

2. Ustaw aktywny projekt Firebase:

```bash
firebase use --add
```

3. Ustaw sekret z kluczem OpenAI:

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

4. Wdróż funkcję:

```bash
firebase deploy --only functions:aiChat
```

5. Jeżeli adres funkcji jest inny niż w projekcie, należy zaktualizować go w pliku:

```txt
lib/features/ai_assistant/openai_client.dart
```

## Struktura projektu

Najważniejsze foldery projektu:

```txt
lib/
  app/
  features/
    ai_assistant/
    auth/
    flashcards/
    home/
    onboarding/
    profile/
  shared/

functions/
  index.js
```

## Bezpieczeństwo

W repozytorium nie należy umieszczać plików zawierających prywatne klucze API, takich jak:

```txt
.env
```

Klucz OpenAI API powinien być przechowywany wyłącznie jako sekret po stronie Firebase Cloud Functions.

## Autor

Projekt wykonany jako część pracy inżynierskiej.

Autor: Dawid Bodzęta
