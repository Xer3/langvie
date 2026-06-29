import 'package:flutter/material.dart';

class AppColors {
  // Paleta z Twojego screena
  static const yellow = Color(0xFFFFD36A); // #FFD36A
  static const orange = Color(0xFFFDA741); // #FDA741
  static const blue = Color(0xFF4A90E2);   // #4A90E2

  // ✅ seed do ThemeData (u Ciebie buildLightTheme używa AppColors.seed)
  static const seed = blue;

  // Tło i powierzchnie
  static const bg = yellow;
  static const surface = Color(0xFFFFFFFF);

  // Teksty
  static const textStrong = Color(0xFF121212);
  static const textOnBlue = Color(0xFFFFFFFF);

  // Border (delikatny)
  static const border = Color(0x1A000000); // czarny 10%
}