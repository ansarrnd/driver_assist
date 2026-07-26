import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. ThemeExtension to hold the background decoration
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final BoxDecoration backgroundDecoration;

  const AppThemeExtension({required this.backgroundDecoration});

  @override
  ThemeExtension<AppThemeExtension> copyWith({BoxDecoration? backgroundDecoration}) {
    return AppThemeExtension(
      backgroundDecoration: backgroundDecoration ?? this.backgroundDecoration,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      backgroundDecoration: BoxDecoration.lerp(backgroundDecoration, other.backgroundDecoration, t)!,
    );
  }
}

class AppTheme {
  // Common values for LiquidGlassContainer
  static const double defaultBlur = 15.0;
  static const double defaultOpacity = 0.1;
  static final BorderRadius defaultBorderRadius = BorderRadius.circular(10.0);

  // Helper method to build themes for IPL teams
  static ThemeData _buildTeamTheme({
    required Color seedColor,
    required Color secondaryColor,
    required Color backgroundColor,
    required Color appBarTextColor,
    required Color buttonTextColor,
    required BoxDecoration backgroundDecoration,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      secondary: secondaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      extensions: [
        AppThemeExtension(backgroundDecoration: backgroundDecoration),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: appBarTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: secondaryColor,
        unselectedItemColor: Colors.white70,
        elevation: 10,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: secondaryColor,
        unselectedLabelColor: Colors.white70,
        indicatorColor: secondaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: buttonTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: secondaryColor, width: 1.5)),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
    );
  }

  // ---------------------------------------------------------
  // RCB Theme
  // ---------------------------------------------------------
  static final BoxDecoration rcbBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1A1A1A), Color(0xFF8B0000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get rcbTheme => _buildTeamTheme(
        seedColor: const Color(0xFFE50E2F),
        secondaryColor: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1A1A1A),
        appBarTextColor: const Color(0xFFD4AF37),
        buttonTextColor: Colors.white,
        backgroundDecoration: rcbBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // CSK Theme
  // ---------------------------------------------------------
  static final BoxDecoration cskBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF003b7a), Color(0xFFfcca00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get cskTheme => _buildTeamTheme(
        seedColor: const Color(0xFFfcca00),
        secondaryColor: const Color(0xFFff8200),
        backgroundColor: const Color(0xFF003b7a),
        appBarTextColor: Colors.white,
        buttonTextColor: const Color(0xFF003b7a),
        backgroundDecoration: cskBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // MI Theme
  // ---------------------------------------------------------
  static final BoxDecoration miBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF004BA0), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get miTheme => _buildTeamTheme(
        seedColor: const Color(0xFF004BA0),
        secondaryColor: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF004BA0),
        appBarTextColor: const Color(0xFFD4AF37),
        buttonTextColor: const Color(0xFFD4AF37),
        backgroundDecoration: miBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // KKR Theme
  // ---------------------------------------------------------
  static final BoxDecoration kkrBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1E1332), Color(0xFFB3A123)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get kkrTheme => _buildTeamTheme(
        seedColor: const Color(0xFF3A225D),
        secondaryColor: const Color(0xFFB3A123),
        backgroundColor: const Color(0xFF1E1332),
        appBarTextColor: const Color(0xFFB3A123),
        buttonTextColor: const Color(0xFFB3A123),
        backgroundDecoration: kkrBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // DC Theme
  // ---------------------------------------------------------
  static final BoxDecoration dcBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF000040), Color(0xFFEF1A2D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get dcTheme => _buildTeamTheme(
        seedColor: const Color(0xFF00008B),
        secondaryColor: const Color(0xFFEF1A2D),
        backgroundColor: const Color(0xFF000040),
        appBarTextColor: const Color(0xFFEF1A2D),
        buttonTextColor: Colors.white,
        backgroundDecoration: dcBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // RR Theme
  // ---------------------------------------------------------
  static final BoxDecoration rrBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF8A0F4D), Color(0xFF001D48)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get rrTheme => _buildTeamTheme(
        seedColor: const Color(0xFFEA1A85),
        secondaryColor: const Color(0xFF001D48),
        backgroundColor: const Color(0xFF8A0F4D),
        appBarTextColor: Colors.white,
        buttonTextColor: Colors.white,
        backgroundDecoration: rrBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // PBKS Theme
  // ---------------------------------------------------------
  static final BoxDecoration pbksBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF7A0E12), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get pbksTheme => _buildTeamTheme(
        seedColor: const Color(0xFFD71920),
        secondaryColor: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF7A0E12),
        appBarTextColor: const Color(0xFFD4AF37),
        buttonTextColor: Colors.white,
        backgroundDecoration: pbksBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // SRH Theme
  // ---------------------------------------------------------
  static final BoxDecoration srhBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF000000), Color(0xFFF26522)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get srhTheme => _buildTeamTheme(
        seedColor: const Color(0xFFF26522),
        secondaryColor: const Color(0xFFF26522),
        backgroundColor: const Color(0xFF111111),
        appBarTextColor: Colors.white,
        buttonTextColor: Colors.white,
        backgroundDecoration: srhBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // LSG Theme
  // ---------------------------------------------------------
  static final BoxDecoration lsgBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF005792), Color(0xFF00b1e5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get lsgTheme => _buildTeamTheme(
        seedColor: const Color(0xFF00b1e5),
        secondaryColor: const Color(0xFF00b1e5),
        backgroundColor: const Color(0xFF00223E),
        appBarTextColor: Colors.white,
        buttonTextColor: Colors.white,
        backgroundDecoration: lsgBackgroundDecoration,
      );

  // ---------------------------------------------------------
  // GT Theme
  // ---------------------------------------------------------
  static final BoxDecoration gtBackgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF060D18), Color(0xFFB19D5E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get gtTheme => _buildTeamTheme(
        seedColor: const Color(0xFF0B172A),
        secondaryColor: const Color(0xFFB19D5E),
        backgroundColor: const Color(0xFF060D18),
        appBarTextColor: const Color(0xFFB19D5E),
        buttonTextColor: const Color(0xFFB19D5E),
        backgroundDecoration: gtBackgroundDecoration,
      );
}
