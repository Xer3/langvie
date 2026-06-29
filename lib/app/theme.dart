import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/app_colors.dart';

const kNavOrange = Color(0xFFFDA741);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
  ),

  scaffoldBackgroundColor: AppColors.bg,
  textTheme: GoogleFonts.atmaTextTheme(),

  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),

  // ✅ NAVIGATION BAR — CAŁY POMARAŃCZOWY
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: kNavOrange,
    indicatorColor: Colors.transparent, // brak pill
    height: 72,
    elevation: 0,
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: Colors.black,
      ),
    ),
    iconTheme: const WidgetStatePropertyAll(
      IconThemeData(
        color: Colors.black,
        size: 26,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);