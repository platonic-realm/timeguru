import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';

import '../widgets/time_entry_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/add_time_entry_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_diary_entry_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeGuru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  _buildDateHeader(context, provider),
                  const SizedBox(height: 24),
                  
                  // Daily summary
                  if (provider.currentDailySummary != null)
                    DailySummaryCard(summary: provider.currentDailySummary!),
                  const SizedBox(height: 24),
                  
                  // Time entries section
                  _buildTimeEntriesSection(context, provider),
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  _buildQuickActions(context, provider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTimeEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, AppProvider provider) {
    final date = provider.selectedDate;
    final isToday = date.isAtSameMomentAs(DateTime.now());
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isToday ? Icons.today : Icons.calendar_today,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(date),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (isToday)
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () => _showDatePicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntriesSection(BuildContext context, AppProvider provider) {
    final timeEntries = provider.timeEntries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Entries',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${timeEntries.length} entries',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (timeEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No time entries yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your time by adding your first entry',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timeEntries.length,
            itemBuilder: (context, index) {
              final entry = timeEntries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TimeEntryCard(
                  entry: entry,
                  onEdit: () => _showEditTimeEntryDialog(context, entry),
                  onDelete: () => _showDeleteConfirmation(context, entry),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.task,
                title: 'Add Task',
                subtitle: 'Create new task',
                onTap: () => _showAddTaskDialog(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.book,
                title: 'Add Diary',
                subtitle: 'Write daily entry',
                onTap: () => _showAddDiaryDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Backup your data',
                onTap: () => _showExportDialog(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.calendar_month,
                title: 'Calendar',
                subtitle: 'View calendar',
                onTap: () => _showCalendarView(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog and navigation methods
  void _showDatePicker(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        provider.setSelectedDate(date);
      }
    });
  }

  void _showAddTimeEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeEntryDialog(),
    );
  }

  void _showEditTimeEntryDialog(BuildContext context, TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AddTimeEntryDialog(entry: entry),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Entry'),
        content: Text('Are you sure you want to delete "${entry.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteTimeEntry(entry.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showAddDiaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddDiaryEntryDialog(),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Export your TimeGuru data including time entries, tasks, diary entries, and calendar files. '
          'This will create a backup of all your data in the selected directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData(context);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = context.read<AppProvider>();
      await provider.exportData('/tmp/timeguru_export');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully to /tmp/timeguru_export'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCalendarView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Calendar View',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCalendarView(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    final provider = context.read<AppProvider>();
    final selectedDate = provider.selectedDate;
    
    return Column(
      children: [
        // Calendar header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                final newDate = selectedDate.subtract(const Duration(days: 1));
                provider.setSelectedDate(newDate);
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM y').format(selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: () {
                final newDate = selectedDate.add(const Duration(days: 1));
                provider.setSelectedDate(newDate);
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(context, selectedDate),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isSelected = date.isAtSameMomentAs(selectedDate);
      final isToday = date.isAtSameMomentAs(DateTime.now());
      
      days.add(
        GestureDetector(
          onTap: () {
            context.read<AppProvider>().setSelectedDate(date);
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected || isToday
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : isToday
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) => days[index],
    );
  }
}
