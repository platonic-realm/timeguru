import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
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
                _buildPriorityIndicator(task.priority),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'complete':
                        onStatusChange(TaskStatus.completed);
                        break;
                      case 'in_progress':
                        onStatusChange(TaskStatus.inProgress);
                        break;
                      case 'pending':
                        onStatusChange(TaskStatus.pending);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (task.status != TaskStatus.completed) ...[
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text('Mark Complete'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            Icon(Icons.play_circle),
                            SizedBox(width: 8),
                            Text('Mark In Progress'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pending',
                        child: Row(
                          children: [
                            Icon(Icons.schedule),
                            SizedBox(width: 8),
                            Text('Mark Pending'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                    ],
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
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Task metadata
            Row(
              children: [
                if (task.project != null) ...[
                  _buildMetadataChip(
                    context,
                    Icons.folder,
                    task.project!,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildMetadataChip(
                  context,
                  Icons.flag,
                  task.priority.name.toUpperCase(),
                  _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 8),
                _buildMetadataChip(
                  context,
                  Icons.info,
                  task.status.name.replaceAll('InProgress', 'In Progress'),
                  _getStatusColor(task.status),
                ),
                const Spacer(),
                if (task.dueDate != null)
                  _buildDueDateChip(context, task.dueDate!),
              ],
            ),
            
            // Tags
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: task.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Creation date
            const SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('MMM d, y').format(task.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(TaskPriority priority) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now) && task.status != TaskStatus.completed;
    final isToday = dueDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
    
    Color chipColor;
    String dateText;
    
    if (isOverdue) {
      chipColor = Theme.of(context).colorScheme.error;
      dateText = 'Overdue';
    } else if (isToday) {
      chipColor = Theme.of(context).colorScheme.primary;
      dateText = 'Today';
    } else {
      chipColor = Theme.of(context).colorScheme.secondary;
      dateText = DateFormat('MMM d').format(dueDate);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            dateText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }
}
