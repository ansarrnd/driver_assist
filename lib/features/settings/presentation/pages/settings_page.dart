import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import '../../../../core/theme/theme.dart';
import 'theme_selection_page.dart';
import 'manage_drive_entries_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: LiquidGlassContainer(
              blur: AppTheme.defaultBlur,
              opacity: AppTheme.defaultOpacity,
              borderRadius: AppTheme.defaultBorderRadius,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('App Theme'),
                  subtitle: const Text('Change the visual style of the application'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSelectionPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: LiquidGlassContainer(
              blur: AppTheme.defaultBlur,
              opacity: AppTheme.defaultOpacity,
              borderRadius: AppTheme.defaultBorderRadius,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Manage Drive Entries'),
                  subtitle: const Text('View and delete your saved drive history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageDriveEntriesPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
