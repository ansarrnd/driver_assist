import 'package:flutter/material.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'database_helper.dart';
import 'main.dart'; // Assuming DriveEntry is in main.dart
import 'theme.dart';

// Screen to display the list of ticket entries
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  // Filter options (can be customized for tickets if needed)
  final List<String> _filterOptions = ['Today', 'Week', 'Month'];
  String _selectedFilter = 'Month'; // Default filter
  late Future<List<DriveEntry>> _ticketEntriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshTicketEntries();
  }

  void _refreshTicketEntries() {
    setState(() {
      // Fetch only 'ticket' type entries
      _ticketEntriesFuture = DatabaseHelper.instance.getDriveEntriesByType('ticket');
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
                  // No need to call _refreshTicketEntries unless you want to re-fetch from DB on filter change
                });
              }
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DriveEntry>>(
            future: _ticketEntriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No ticket entries available.',
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
                        'No ticket entries found for "$_selectedFilter".',
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
                    // Display 'ticket' type entries
                    return InkWell( // Keep InkWell for potential future taps or just for the ripple effect
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: LiquidGlassContainer(
                          blur: AppTheme.defaultBlur,
                          opacity: AppTheme.defaultOpacity,
                          borderRadius: AppTheme.defaultBorderRadius,
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
                              _buildInfoRow(context, Icons.access_time, 'Date & Time: ${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.location_on_outlined, 'From: ${entry.source}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.flag_outlined, 'To: ${entry.destination}'),
                            ],
                          ),
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

// Helper function for building info rows (can be shared or duplicated)
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