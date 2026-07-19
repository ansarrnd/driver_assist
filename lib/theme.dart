import 'package:flutter/material.dart';

class AppTheme {
  // Common values for LiquidGlassContainer
  static const double defaultBlur = 15.0;
  static const double defaultOpacity = 0.1;
  static final BorderRadius defaultBorderRadius = BorderRadius.circular(10.0);
  
  static final BoxDecoration backgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1A1A1A), Color(0xFF8B0000)], // RCB Black to Deep Red
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get themeData {
    // RCB Seed Color: Vibrant Red, with a dark brightness
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE50E2F),
      secondary: const Color(0xFFD4AF37), // RCB Gold
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent, // Ensure the background decoration is visible
      
      // Global app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold), // Gold text for app bar
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),

      // Global Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A), // RCB Dark Charcoal
        selectedItemColor: Color(0xFFD4AF37), // RCB Gold
        unselectedItemColor: Colors.white70,
        elevation: 10,
      ),

      // Global Tab Bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: Color(0xFFD4AF37), // RCB Gold
        unselectedLabelColor: Colors.white70,
        indicatorColor: Color(0xFFD4AF37), // RCB Gold
      ),

      // Global elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50E2F), // Red background
          foregroundColor: Colors.white, // White text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),

      // Global input decoration for forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha((255 * 0.15).round()), // Lighter frosted feel for dark mode

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withAlpha((255 * 0.5).round())),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    );
  }
}
