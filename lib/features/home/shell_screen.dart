import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  static const _navBlue = Color(0xFF4A90E2); // nasz niebieski

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: _navBlue,
        elevation: 0,
        height: 72,
        indicatorColor: Colors.transparent,

        // 🔥 TE DWIE LINIE SĄ KLUCZOWE
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        overlayColor: MaterialStateProperty.all(Colors.transparent),

        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.style, color: Colors.white),
            label: 'Fiszki',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.smart_toy, color: Colors.white),
            label: 'Asystent',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}