import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/drive_entity.dart';
import '../bloc/drive/drive_bloc.dart';
import '../bloc/drive/drive_event.dart';
import '../../../../services/notification_service.dart';

class AddDriveEntryPage extends HookWidget {
  final DriveEntity? entryToEdit;

  const AddDriveEntryPage({super.key, this.entryToEdit});

  @override
  Widget build(BuildContext context) {
    final isEditMode = entryToEdit != null;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final customerNameController = useTextEditingController(text: entryToEdit?.customerName);
    final sourceController = useTextEditingController(text: entryToEdit?.source);
    final destinationController = useTextEditingController(text: entryToEdit?.destination);
    
    final selectedDate = useState<DateTime?>(entryToEdit?.dateTime);
    final selectedTime = useState<TimeOfDay?>(entryToEdit != null ? TimeOfDay.fromDateTime(entryToEdit!.dateTime) : null);
    
    final dateController = useTextEditingController(text: selectedDate.value != null ? "${selectedDate.value!.toLocal()}".split(' ')[0] : '');
    final timeController = useTextEditingController(text: selectedTime.value != null ? selectedTime.value!.format(context) : '');
    
    final selectedType = useState<String>(entryToEdit?.type ?? 'trip');
    final selectedAlarmOffset = useState<int?>(entryToEdit != null ? entryToEdit!.alarmOffsetMinutes : 1440); // 1440 = 1 day

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != selectedDate.value) {
        selectedDate.value = picked;
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      }
    }

    Future<void> selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value ?? TimeOfDay.now(),
      );
      if (picked != null && picked != selectedTime.value) {
        selectedTime.value = picked;
        timeController.text = picked.format(context);
      }
    }

    void submitForm() async {
      if (formKey.currentState!.validate()) {
        if (selectedDate.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date.')),
          );
          return;
        }
        if (selectedTime.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a time.')),
          );
          return;
        }

        final combinedDateTime = DateTime(
          selectedDate.value!.year,
          selectedDate.value!.month,
          selectedDate.value!.day,
          selectedTime.value!.hour,
          selectedTime.value!.minute,
        );

        final entry = DriveEntity(
          id: entryToEdit?.id,
          customerName: customerNameController.text,
          dateTime: combinedDateTime,
          source: sourceController.text,
          destination: destinationController.text,
          type: selectedType.value,
          alarmOffsetMinutes: selectedAlarmOffset.value,
        );

        // Dispatches to the BLoC which saves to the local datasource
        context.read<DriveBloc>().add(AddDriveEvent(entry));
        
        // Also schedule notification
        await notificationService.scheduleDriveNotification(entry);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? 'Drive entry updated successfully!' : 'Drive entry saved successfully!')),
        );

        if (isEditMode) {
          context.pop(true);
        } else {
          customerNameController.clear();
          dateController.clear();
          timeController.clear();
          sourceController.clear();
          destinationController.clear();
          selectedDate.value = null;
          selectedTime.value = null;
          selectedType.value = 'trip';
        }
      }
    }

    final formContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: LiquidGlassContainer(
        blur: AppTheme.defaultBlur,
        opacity: AppTheme.defaultOpacity,
        borderRadius: AppTheme.defaultBorderRadius,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Item Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        type: MaterialType.transparency,
                        child: RadioListTile<String>(
                          title: const Text('Trip'),
                          value: 'trip',
                          groupValue: selectedType.value,
                          onChanged: isEditMode ? null : (String? value) {
                            if (value != null) selectedType.value = value;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        type: MaterialType.transparency,
                        child: RadioListTile<String>(
                          title: const Text('Ticket'),
                          value: 'ticket',
                          groupValue: selectedType.value,
                          onChanged: isEditMode ? null : (String? value) {
                            if (value != null) selectedType.value = value;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter customer name' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => selectDate(context),
                  validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  readOnly: true,
                  onTap: () => selectTime(context),
                  validator: (value) => value == null || value.isEmpty ? 'Please select a time' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: sourceController,
                  decoration: const InputDecoration(labelText: 'Pickup'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter pickup location' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: destinationController,
                  decoration: const InputDecoration(labelText: 'Drop'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter drop location' : null,
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Set Reminder Alarm'),
                  value: selectedAlarmOffset.value,
                  onChanged: (int? newValue) {
                    selectedAlarmOffset.value = newValue;
                  },
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None (Remove Alarm)')),
                    DropdownMenuItem(value: 0, child: Text('At time of trip')),
                    DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                    DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    DropdownMenuItem(value: 1440, child: Text('1 day before')),
                  ],
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: submitForm,
                  child: Text(isEditMode ? 'Update Entry' : 'Add Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isEditMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Drive Entry')),
        body: formContent,
      );
    } else {
      return formContent;
    }
  }
}
