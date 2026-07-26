import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'theme_event.dart';
import '../../../../../core/theme/theme.dart';

class ThemeState extends Equatable {
  final ThemeData themeData;
  final ThemeType themeType;

  const ThemeState({required this.themeData, required this.themeType});

  factory ThemeState.initial() {
    return ThemeState(themeData: AppTheme.rcbTheme, themeType: ThemeType.rcb);
  }

  @override
  List<Object> get props => [themeData, themeType];
}
