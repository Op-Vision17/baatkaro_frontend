import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Updated to #F3B10B
  static const Color primaryYellow = Color(0xFFF3B10B);
  static const Color accentYellow = Color(0xFFF3B10B);
  static const Color primaryBlack = Color(0xFF0a0a0a); // Darker black
  static const Color darkGrey = Color(0xFF1e1e1e); // Card/Container background
  static const Color mediumGrey = Color(0xFF2d2d2d); // Input fields
  static const Color lightGrey = Color(0xFF404040); // Borders
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFE0E0E0); // Secondary text

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryYellow,
      scaffoldBackgroundColor: primaryBlack,
      colorScheme: ColorScheme.dark(
        primary: primaryYellow,
        secondary: accentYellow,
        surface: darkGrey,
        background: primaryBlack,
        error: Colors.red.shade400,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryYellow,
        foregroundColor: primaryBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlack),
        titleTextStyle: TextStyle(
          color: primaryBlack,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mediumGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        labelStyle: TextStyle(color: offWhite, fontSize: 16),
        hintStyle: TextStyle(color: offWhite.withOpacity(0.5), fontSize: 14),
        prefixIconColor: primaryYellow,
        suffixIconColor: primaryYellow,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryBlack,
          disabledBackgroundColor: lightGrey,
          disabledForegroundColor: offWhite.withOpacity(0.5),
          elevation: 0,
          shadowColor: primaryYellow.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryYellow,
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryYellow,
          side: BorderSide(color: primaryYellow, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: primaryBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: primaryYellow, size: 24),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: white,
        iconColor: primaryYellow,
        tileColor: darkGrey,
        selectedTileColor: mediumGrey,
        selectedColor: primaryYellow,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: darkGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkGrey,
        modalBackgroundColor: darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: primaryYellow,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          color: primaryYellow,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: primaryYellow,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: offWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: offWhite,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(color: offWhite.withOpacity(0.7), fontSize: 12),
        labelLarge: TextStyle(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: offWhite,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(color: offWhite.withOpacity(0.7), fontSize: 11),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryYellow,
        circularTrackColor: lightGrey,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: primaryYellow.withOpacity(0.2),
        thickness: 1,
        space: 16,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGrey,
        contentTextStyle: TextStyle(color: white, fontSize: 14),
        actionTextColor: primaryYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
