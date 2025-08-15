import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
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
                _buildTypeIcon(entry.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y').format(entry.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                      case 'view':
                        _showFullEntry(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Full'),
                        ],
                      ),
                    ),
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
            
            // Content preview
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: MarkdownBody(
                data: entry.content,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                  h1: Theme.of(context).textTheme.headlineSmall,
                  h2: Theme.of(context).textTheme.titleMedium,
                  h3: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Tags and metadata
            Row(
              children: [
                if (entry.tags.isNotEmpty) ...[
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: entry.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 10,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Created: ${DateFormat('MMM d').format(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(DiaryEntryType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case DiaryEntryType.daily:
        iconData = Icons.today;
        iconColor = Colors.blue;
        break;
      case DiaryEntryType.monthly:
        iconData = Icons.calendar_month;
        iconColor = Colors.green;
        break;
      case DiaryEntryType.memo:
        iconData = Icons.note;
        iconColor = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  void _showFullEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${DateFormat('EEEE, MMMM d, y').format(entry.date)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Type: ${entry.type.name.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (entry.tags.isNotEmpty)
                        Text(
                          'Tags: ${entry.tags.join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      Text(
                        'Created: ${DateFormat('MMM d, y HH:mm').format(entry.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (entry.updatedAt != null)
                        Text(
                          'Updated: ${DateFormat('MMM d, y HH:mm').format(entry.updatedAt!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Content
                MarkdownBody(
                  data: entry.content,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyMedium,
                    h1: Theme.of(context).textTheme.headlineMedium,
                    h2: Theme.of(context).textTheme.headlineSmall,
                    h3: Theme.of(context).textTheme.titleLarge,
                    h4: Theme.of(context).textTheme.titleMedium,
                    h5: Theme.of(context).textTheme.titleSmall,
                    h6: Theme.of(context).textTheme.titleSmall,
                    blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
