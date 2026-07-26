import 'package:equatable/equatable.dart';

enum ThemeType { rcb, csk, mi, kkr, dc, rr, pbks, srh, lsg, gt }

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object> get props => [];
}

class ChangeThemeEvent extends ThemeEvent {
  final ThemeType themeType;
  const ChangeThemeEvent(this.themeType);

  @override
  List<Object> get props => [themeType];
}

class LoadThemeEvent extends ThemeEvent {}
