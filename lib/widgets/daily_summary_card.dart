import 'package:flutter/material.dart';
import '../models/daily_summary.dart';

class DailySummaryCard extends StatelessWidget {
  final DailySummary summary;

  const DailySummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatDuration(summary.total),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category breakdown
            _buildCategoryRow(
              context,
              'Idle',
              summary.idle,
              Colors.blue,
              Icons.bedtime,
            ),
            _buildCategoryRow(
              context,
              'Study',
              summary.study,
              Colors.green,
              Icons.school,
            ),
            _buildCategoryRow(
              context,
              'Work',
              summary.work,
              Colors.orange,
              Icons.work,
            ),
            _buildCategoryRow(
              context,
              'Quotidian',
              summary.quotidian,
              Colors.purple,
              Icons.home,
            ),
            _buildCategoryRow(
              context,
              'Family',
              summary.family,
              Colors.pink,
              Icons.family_restroom,
            ),
            if (summary.unknown.inMinutes > 0)
              _buildCategoryRow(
                context,
                'Unknown',
                summary.unknown,
                Colors.grey,
                Icons.help_outline,
              ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String category,
    Duration duration,
    Color color,
    IconData icon,
  ) {
    if (duration.inMinutes == 0) return const SizedBox.shrink();
    
    final percentage = summary.total.inMinutes > 0 
        ? (duration.inMinutes / summary.total.inMinutes) * 100 
        : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final totalMinutes = summary.total.inMinutes;
    final targetMinutes = 24 * 60; // 24 hours in minutes
    final progress = totalMinutes / targetMinutes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${totalMinutes}h / 24h',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 
                ? Colors.green 
                : Theme.of(context).colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(8),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0 
              ? 'Daily goal achieved! 🎉'
              : '${(targetMinutes - totalMinutes).abs()}h remaining',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: progress >= 1.0 
                ? Colors.green 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: progress >= 1.0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
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
}
