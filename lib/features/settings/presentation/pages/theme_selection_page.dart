import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  Color _getThemeColor(ThemeType type) {
    switch (type) {
      case ThemeType.rcb: return const Color(0xFFE50E2F);
      case ThemeType.csk: return const Color(0xFFfcca00);
      case ThemeType.mi: return const Color(0xFF004BA0);
      case ThemeType.kkr: return const Color(0xFFB3A123);
      case ThemeType.dc: return const Color(0xFFEF1A2D);
      case ThemeType.rr: return const Color(0xFFEA1A85);
      case ThemeType.pbks: return const Color(0xFFD71920);
      case ThemeType.srh: return const Color(0xFFF26522);
      case ThemeType.lsg: return const Color(0xFF00b1e5);
      case ThemeType.gt: return const Color(0xFFB19D5E);
    }
  }

  String _getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.rcb: return 'RCB';
      case ThemeType.csk: return 'CSK';
      case ThemeType.mi: return 'MI';
      case ThemeType.kkr: return 'KKR';
      case ThemeType.dc: return 'DC';
      case ThemeType.rr: return 'RR';
      case ThemeType.pbks: return 'PBKS';
      case ThemeType.srh: return 'SRH';
      case ThemeType.lsg: return 'LSG';
      case ThemeType.gt: return 'GT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ThemeType.values.map((theme) {
                final isSelected = state.themeType == theme;
                final themeColor = _getThemeColor(theme);
                return GestureDetector(
                  onTap: () {
                    context.read<ThemeBloc>().add(ChangeThemeEvent(theme));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withOpacity(0.2) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? themeColor : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getThemeName(theme),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? themeColor : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
