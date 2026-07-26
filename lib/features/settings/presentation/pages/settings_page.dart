import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import '../../../../core/theme/theme.dart';
import '../../../drive/presentation/bloc/drive/drive_bloc.dart';
import '../../../drive/presentation/bloc/drive/drive_event.dart';
import '../../../drive/presentation/bloc/drive/drive_state.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Set<int> _selectedEntryIds = {};

  void _toggleSelection(int entryId) {
    setState(() {
      if (_selectedEntryIds.contains(entryId)) {
        _selectedEntryIds.remove(entryId);
      } else {
        _selectedEntryIds.add(entryId);
      }
    });
  }

  Future<void> _deleteSelectedEntries() async {
    if (_selectedEntryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries selected for deletion.')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${_selectedEntryIds.length} selected entries? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final driveBloc = context.read<DriveBloc>();
      for (int id in _selectedEntryIds) {
        driveBloc.add(DeleteDriveEvent(id));
      }
      setState(() {
        _selectedEntryIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drive Entries'),
        actions: [
          if (_selectedEntryIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete Selected',
              onPressed: _deleteSelectedEntries,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('App Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return DropdownButton<ThemeType>(
                      value: state.themeType,
                      onChanged: (ThemeType? newValue) {
                        if (newValue != null) {
                          context.read<ThemeBloc>().add(ChangeThemeEvent(newValue));
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: ThemeType.rcb, child: Text('RCB Theme')),
                        DropdownMenuItem(value: ThemeType.csk, child: Text('CSK Theme')),
                        DropdownMenuItem(value: ThemeType.mi, child: Text('MI Theme')),
                        DropdownMenuItem(value: ThemeType.kkr, child: Text('KKR Theme')),
                        DropdownMenuItem(value: ThemeType.dc, child: Text('DC Theme')),
                        DropdownMenuItem(value: ThemeType.rr, child: Text('RR Theme')),
                        DropdownMenuItem(value: ThemeType.pbks, child: Text('PBKS Theme')),
                        DropdownMenuItem(value: ThemeType.srh, child: Text('SRH Theme')),
                        DropdownMenuItem(value: ThemeType.lsg, child: Text('LSG Theme')),
                        DropdownMenuItem(value: ThemeType.gt, child: Text('GT Theme')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Manage Drive Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: BlocBuilder<DriveBloc, DriveState>(
              builder: (context, state) {
                if (state is DriveLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DriveError) {
                  return Center(child: Text('Error loading entries: ${state.message}'));
                } else if (state is DriveLoaded) {
                  if (state.drives.isEmpty) {
                    return const Center(
                      child: Text(
                        'No drive entries found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.drives.length,
                    itemBuilder: (context, index) {
                      final entry = state.drives[index];
                      final isSelected = entry.id != null && _selectedEntryIds.contains(entry.id!);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: LiquidGlassContainer(
                          blur: AppTheme.defaultBlur,
                          opacity: AppTheme.defaultOpacity,
                          borderRadius: AppTheme.defaultBorderRadius,
                          child: Material(
                            type: MaterialType.transparency,
                            child: CheckboxListTile(
                              title: Text(entry.customerName),
                              subtitle: Text(
                                  'Pickup: ${entry.source} to Drop: ${entry.destination}\n${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                              value: isSelected,
                              onChanged: entry.id == null
                                  ? null
                                  : (bool? selected) {
                                      _toggleSelection(entry.id!);
                                    },
                              secondary: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                              isThreeLine: true,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
