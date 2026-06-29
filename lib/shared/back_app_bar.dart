import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackAppBar extends AppBar {
  BackAppBar({
    super.key,
    required BuildContext context,
    required String title,
  }) : super(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
                return;
              }

              // fallback: wróć do Home (bez wchodzenia na siłę do chapter-list)
              GoRouter.of(context).go('/home');
            },
          ),
        );
}