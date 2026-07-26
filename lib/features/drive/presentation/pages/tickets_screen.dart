import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/drive_entity.dart';
import '../bloc/drive/drive_bloc.dart';
import '../bloc/drive/drive_state.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final List<String> _filterOptions = ['Today', 'Week', 'Month'];
  String _selectedFilter = 'Month';

  List<DriveEntity> _getFilteredEntries(List<DriveEntity> allEntries) {
    // Only show tickets
    final tickets = allEntries.where((e) => e.type == 'ticket').toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Today') {
      return tickets.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entryDate.isAtSameMomentAs(today);
      }).toList();
    } else if (_selectedFilter == 'Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return tickets.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return !entryDate.isBefore(startOfWeek) && !entryDate.isAfter(endOfWeek);
      }).toList();
    } else if (_selectedFilter == 'Month') {
      return tickets.where((entry) {
        return entry.dateTime.year == now.year && entry.dateTime.month == now.month;
      }).toList();
    }
    return tickets;
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
                });
              }
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<DriveBloc, DriveState>(
            builder: (context, state) {
              if (state is DriveLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DriveError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is DriveLoaded) {
                final allEntries = state.drives;
                final displayedEntries = _getFilteredEntries(allEntries);

                if (displayedEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No ticket entries available.',
                          style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    itemCount: displayedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = displayedEntries[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: InkWell(
                              onTap: () { HapticFeedback.selectionClick(); },
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
                                        _buildInfoRow(context, Icons.location_on_outlined, 'Pickup: ${entry.source}'),
                                        const SizedBox(height: 4.0),
                                        _buildInfoRow(context, Icons.flag_outlined, 'Drop: ${entry.destination}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
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
}