import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import '../database_helper.dart';
import '../models/drive_entry.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<DriveEntry>> _driveEntriesFuture;
  List<DriveEntry> _allEntries = [];
  final Set<String> _selectedEntryIds = {}; // Store String IDs from DriveEntry.id

  @override
  void initState() {
    super.initState();
    _refreshDriveEntries();
  }

  void _refreshDriveEntries() {
    setState(() {
      _driveEntriesFuture = DatabaseHelper.instance.getAllDriveEntries().then((entries) {
        _allEntries = entries;
        return entries;
      });
      _selectedEntryIds.clear(); // Clear selection on refresh
    });
  }

  void _toggleSelection(String entryId) {
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
      int successCount = 0;
      int failCount = 0;
      List<String> idsToDelete = List.from(_selectedEntryIds);

      for (String entryIdString in idsToDelete) {
          try {
            await DatabaseHelper.instance.deleteDriveEntry(entryIdString); // Pass the String ID
            await notificationService.cancelNotification(entryIdString); // Cancel notification
            successCount++;
          } catch (e) {
            print('Error deleting entry ID $entryIdString: $e');
            failCount++;
          } // This closes the catch block
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount entries deleted. $failCount failed.')),
      );
      _refreshDriveEntries(); // Refresh the list and clear selection
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
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return DropdownButton<ThemeType>(
                      value: themeProvider.currentTheme,
                      onChanged: (ThemeType? newValue) {
                        if (newValue != null) {
                          themeProvider.setTheme(newValue);
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
            child: FutureBuilder<List<DriveEntry>>(
              future: _driveEntriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading entries: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No drive entries found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                } else {
                  // _allEntries is updated by _refreshDriveEntries
                  return ListView.builder(
                    itemCount: _allEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _allEntries[index];
                      // DriveEntry.id is String?, but should be non-null for DB entries
                      final isSelected = entry.id != null && _selectedEntryIds.contains(entry.id!);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: LiquidGlassContainer(
                          blur: AppTheme.defaultBlur,
                          opacity: AppTheme.defaultOpacity,
                          borderRadius: AppTheme.defaultBorderRadius,
                          child: Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                          title: Text(entry.customerName),
                          subtitle: Text(
                              'Pickup: ${entry.source} to Drop: ${entry.destination}\n${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                          value: isSelected,
                          onChanged: entry.id == null ? null : (bool? selected) {
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
