import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/theme/theme.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final FlutterSecureStorage secureStorage;
  static const String _themeKey = 'selected_theme';

  ThemeBloc(this.secureStorage) : super(ThemeState.initial()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    final themeString = await secureStorage.read(key: _themeKey) ?? 'rcb';
    final themeType = ThemeType.values.firstWhere(
      (e) => e.toString().split('.').last == themeString,
      orElse: () => ThemeType.rcb,
    );
    emit(ThemeState(themeData: _getThemeData(themeType), themeType: themeType));
  }

  Future<void> _onChangeTheme(ChangeThemeEvent event, Emitter<ThemeState> emit) async {
    await secureStorage.write(key: _themeKey, value: event.themeType.toString().split('.').last);
    emit(ThemeState(themeData: _getThemeData(event.themeType), themeType: event.themeType));
  }

  ThemeData _getThemeData(ThemeType type) {
    switch (type) {
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
}
