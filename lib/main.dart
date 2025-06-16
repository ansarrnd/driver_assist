import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  // Initialize FFI for sqflite on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Recommended for new Flutter projects
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // To keep track of the selected tab index

  // List of widgets to display in the body based on the selected tab
  static const List<Widget> _widgetOptions = <Widget>[
    DriveScheduleScreen(),
    AddScreen(), // This will be AddScreen in "add mode"
    SettingsScreen(),
  ];

  // List of titles for the AppBar corresponding to each tab
  static const List<String> _appBarTitles = <String>[
    'Drive Schedule',
    'Add Item', // You can customize this title
    'Settings',
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Dynamically set the title based on the selected tab
        title: Text(_appBarTitles[_selectedIndex]),
      ),
      body: Center(
        // Display the widget from _widgetOptions based on the selected index
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.drive_eta),
            label: 'Drive Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // Or your theme's primary color
        onTap: _onItemTapped,
      ),
    );
  }
}

// Data model for a drive entry
class DriveEntry {
  final String customerName;
  final DateTime dateTime; // Changed from TimeOfDay to DateTime
  final String source;
  final String destination;
  final String? id; // Optional: for unique identification

  DriveEntry({
    required this.customerName,
    required this.dateTime,
    required this.source,
    required this.destination,
    this.id,
  });

  // Convert a DriveEntry into a Map. Keys must correspond to column names in the database.
  Map<String, dynamic> toMap() {
    return {
      // DatabaseHelper.columnId is auto-generated for new entries,
      // but needed for updates. If id is null, it means it's a new entry.
      if (id != null) DatabaseHelper.columnId: int.tryParse(id!),
      DatabaseHelper.columnCustomerName: customerName,
      // Store DateTime as ISO8601 string
      DatabaseHelper.columnDateTime: dateTime.toIso8601String(),
      DatabaseHelper.columnSource: source,
      DatabaseHelper.columnDestination: destination,
    };
  }

  // Create a DriveEntry from a map retrieved from the database.
  factory DriveEntry.fromMap(Map<String, dynamic> map) {
    return DriveEntry(
      id: map[DatabaseHelper.columnId]?.toString(), // SQLite ID is integer
      customerName: map[DatabaseHelper.columnCustomerName],
      dateTime: DateTime.parse(map[DatabaseHelper.columnDateTime] as String),
      source: map[DatabaseHelper.columnSource],
      destination: map[DatabaseHelper.columnDestination],
    );
  }
}

// Screen to display the list of drive schedules
class DriveScheduleScreen extends StatefulWidget {
  const DriveScheduleScreen({super.key});
  @override
  State<DriveScheduleScreen> createState() => _DriveScheduleScreenState();
}

class _DriveScheduleScreenState extends State<DriveScheduleScreen> {
  // Filter options
  final List<String> _filterOptions = ['Today', 'Week', 'Month'];
  String _selectedFilter = 'Month'; // Default filter
  late Future<List<DriveEntry>> _driveEntriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDriveEntries();
  }

  void _refreshDriveEntries() {
    setState(() {
      _driveEntriesFuture = DatabaseHelper.instance.getAllDriveEntries();
    });
  }

  // This method will filter the entries fetched from the database
  List<DriveEntry> _getFilteredEntries(List<DriveEntry> allEntries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Today') {
      return allEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entryDate.isAtSameMomentAs(today);
      }).toList();
    } else if (_selectedFilter == 'Week') {
      // Assuming week starts on Monday (weekday 1) and ends on Sunday (weekday 7)
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return allEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return !entryDate.isBefore(startOfWeek) && !entryDate.isAfter(endOfWeek);
      }).toList();
    } else if (_selectedFilter == 'Month') {
      return allEntries.where((entry) {
        return entry.dateTime.year == now.year && entry.dateTime.month == now.month;
      }).toList();
    }
    return allEntries; // Default fallback, though should not be reached
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              labelText: 'Filter by',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            items: _filterOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                  // Re-filtering happens in the FutureBuilder based on the new _selectedFilter
                  // No need to call _refreshDriveEntries unless you want to re-fetch from DB on filter change
                });
              }
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DriveEntry>>(
            future: _driveEntriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No drive schedules available.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              } else {
                final allEntries = snapshot.data!;
                final displayedEntries = _getFilteredEntries(allEntries);

                if (displayedEntries.isEmpty && allEntries.isNotEmpty) {
                  // This means filtering resulted in an empty list, but there is data
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No drive schedules found for "$_selectedFilter".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  itemCount: displayedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = displayedEntries[index];
                    return InkWell( // Keep InkWell for potential future taps or just for the ripple effect
                      child: Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.customerName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8.0),
                              _buildInfoRow(context, Icons.access_time, 'Time: ${TimeOfDay.fromDateTime(entry.dateTime).format(context)}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.location_on_outlined, 'From: ${entry.source}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.flag_outlined, 'To: ${entry.destination}'),
                            ],
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
    );
  }
}

Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
  return Row(
    children: <Widget>[
      Icon(icon, size: 18.0, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8.0),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}



// Placeholder screen for Add
// This screen can now also be used for editing an existing entry.
class AddScreen extends StatefulWidget {
  final DriveEntry? entryToEdit; // If null, it's "Add" mode. Otherwise, "Edit" mode.

  const AddScreen({super.key, this.entryToEdit});

 @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // For Date
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _isEditMode => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final entry = widget.entryToEdit!;
      _customerNameController.text = entry.customerName;
      _selectedDate = entry.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(entry.dateTime);
      _dateController.text = "${_selectedDate!.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      _timeController.text = _selectedTime!.format(context); // Format for display
      _sourceController.text = entry.source;
      _destinationController.text = entry.destination;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context); // Format the time for the text field
      });
    }
  }

  void _submitForm() async { // Make the method async
    if (_formKey.currentState!.validate()) {
      // Process the data
      String customerName = _customerNameController.text;
      String source = _sourceController.text;
      String destination = _destinationController.text;

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time.')),
        );
        return;
      }

      final DateTime combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (_isEditMode) {
        DriveEntry updatedEntry = DriveEntry(
          id: widget.entryToEdit!.id, // Crucial for update
          customerName: customerName,
          dateTime: combinedDateTime,
          source: source,
          destination: destination,
        );
        try {
          await DatabaseHelper.instance.updateDriveEntry(updatedEntry);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive entry updated successfully!')),
          );
          if (mounted) Navigator.pop(context, true); // Pop and signal success
        } catch (e) {
          print('Error updating drive entry: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update entry: $e')),
          );
        }
      } else { // Add new entry
        DriveEntry newEntry = DriveEntry(
          customerName: customerName,
          dateTime: combinedDateTime,
          source: source,
          destination: destination,
        );

        try {
          final id = await DatabaseHelper.instance.insertDriveEntry(newEntry);
          print('Inserted drive entry with id: $id');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive entry saved successfully!')),
          );

          // Clear the form
          _customerNameController.clear();
          _dateController.clear();
          _timeController.clear();
          _sourceController.clear();
          _destinationController.clear();
          setState(() {
            _selectedDate = null;
            _selectedTime = null;
          });
          // Note: If this AddScreen is a tab, DriveScheduleScreen won't auto-refresh
          // unless specific state management or callback is implemented.
          // This is handled for edit mode by popping and checking the result.
        } catch (e) {
          print('Error saving drive entry: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _customerNameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget formContent = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling if the form gets long
            children: <Widget>[
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0), // Space between fields
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Source'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter source location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditMode ? 'Update Entry' : 'Add Entry'),
              ),
            ],
          ),
        ),
      );

    if (_isEditMode) {
      // If in edit mode (navigated to directly), provide a Scaffold
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Drive Entry'),
        ),
        body: formContent,
      );
    } else {
      // If in add mode (used as a tab), return just the form content
      return formContent;
    }
  }
}

// Placeholder screen for Settings
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
        // final int? entryId = int.tryParse(entryIdString); // No longer needed here
        // if (entryId != null) { // Check if entryIdString is valid before parsing in DatabaseHelper
          try {
            await DatabaseHelper.instance.deleteDriveEntry(entryIdString); // Pass the String ID
            successCount++;
          } catch (e) {
            print('Error deleting entry ID $entryIdString: $e');
            failCount++;
          }
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
      body: FutureBuilder<List<DriveEntry>>(
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: CheckboxListTile(
                    title: Text(entry.customerName),
                    subtitle: Text(
                        '${entry.source} to ${entry.destination}\n${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                    value: isSelected,
                    onChanged: entry.id == null ? null : (bool? selected) {
                      _toggleSelection(entry.id!);
                    },
                    secondary: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
