import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app_state.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: LangvieRoot()));
}

class LangvieRoot extends ConsumerStatefulWidget {
  const LangvieRoot({super.key});

  @override
  ConsumerState<LangvieRoot> createState() => _LangvieRootState();
}

class _LangvieRootState extends ConsumerState<LangvieRoot> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loaded = true;
      Future.microtask(() async {
        await ref.read(appStateProvider.notifier).loadFromStorage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Langvie',
      theme: lightTheme,
      routerConfig: router,
    );
  }
}