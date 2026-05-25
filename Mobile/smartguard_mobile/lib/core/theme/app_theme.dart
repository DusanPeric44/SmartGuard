import 'package:flutter/material.dart';

import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF2563EB);
    const scaffold = Color(0xFF020617);
    const surface = Color(0xFF0F172A);
    const surfaceVariant = Color(0xFF1E293B);
    const outline = Color(0xFF334155);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: surface,
        ).copyWith(
          primary: seed,
          secondary: const Color(0xFF7C3AED),
          surface: surface,
          surfaceContainerHighest: surfaceVariant,
          outline: outline,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),
      textTheme: AppTypography.textTheme(base.textTheme),
    );
  }
}
