import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/monthly_file.dart';
import '../models/time_entry.dart';
import '../widgets/add_monthly_task_dialog.dart';
import '../widgets/add_diary_entry_dialog.dart';
import '../widgets/add_time_entry_dialog.dart';
import '../utils/responsive_utils.dart';

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  late final PageController _summaryController;
  int _summaryPage = 0;
  
  @override
  void initState() {
    super.initState();
    _summaryController = PageController();
    // Initialize the provider when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ResponsiveUtils.init(context);
        context.read<AppProvider>().initialize();
      }
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < 3) {
      _summaryController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _summaryPage = page;
      });
    }
  }

  Future<void> _showDatePicker(BuildContext context, AppProvider provider) async {
    final initialDate = provider.selectedDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      await provider.updateSelectedDate(selectedDate);
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Add error boundary
        try {
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
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final monthlyFile = provider.currentMonthlyFile;
        if (monthlyFile == null) {
          return const Center(child: Text('No monthly data available'));
        }

        return Scaffold(
          appBar: AppBar(
              centerTitle: true,
              title: GestureDetector(
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
                        '${_getMonthName(monthlyFile.month)} ${monthlyFile.year}',
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
              ),
              actions: [
                // Today button
                IconButton(
                  onPressed: () => provider.goToToday(),
                  icon: Icon(
                    Icons.today,
                    size: ResponsiveUtils.getResponsiveIconSize(24),
                  ),
                  tooltip: 'Go to Today',
              ),
            ],
          ),
          body: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Top summaries (swipe between Overview, Time Summary, Graphs)
                  _buildTopSummaries(provider, monthlyFile.overview),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(24)),
                
                // Tasks Section
                _buildTasksSection(monthlyFile.tasks, provider),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(24)),
                
                // Daily Entries Section
                _buildDailyEntriesSection(monthlyFile.dailyEntries, provider),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(24)),
                  
                  // Time Entries Section
                  _buildTimeEntriesSection(provider),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context, provider),
              icon: Icon(Icons.add),
              label: Text('Add Entry'),
            ),
          );
        } catch (e) {
          // Error boundary - show error UI if something goes wrong
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
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
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try refreshing the app',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildOverviewCard(MonthlyOverview overview) {
    // Enhanced overview card for the swipeable summary
    return Card(
      elevation: ResponsiveUtils.getResponsiveElevation(3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(16)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(16)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(8)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(12)),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.primary,
                        size: ResponsiveUtils.getResponsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Overview',
                            style: ResponsiveUtils.getResponsiveTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                            style: ResponsiveUtils.getResponsiveTextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(20)),
                
                // Progress bar for task completion
                if (overview.totalTasks > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Progress',
                              style: ResponsiveUtils.getResponsiveTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(4)),
                            LinearProgressIndicator(
                              value: overview.totalTasks > 0 
                                  ? overview.completedTasks / overview.totalTasks 
                                  : 0.0,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: ResponsiveUtils.getResponsiveSpacing(8),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getResponsiveSpacing(16)),
                      Text(
                        '${((overview.completedTasks / overview.totalTasks) * 100).toStringAsFixed(0)}%',
                        style: ResponsiveUtils.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(20)),
                ],
                
                // Enhanced stat grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveUtils.getResponsiveGridColumns(),
                  crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(4),
                  mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(4),
                  childAspectRatio: 2.5, // Make items rectangular (wider than tall)
                  children: [
                      _buildEnhancedStatCard('Days', overview.totalDays.toString(), Icons.calendar_today, 'Active'),
                      _buildEnhancedStatCard('Tasks', '${overview.completedTasks}/${overview.totalTasks}', Icons.check_circle, 'Completed'),
                      _buildEnhancedStatCard('Study', _formatDuration(overview.studyHours), Icons.school, 'Hours'),
                      _buildEnhancedStatCard('Work', _formatDuration(overview.workHours), Icons.work, 'Hours'),
                      _buildEnhancedStatCard('Family', _formatDuration(overview.familyHours), Icons.family_restroom, 'Hours'),
                      _buildEnhancedStatCard('Quot.', _formatDuration(overview.quotidianHours), Icons.home, 'Hours'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(String label, String value, IconData icon, String subtitle) {
    // Initialize ResponsiveUtils
    ResponsiveUtils.init(context);
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(10)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(16)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: ResponsiveUtils.getResponsiveSpacing(8),
            offset: Offset(0, ResponsiveUtils.getResponsiveSpacing(2)),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Always use horizontal layout for overview items to save vertical space
          return _buildHorizontalStatLayout(label, value, icon, subtitle);
        },
      ),
    );
  }

  Widget _buildVerticalStatLayout(String label, String value, IconData icon, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(4.0), // Further reduced padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Make it more compact
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(4)), // Further reduced padding
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(6)), // Reduced radius
            ),
            child: Icon(
              icon, 
              size: ResponsiveUtils.getResponsiveIconSize(14), // Further reduced icon size
              color: Theme.of(context).colorScheme.primary
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(2)), // Minimal spacing
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(11), // Further reduced font size
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Handle text overflow
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(1)), // Minimal spacing
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(9), // Further reduced font size
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Handle text overflow
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(1)), // Minimal spacing
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(7), // Further reduced font size
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // Handle text overflow
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalStatLayout(String label, String value, IconData icon, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(6)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(8)),
          ),
          child: Icon(
            icon, 
            size: ResponsiveUtils.getResponsiveIconSize(16), 
            color: Theme.of(context).colorScheme.primary
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(8)),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(13),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(1)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(11),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.left,
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(1)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(9),
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Swipeable top summaries: overview, time summary, graphs placeholder
  Widget _buildTopSummaries(AppProvider provider, MonthlyOverview overview) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate dynamic height based on content and available space
            final availableWidth = constraints.maxWidth;
            
            // Calculate height based on content type and screen size
            double dynamicHeight;
            
            // Always use the overview page height as the fixed container height
            // This ensures consistent layout across all page swaps
            final crossAxisCount = ResponsiveUtils.getResponsiveGridColumns();
            final totalItems = 6; // Days, Tasks, Study, Work, Family, Quot.
            final rowsNeeded = (totalItems / crossAxisCount).ceil();
            
            // Calculate item dimensions
            final itemWidth = (availableWidth - (crossAxisCount - 1) * ResponsiveUtils.getResponsiveSpacing(4)) / crossAxisCount;
            
            // Calculate total height step by step for overview page:
            double totalHeight = 0;
            
            // 1. Card padding (top and bottom)
            totalHeight += ResponsiveUtils.getResponsiveSpacing(20) * 2; // 20 top + 20 bottom
            
            // 2. Header section
            totalHeight += ResponsiveUtils.getResponsiveSpacing(8) * 2; // Icon container padding
            totalHeight += ResponsiveUtils.getResponsiveIconSize(24); // Icon size
            totalHeight += ResponsiveUtils.getResponsiveSpacing(20); // Spacing after header
            
            // 3. Progress bar section (only if tasks exist)
            if (overview.totalTasks > 0) {
              totalHeight += ResponsiveUtils.getResponsiveSpacing(14); // Task Progress text
              totalHeight += ResponsiveUtils.getResponsiveSpacing(4); // Spacing before progress bar
              totalHeight += ResponsiveUtils.getResponsiveSpacing(8); // Progress bar height
              totalHeight += ResponsiveUtils.getResponsiveSpacing(20); // Spacing after progress bar
            }
            
            // 4. Grid section - calculate actual grid height
            final childAspectRatio = 2.5; // Rectangular items (wider than tall)
            final gridItemHeight = itemWidth / childAspectRatio;
            totalHeight += rowsNeeded * gridItemHeight; // Grid rows height
            totalHeight += (rowsNeeded - 1) * ResponsiveUtils.getResponsiveSpacing(4); // Row spacing between rows
            
            // 5. Safety margin
            totalHeight += ResponsiveUtils.getResponsiveSpacing(10);
            
            // Use this fixed height for all pages
            dynamicHeight = totalHeight;
            
            return SizedBox(
              height: dynamicHeight,
              child: PageView(
                controller: _summaryController,
                onPageChanged: (index) {
                  if (_summaryPage != index) {
                    setState(() => _summaryPage = index);
                  }
                },
                physics: const BouncingScrollPhysics(),
                allowImplicitScrolling: false,
                children: [
                  _buildOverviewCard(overview),
                  _buildTimeSummaryCard(provider),
                  _buildGraphsPlaceholderCard(),
                ],
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(8)),
        // Debug navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _goToPage(0),
              icon: Icon(
                Icons.analytics, 
                size: ResponsiveUtils.getResponsiveIconSize(16)
              ),
              tooltip: 'Overview',
            ),
            IconButton(
              onPressed: () => _goToPage(1),
              icon: Icon(
                Icons.timelapse, 
                size: ResponsiveUtils.getResponsiveIconSize(16)
              ),
              tooltip: 'Time Summary',
            ),
            IconButton(
              onPressed: () => _goToPage(2),
              icon: Icon(
                Icons.insights, 
                size: ResponsiveUtils.getResponsiveIconSize(16)
              ),
              tooltip: 'Graphs',
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swipe_left,
              size: ResponsiveUtils.getResponsiveIconSize(16),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(8)),
            ...List.generate(3, (index) {
              final isActive = _summaryPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(4)),
                width: isActive ? ResponsiveUtils.getResponsiveSpacing(16) : ResponsiveUtils.getResponsiveSpacing(8),
                height: ResponsiveUtils.getResponsiveSpacing(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(4)),
                ),
              );
            }),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(8)),
            Icon(
              Icons.swipe_right,
              size: ResponsiveUtils.getResponsiveIconSize(16),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSummaryCard(AppProvider provider) {
    final monthEntries = provider.timeEntries.where((e) =>
        e.date.year == provider.currentYear && e.date.month == provider.currentMonth);

    final Map<String, Duration> totals = {
      'work': Duration.zero,
      'study': Duration.zero,
      'family': Duration.zero,
      'quotidian': Duration.zero,
      'idle': Duration.zero,
    };
    for (final e in monthEntries) {
      final key = e.category.toLowerCase();
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + e.duration;
      }
    }

    final totalMinutes = totals.values.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final totalHours = totalMinutes / 60;

    Color barColor(String key) {
      switch (key) {
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

    IconData getCategoryIcon(String key) {
      switch (key) {
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

    Widget bar(String label, Duration value) {
      final percent = totalMinutes == 0 ? 0.0 : value.inMinutes / totalMinutes;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: barColor(label).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getCategoryIcon(label),
                    size: 16,
                    color: barColor(label),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label[0].toUpperCase() + label.substring(1),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: barColor(label).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(percent * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: barColor(label),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 10,
                color: barColor(label),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timelapse,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_getMonthName(provider.currentMonth)} ${provider.currentYear}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Total time display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Time: ${totalHours.toStringAsFixed(1)} hours',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category bars
                bar('work', totals['work']!),
                bar('study', totals['study']!),
                bar('family', totals['family']!),
                bar('quotidian', totals['quotidian']!),
                bar('idle', totals['idle']!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphsPlaceholderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insights,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics & Insights',
                            style: ResponsiveUtils.getResponsiveTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Data visualization and trends',
                            style: ResponsiveUtils.getResponsiveTextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Placeholder content with better styling
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Advanced Analytics',
                        style: ResponsiveUtils.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coming soon: Interactive charts,\ntrends, and insights',
                        textAlign: TextAlign.center,
                        style: ResponsiveUtils.getResponsiveTextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection(List<MonthlyTask> tasks, AppProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tasks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),
            
            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first task to get started',
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
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskTile(task, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(MonthlyTask task, AppProvider provider) {
    final priorityColor = _getPriorityColor(task.priority);
    final priorityIcon = _getPriorityIcon(task.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted 
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
              : priorityColor.withValues(alpha: 0.3),
          width: task.isCompleted ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          decoration: BoxDecoration(
            color: task.isCompleted 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Checkbox(
        value: task.isCompleted,
        onChanged: (value) {
          if (value != null) {
            final updatedTask = MonthlyTask(
              id: task.id,
              title: task.title,
              description: task.description,
              isCompleted: value,
              completedAt: value ? DateTime.now() : null,
              project: task.project,
              priority: task.priority,
            );
            provider.updateTask(updatedTask);
          }
        },
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted 
              ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (!task.isCompleted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priorityIcon,
                      size: 14,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.priority.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (task.project != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.project!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.isCompleted && task.completedAt != null) ...[
                  if (task.project != null) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        onSelected: (action) {
          switch (action) {
            case 'edit':
              _showEditTaskDialog(context, provider, task);
              break;
            case 'delete':
              _showDeleteTaskConfirmation(context, provider, task);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntriesSection(AppProvider provider) {
    final monthEntries = provider.timeEntries.where((entry) {
      return entry.date.year == provider.currentYear && 
             entry.date.month == provider.currentMonth;
    }).toList();
    
    monthEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Time Entries',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),
            
            if (monthEntries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No time entries yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start tracking your time',
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
                itemCount: monthEntries.length,
                itemBuilder: (context, index) {
                  final entry = monthEntries[index];
                  return _buildTimeEntryTile(entry, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntryTile(TimeEntry entry, AppProvider provider) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(entry.category),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.timer,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(entry.type),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.description),
          Text(
            '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)} (${_formatDuration(entry.duration)})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          switch (action) {
            case 'edit':
              _showEditTimeEntryDialog(context, provider, entry);
              break;
            case 'delete':
              _showDeleteTimeEntryConfirmation(context, provider, entry);
              break;
          }
        },
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
                Icon(Icons.delete),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        child: const Icon(Icons.more_vert),
      ),
    );
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDailyEntriesSection(List<DailyEntry> entries, AppProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Entries',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddDiaryEntryDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (entries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No daily entries yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start writing about your day',
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
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildDailyEntryTile(entry, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyEntryTile(DailyEntry entry, AppProvider provider) {
    return ExpansionTile(
      title: Text(
        '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year} - ${_getDayOfWeek(entry.date.weekday)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: entry.tags.isNotEmpty 
          ? Text(entry.tags.map((tag) => '#$tag').join(' '))
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.content),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditDiaryEntryDialog(context, provider, entry),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteDiaryEntryConfirmation(context, provider, entry),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // DIALOG METHODS
  
  void _showAddDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Task'),
              subtitle: const Text('Add a new task'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddTaskDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Daily Entry'),
              subtitle: const Text('Write about your day'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddDiaryEntryDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Time Entry'),
              subtitle: const Text('Track time spent on activities'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddTimeEntryDialog(context, provider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
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

  void _showEditTaskDialog(BuildContext context, AppProvider provider, MonthlyTask task) {
    showDialog(
      context: context,
      builder: (context) => AddMonthlyTaskDialog(
        task: task,
        isEditing: true,
      ),
    ).then((updatedTask) {
      if (updatedTask != null) {
        provider.updateTask(updatedTask);
      }
    });
  }

  void _showDeleteTaskConfirmation(BuildContext context, AppProvider provider, MonthlyTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
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

  void _showAddDiaryEntryDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const AddDiaryEntryDialog(),
    ).then((entry) {
      if (entry != null) {
        provider.addDailyEntry(entry);
      }
    });
  }

  void _showEditDiaryEntryDialog(BuildContext context, AppProvider provider, DailyEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AddDiaryEntryDialog(
        entry: entry,
        isEditing: true,
      ),
    ).then((updatedEntry) {
      if (updatedEntry != null) {
        provider.updateDailyEntry(updatedEntry);
      }
    });
  }

  void _showDeleteDiaryEntryConfirmation(BuildContext context, AppProvider provider, DailyEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete the entry for ${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDailyEntry(entry.date);
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

  // TIME ENTRY DIALOG METHODS
  
  void _showAddTimeEntryDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeEntryDialog(),
    ).then((entry) {
      if (entry != null) {
        provider.addTimeEntry(entry);
      }
    });
  }

  void _showEditTimeEntryDialog(BuildContext context, AppProvider provider, TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AddTimeEntryDialog(
        timeEntry: entry,
        isEditing: true,
      ),
    ).then((updatedEntry) {
      if (updatedEntry != null) {
        provider.updateTimeEntry(updatedEntry);
      }
    });
  }

  void _showDeleteTimeEntryConfirmation(BuildContext context, AppProvider provider, TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Entry'),
        content: Text('Are you sure you want to delete "${entry.type}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTimeEntry(entry.id);
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

  // UTILITY METHODS
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.priority_high; // Default icon
    }
  }
}
