import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_state.dart';

import '../helpers/pump_app.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage secureStorage;
  late ThemeBloc bloc;

  setUpAll(() async {
    await configureTestEnvironment();
  });

  setUp(() {
    secureStorage = MockSecureStorage();
    bloc = ThemeBloc(secureStorage);
  });

  tearDown(() => bloc.close());

  group('ThemeBloc', () {
    blocTest<ThemeBloc, ThemeState>(
      'loads saved theme from secure storage',
      build: () {
        when(
          () => secureStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'csk');
        return bloc;
      },
      act: (bloc) => bloc.add(LoadThemeEvent()),
      expect: () => [
        isA<ThemeState>().having(
          (s) => s.themeType,
          'themeType',
          ThemeType.csk,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'defaults to rcb when storage is empty',
      build: () {
        when(
          () => secureStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadThemeEvent()),
      expect: () => [
        isA<ThemeState>().having(
          (s) => s.themeType,
          'themeType',
          ThemeType.rcb,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'persists theme change',
      build: () {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ChangeThemeEvent(ThemeType.mi)),
      expect: () => [
        isA<ThemeState>().having((s) => s.themeType, 'themeType', ThemeType.mi),
      ],
      verify: (_) {
        verify(
          () => secureStorage.write(key: 'selected_theme', value: 'mi'),
        ).called(1);
      },
    );
  });
}
