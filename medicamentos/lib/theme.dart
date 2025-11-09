import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Paleta de colores profesional
  static const Color primary = Color(0xFF3498DB); // Azul brillante
  static const Color secondary = Color(0xFFE74C3C); // Rojo
  static const Color dark = Color(0xFF2C3E50); // Azul oscuro
  static const Color light = Color(0xFFECF0F1); // Gris claro

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: secondary,
      onError: Colors.white,
      background: light,
      onBackground: dark,
      surface: Colors.white,
      onSurface: dark,
      tertiary: dark,
      onTertiary: Colors.white,
      primaryContainer: Color(0xFF2D81B9),
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFFC0392B),
      onSecondaryContainer: Colors.white,
      surfaceContainerHighest: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: light,

      // 🧭 AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // 🧱 Tarjetas
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // 📝 Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: dark.withOpacity(.6)),
        labelStyle: TextStyle(color: dark.withOpacity(.9)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark.withOpacity(.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark.withOpacity(.15)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: secondary),
        ),
      ),

      // 📜 Listas
      listTileTheme: const ListTileThemeData(
        iconColor: dark,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: dark,
        ),
        subtitleTextStyle: TextStyle(fontSize: 13, color: Colors.black54),
      ),

      // 🔘 Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: dark.withOpacity(.25), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: dark,
        ),
      ),

      // 🔔 Snackbars
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      // ⏳ Indicadores
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),

      // ➖ Divisores
      dividerTheme: DividerThemeData(
        color: dark.withOpacity(.12),
        thickness: 1,
      ),

      // 💬 Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
