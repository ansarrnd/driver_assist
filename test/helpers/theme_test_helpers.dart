import 'package:bloc_test/bloc_test.dart';

import 'package:driver_schedule/core/theme/theme.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_state.dart';

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

ThemeState themeStateFor(ThemeType type) {
  final themeData = switch (type) {
    ThemeType.rcb => AppTheme.rcbTheme,
    ThemeType.csk => AppTheme.cskTheme,
    ThemeType.mi => AppTheme.miTheme,
    ThemeType.kkr => AppTheme.kkrTheme,
    ThemeType.dc => AppTheme.dcTheme,
    ThemeType.rr => AppTheme.rrTheme,
    ThemeType.pbks => AppTheme.pbksTheme,
    ThemeType.srh => AppTheme.srhTheme,
    ThemeType.lsg => AppTheme.lsgTheme,
    ThemeType.gt => AppTheme.gtTheme,
  };

  return ThemeState(themeData: themeData, themeType: type);
}

String themeLabel(ThemeType type) {
  return switch (type) {
    ThemeType.rcb => 'RCB',
    ThemeType.csk => 'CSK',
    ThemeType.mi => 'MI',
    ThemeType.kkr => 'KKR',
    ThemeType.dc => 'DC',
    ThemeType.rr => 'RR',
    ThemeType.pbks => 'PBKS',
    ThemeType.srh => 'SRH',
    ThemeType.lsg => 'LSG',
    ThemeType.gt => 'GT',
  };
}
