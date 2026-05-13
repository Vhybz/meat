import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.light().textTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryMaroon,
        primary: AppColors.primaryMaroon,
        surface: Colors.white,
        onSurface: AppColors.textDark,
        surfaceContainerHighest: AppColors.surfaceWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surfaceWhite,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: const BorderSide(color: AppColors.borderGray),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderGray),
    );
  }

  static ThemeData get darkTheme {
    // Elegant deep dark palette
    const darkSurface = Color(0xFF1E1E1E);
    const darkBg = Color(0xFF121212);
    const darkBorder = Color(0xFF2C2C2C);
    const primaryMaroonLight = Color(0xFF9E1B1B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      textTheme: GoogleFonts.montserratTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryMaroon,
        primary: primaryMaroonLight,
        secondary: const Color(0xFFE57373),
        surface: darkSurface,
        onSurface: const Color(0xFFE0E0E0),
        onSurfaceVariant: const Color(0xFFB0B0B0),
        surfaceContainerHighest: const Color(0xFF252525),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFB0B0B0)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: darkBorder),
        ),
        labelStyle: GoogleFonts.montserrat(color: const Color(0xFFB0B0B0)),
        hintStyle: GoogleFonts.montserrat(color: const Color(0xFF757575)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMaroonLight,
        foregroundColor: Colors.white,
      ),
    );
  }
}
