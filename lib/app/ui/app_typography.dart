import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.textStrong,
    letterSpacing: -0.3,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textMuted,
  );

  static const section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textStrong,
  );
}