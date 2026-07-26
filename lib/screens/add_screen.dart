import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import '../database_helper.dart';
import '../models/drive_entry.dart';
import '../services/notification_service.dart';
import '../theme.dart';

// Screen for Add
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
  String _selectedType = 'trip'; // Default to 'trip'

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
      _selectedType = entry.type; // Initialize type for edit mode
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
          // type: widget.entryToEdit!.type, // Type is not changed in edit mode
        );
        try {
          await DatabaseHelper.instance.updateDriveEntry(updatedEntry);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive entry updated successfully!')),
          );
          // Schedule notification for the updated entry
          await notificationService.scheduleDriveNotification(updatedEntry);
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
          type: _selectedType, // Use the selected type
        );

        try {
          final insertedId = await DatabaseHelper.instance.insertDriveEntry(newEntry);
          print('Inserted drive entry with id: $insertedId');

          // Create a DriveEntry instance that includes the ID for notification scheduling
          DriveEntry entryForNotification = DriveEntry(
            id: insertedId.toString(), // Use the ID returned from the database
            customerName: customerName,
            dateTime: combinedDateTime,
            source: source,
            destination: destination,
            type: _selectedType, // Include type for notification if needed
          );
          await notificationService.scheduleDriveNotification(entryForNotification);

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
            _selectedType = 'trip'; // Reset type to default
          });
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
        child: LiquidGlassContainer(
          blur: AppTheme.defaultBlur,
          opacity: AppTheme.defaultOpacity,
          borderRadius: AppTheme.defaultBorderRadius,
          padding: const EdgeInsets.all(16.0),
          child: Form(
          key: _formKey, // Wrap with SingleChildScrollView to prevent overflow
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Type Selection
              const Text('Item Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Trip'),
                      value: 'trip',
                      groupValue: _selectedType,
                      // Disable type change in edit mode
                      onChanged: _isEditMode ? null : (String? value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Ticket'),
                      value: 'ticket',
                      groupValue: _selectedType,
                      // Disable type change in edit mode
                      onChanged: _isEditMode ? null : (String? value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Space after type selection
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
                decoration: const InputDecoration(labelText: 'Pickup'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Drop'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter drop location';
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
