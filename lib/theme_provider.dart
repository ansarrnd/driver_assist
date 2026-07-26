import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

enum ThemeType { rcb, csk, mi, kkr, dc, rr, pbks, srh, lsg, gt }

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  ThemeType _currentTheme = ThemeType.rcb;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeType get currentTheme => _currentTheme;

  ThemeData get themeData {
    switch (_currentTheme) {
      case ThemeType.rcb:
        return AppTheme.rcbTheme;
      case ThemeType.csk:
        return AppTheme.cskTheme;
      case ThemeType.mi:
        return AppTheme.miTheme;
      case ThemeType.kkr:
        return AppTheme.kkrTheme;
      case ThemeType.dc:
        return AppTheme.dcTheme;
      case ThemeType.rr:
        return AppTheme.rrTheme;
      case ThemeType.pbks:
        return AppTheme.pbksTheme;
      case ThemeType.srh:
        return AppTheme.srhTheme;
      case ThemeType.lsg:
        return AppTheme.lsgTheme;
      case ThemeType.gt:
        return AppTheme.gtTheme;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'rcb';
    _currentTheme = ThemeType.values.firstWhere(
      (e) => e.toString().split('.').last == themeString,
      orElse: () => ThemeType.rcb,
    );
    notifyListeners();
  }

  Future<void> setTheme(ThemeType theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.toString().split('.').last);
    }
  }
}
