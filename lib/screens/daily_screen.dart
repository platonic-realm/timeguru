import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/monthly_file.dart';
import '../models/time_entry.dart';
import '../widgets/add_diary_entry_dialog.dart';
import '../widgets/add_time_entry_dialog.dart';
import '../widgets/add_monthly_task_dialog.dart';
import '../utils/responsive_utils.dart';

class DailyScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailyScreen({super.key, this.initialDate});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late PageController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = PageController(initialPage: 1000); // Start at middle for infinite scrolling
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive utilities
    ResponsiveUtils.init(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return GestureDetector(
              onTap: () => _showDatePicker(context, provider),
              child: Container(
                padding: ResponsiveUtils.getResponsivePadding(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(12)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(provider.selectedDate),
                      style: ResponsiveUtils.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(8)),
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveUtils.getResponsiveIconSize(18),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.today,
              size: ResponsiveUtils.getResponsiveIconSize(24),
            ),
            onPressed: () => _goToToday(),
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
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
                    'Error: ${provider.error}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.clearError(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Daily content
              Expanded(
                child: _buildDailyContent(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDailyContent(AppProvider provider) {
    final dailyEntry = provider.getDailyEntry(provider.selectedDate);
    // Since MonthlyTask doesn't have a date field, we'll show all tasks for the month
    final monthTasks = provider.currentMonthlyFile?.tasks ?? [];
    final dayTimeEntries = provider.timeEntries
        .where((entry) => entry.date.year == provider.selectedDate.year &&
            entry.date.month == provider.selectedDate.month &&
            entry.date.day == provider.selectedDate.day)
        .toList();

    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily summary card
          _buildDailySummaryCard(dailyEntry, monthTasks, dayTimeEntries),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Tasks for the month (since tasks don't have specific dates)
          _buildTasksSection(monthTasks, provider),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Time entries for the day
          _buildTimeEntriesSection(dayTimeEntries, provider),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(DailyEntry? dailyEntry, List<MonthlyTask> tasks, List<TimeEntry> timeEntries) {
    final totalTaskTime = timeEntries.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    'Tasks',
                    '${tasks.length}',
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Time',
                    _formatDuration(totalTaskTime),
                    Icons.timelapse,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Categories',
                    timeEntries.map((e) => e.category).toSet().length.toString(),
                    Icons.category,
                  ),
                ),
              ],
            ),
            
            if (dailyEntry?.content.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dailyEntry!.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTasksSection(List<MonthlyTask> tasks, AppProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tasks for ${_formatDate(provider.selectedDate)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddTaskDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No tasks for this day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    leading: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: task.description != null ? Text(task.description!) : null,
                    trailing: Chip(
                      label: Text(task.priority),
                      backgroundColor: _getPriorityColor(task.priority),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntriesSection(List<TimeEntry> timeEntries, AppProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timelapse,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Entries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddTimeEntryDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (timeEntries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No time entries for this day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                  return ListTile(
                    leading: Icon(
                      _getCategoryIcon(entry.category),
                      color: _getCategoryColor(entry.category),
                    ),
                    title: Text(entry.description),
                    subtitle: Text('${entry.type} • ${entry.category}'),
                    trailing: Text(
                      _formatDuration(entry.duration),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _goToToday() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.goToToday();
  }

  void _showDatePicker(BuildContext context, AppProvider provider) {
    showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    ).then((pickedDate) {
      if (pickedDate != null) {
        provider.updateSelectedDate(pickedDate);
      }
    });
  }

  void _showAddEntryDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Add Diary Entry'),
              onTap: () {
                Navigator.pop(context);
                _showAddDiaryEntryDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Add Time Entry'),
              onTap: () {
                Navigator.pop(context);
                _showAddTimeEntryDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const AddMonthlyTaskDialog(),
    ).then((task) {
      if (task != null) {
        provider.addTask(task);
      }
    });
  }

  void _showAddDiaryEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddDiaryEntryDialog(),
    );
  }

  void _showAddTimeEntryDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddTimeEntryDialog(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'low':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'study':
        return Icons.school;
      case 'family':
        return Icons.family_restroom;
      case 'quotidian':
        return Icons.home;
      case 'idle':
        return Icons.weekend;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.orange;
      case 'study':
        return Colors.green;
      case 'family':
        return Colors.pink;
      case 'quotidian':
        return Colors.purple;
      case 'idle':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
