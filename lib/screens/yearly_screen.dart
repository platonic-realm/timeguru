import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';
import '../utils/responsive_utils.dart';

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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            monthName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(totalHours),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${monthTimeEntries.length} entries',
            style: Theme.of(context).textTheme.bodySmall,
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
}
