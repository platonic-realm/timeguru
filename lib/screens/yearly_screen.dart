import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';
import '../utils/responsive_utils.dart';
import '../services/config_service.dart';
import '../widgets/edit_category_dialog.dart';
import '../widgets/edit_goal_dialog.dart';

class YearlyScreen extends StatefulWidget {
  final int? initialYear;

  const YearlyScreen({super.key, this.initialYear});

  @override
  State<YearlyScreen> createState() => _YearlyScreenState();
}

class _YearlyScreenState extends State<YearlyScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive utilities
    ResponsiveUtils.init(context);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return GestureDetector(
              onTap: () => _showYearPicker(context, provider),
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
                      'Year ${provider.selectedDate.year}',
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
            onPressed: () => _goToCurrentYear(),
            tooltip: 'Go to Current Year',
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
              // Yearly content
              Expanded(
                child: _buildYearlyContent(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddCategoryDialog(context, Provider.of<ConfigService>(context, listen: false), provider.selectedDate.year),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          );
        },
      ),
    );
  }

  Widget _buildYearlyContent(AppProvider provider) {
    final yearTimeEntries = provider.timeEntries
        .where((entry) => entry.date.year == provider.selectedDate.year)
        .toList();

    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yearly overview card
          _buildYearlyOverviewCard(yearTimeEntries, provider),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Categories Section
          _buildCategoriesSection(provider),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Goals Section
          _buildGoalsSection(provider),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Monthly breakdown
          _buildMonthlyBreakdownCard(provider),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Category analysis
          _buildCategoryAnalysisCard(yearTimeEntries),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(16)),
          
          // Time trends
          _buildTimeTrendsCard(yearTimeEntries),
        ],
      ),
    );
  }

  Widget _buildYearlyOverviewCard(List<TimeEntry> yearTimeEntries, AppProvider provider) {
    final totalHours = yearTimeEntries.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );

    final totalDays = yearTimeEntries.map((e) => e.date.day).toSet().length;
    final totalCategories = yearTimeEntries.map((e) => e.category).toSet().length;
    final totalProjects = yearTimeEntries.map((e) => e.type).toSet().length;

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
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Year ${provider.selectedDate.year} Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    'Total Hours',
                    _formatDuration(totalHours),
                    Icons.timelapse,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Active Days',
                    '$totalDays',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Categories',
                    '$totalCategories',
                    Icons.category,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Projects',
                    '$totalProjects',
                    Icons.work,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(AppProvider provider) {
    return Consumer<ConfigService>(
      builder: (context, configService, child) {
        return FutureBuilder<List<TimeEntryCategory>>(
          future: _loadYearCategories(configService, provider.selectedDate.year),
          builder: (context, snapshot) {
            final yearCategories = snapshot.data ?? [];
            
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
                          Icons.category,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Categories for ${provider.selectedDate.year}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCategoryDialog(context, configService, provider.selectedDate.year),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (yearCategories.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No categories for this year yet. Add your first category to get started!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: yearCategories.length,
                        itemBuilder: (context, index) {
                          final category = yearCategories[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _parseColor(category.color).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(category.icon),
                                color: _parseColor(category.color),
                              ),
                            ),
                            title: Text(category.name),
                            subtitle: Text(category.isDefault ? 'Default Category' : 'Custom Category'),
                            trailing: category.isDefault
                                ? const Chip(label: Text('Default'))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editCategory(category, configService, provider.selectedDate.year),
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteCategory(category, configService, provider.selectedDate.year),
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Delete',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsSection(AppProvider provider) {
    return Consumer<ConfigService>(
      builder: (context, configService, child) {
        return FutureBuilder<List<Goal>>(
          future: _loadYearGoals(configService, provider.selectedDate.year),
          builder: (context, snapshot) {
            final yearGoals = snapshot.data ?? [];
            
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
                          Icons.flag,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Goals for ${provider.selectedDate.year}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddGoalDialog(context, configService, provider.selectedDate.year),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (yearGoals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No goals for this year yet. Add your first goal to get started!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: yearGoals.length,
                        itemBuilder: (context, index) {
                          final goal = yearGoals[index];
                          final daysUntilDeadline = goal.deadline.difference(DateTime.now()).inDays;
                          final isOverdue = daysUntilDeadline < 0;
                          final isDueSoon = daysUntilDeadline <= 7 && daysUntilDeadline >= 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _parseColor(goal.color).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(goal.icon),
                                  color: _parseColor(goal.color),
                                ),
                              ),
                              title: Text(
                                goal.title,
                                style: TextStyle(
                                  decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(goal.description),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: goal.tags.map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      labelStyle: Theme.of(context).textTheme.bodySmall,
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: isOverdue
                                            ? Colors.red
                                            : isDueSoon
                                                ? Colors.orange
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOverdue
                                            ? 'Overdue by ${daysUntilDeadline.abs()} days'
                                            : isDueSoon
                                                ? 'Due in $daysUntilDeadline days'
                                                : 'Due ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                                        style: TextStyle(
                                          color: isOverdue
                                              ? Colors.red
                                              : isDueSoon
                                                  ? Colors.orange
                                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: isOverdue || isDueSoon ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: goal.isCompleted,
                                    onChanged: (bool? value) {
                                      if (value != null) {
                                        final updatedGoal = goal.copyWith(isCompleted: value);
                                        configService.updateYearGoal(provider.selectedDate.year, updatedGoal);
                                      }
                                    },
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editGoal(goal, configService, provider.selectedDate.year);
                                      } else if (value == 'delete') {
                                        _deleteGoal(goal, configService, provider.selectedDate.year);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthlyBreakdownCard(AppProvider provider) {
    final availableMonths = provider.availableMonths;
    
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
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (availableMonths.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No data available for this year',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveUtils.isSmallScreen ? 2 : 3,
                  crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(8),
                  mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(8),
                  childAspectRatio: ResponsiveUtils.isSmallScreen ? 1.0 : 1.3,
                ),
                itemCount: availableMonths.length,
                itemBuilder: (context, index) {
                  final month = availableMonths[index];
                  return _buildMonthCard(month, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(int month, AppProvider provider) {
    final monthName = _getMonthName(month);
    final monthTimeEntries = provider.timeEntries
        .where((entry) => entry.date.year == provider.selectedDate.year && entry.date.month == month)
        .toList();
    
    final totalHours = monthTimeEntries.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );

    // Initialize ResponsiveUtils
    ResponsiveUtils.init(context);
    
    // Determine layout based on screen width
    final isSmallScreen = ResponsiveUtils.isSmallScreen;
    final isMobile = ResponsiveUtils.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout based on available height and screen width
          final availableHeight = constraints.maxHeight;
          final isSmallScreen = ResponsiveUtils.isSmallScreen;
          final isMobile = ResponsiveUtils.isMobile;
          final shouldUseHorizontal = (isSmallScreen || isMobile || ResponsiveUtils.screenWidth < 800 || availableHeight < 70);
          
          return (isSmallScreen || isMobile || ResponsiveUtils.screenWidth < 800)
              ? _buildVerticalLayout(monthName, totalHours, monthTimeEntries.length)
              : _buildHorizontalLayout(monthName, totalHours, monthTimeEntries.length);
        },
      ),
    );
  }

  Widget _buildVerticalLayout(String monthName, Duration totalHours, int entryCount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            monthName,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(totalHours),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$entryCount entries',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(String monthName, Duration totalHours, int entryCount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(12),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(totalHours),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(14),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article,
                  size: ResponsiveUtils.getResponsiveIconSize(16),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 2),
                Text(
                  '$entryCount',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(12),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'entries',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(10),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisCard(List<TimeEntry> yearTimeEntries) {
    final categoryTotals = <String, Duration>{};
    
    for (final entry in yearTimeEntries) {
      final category = entry.category.toLowerCase();
      categoryTotals[category] = (categoryTotals[category] ?? Duration.zero) + entry.duration;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (sortedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No category data available',
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
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  return ListTile(
                    leading: Icon(
                      _getCategoryIcon(category.key),
                      color: _getCategoryColor(category.key),
                    ),
                    title: Text(category.key[0].toUpperCase() + category.key.substring(1)),
                    trailing: Text(
                      _formatDuration(category.value),
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

  Widget _buildTimeTrendsCard(List<TimeEntry> yearTimeEntries) {
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
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              alignment: Alignment.center,
              child: Text(
                'Trends visualization\n(coming soon)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
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

  void _goToCurrentYear() {
    final currentYear = DateTime.now().year;
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateSelectedDate(DateTime(currentYear, DateTime.now().month, DateTime.now().day));
  }

  void _showYearPicker(BuildContext context, AppProvider provider) {
    showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
    ).then((pickedDate) {
      if (pickedDate != null) {
        provider.updateSelectedDate(pickedDate);
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
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

  void _showAddCategoryDialog(BuildContext context, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<TimeEntryCategory>(
      context: context,
      builder: (context) => const EditCategoryDialog(),
    ).then((category) async {
      if (category != null) {
        await configService.addYearCategory(year, category);
        if (mounted && scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" added to year $year')),
          );
        }
      }
    });
  }

  void _showAddGoalDialog(BuildContext context, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<Goal>(
      context: context,
      builder: (context) => const EditGoalDialog(),
    ).then((goal) async {
      if (goal != null) {
        await configService.addYearGoal(year, goal);
        if (mounted && scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text('Goal "${goal.title}" added to year $year')),
          );
        }
      }
    });
  }

  void _editCategory(TimeEntryCategory category, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<TimeEntryCategory>(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        isEditing: true,
      ),
    ).then((updatedCategory) async {
      if (updatedCategory != null) {
        await configService.updateYearCategory(year, updatedCategory);
        if (mounted && scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text('Category "${updatedCategory.name}" updated in year $year')),
          );
        }
      }
    });
  }

  void _editGoal(Goal goal, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<Goal>(
      context: context,
      builder: (context) => EditGoalDialog(
        goal: goal,
        isEditing: true,
      ),
    ).then((updatedGoal) async {
      if (updatedGoal != null) {
        await configService.updateYearGoal(year, updatedGoal);
        if (mounted && scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text('Goal "${updatedGoal.title}" updated in year $year')),
          );
        }
      }
    });
  }

  void _deleteCategory(TimeEntryCategory category, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}" from year $year? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await configService.removeYearCategory(year, category.id);
          if (mounted && scaffoldContext.mounted) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Category "${category.name}" deleted from year $year')),
            );
          }
        } catch (e) {
          if (mounted && scaffoldContext.mounted) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Error deleting category: $e')),
            );
          }
        }
      }
    });
  }

  void _deleteGoal(Goal goal, ConfigService configService, int year) {
    final scaffoldContext = context;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}" from year $year? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await configService.removeYearGoal(year, goal.id);
          if (mounted && scaffoldContext.mounted) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Goal "${goal.title}" deleted from year $year')),
            );
          }
        } catch (e) {
          if (mounted && scaffoldContext.mounted) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Error deleting goal: $e')),
            );
          }
        }
      }
    });
  }

  // Helper methods
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hexString = colorString.substring(1);
        if (hexString.length == 6) {
          return Color(int.parse('FF$hexString', radix: 16));
        }
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  // Helper methods to load year data
  Future<List<TimeEntryCategory>> _loadYearCategories(ConfigService configService, int year) async {
    try {
      // First try to load year data through the config service
      await configService.loadYearData(year);
      return configService.yearCategories;
    } catch (e) {
      debugPrint('Failed to load year categories: $e');
      return [];
    }
  }

  Future<List<Goal>> _loadYearGoals(ConfigService configService, int year) async {
    try {
      // First try to load year data through the config service
      await configService.loadYearData(year);
      return configService.yearGoals;
    } catch (e) {
      debugPrint('Failed to load year goals: $e');
      return [];
    }
  }
}
