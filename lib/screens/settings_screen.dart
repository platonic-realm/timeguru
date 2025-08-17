import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';
import '../widgets/edit_category_dialog.dart';
import '../widgets/edit_goal_dialog.dart';
import '../utils/icon_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ConfigService>(
        builder: (context, configService, child) {
          if (!configService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data Directory Section
                _buildDataDirectoryCard(configService),
                const SizedBox(height: 16),
                
                // Appearance Section
                _buildAppearanceCard(configService),
                const SizedBox(height: 16),
                
                // Categories Section
                _buildCategoriesCard(configService),
                const SizedBox(height: 16),
                
                // Goals Section
                _buildGoalsCard(configService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataDirectoryCard(ConfigService configService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Directory',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your data is stored in the selected directory. You can change this location at any time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      configService.dataDirectory ?? 'No directory selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _selectDataDirectory(configService),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(ConfigService configService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_getThemeModeName(configService.themeMode)),
              trailing: DropdownButton<ThemeMode>(
                value: configService.themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null && context.mounted) {
                    configService.setThemeMode(newValue);
                  }
                },
                items: ThemeMode.values.map((ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(_getThemeModeName(mode)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(ConfigService configService) {
    return Card(
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
                ),
                const SizedBox(width: 8),
                Text(
                  'Default Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _addCategory(configService),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These categories will be used as templates when creating new year files.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (configService.defaultCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No default categories set yet. Add your first default category to get started!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...configService.defaultCategories.map((category) => _buildCategoryTile(category, configService)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(TimeEntryCategory category, ConfigService configService) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _parseColor(category.color).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getIconData(category.icon),
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
                  onPressed: () => _editCategory(category, configService),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteCategory(category, configService),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
    );
  }

  Widget _buildGoalsCard(ConfigService configService) {
    return Card(
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
                ),
                const SizedBox(width: 8),
                Text(
                  'Default Goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _addGoal(configService),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These goals will be used as templates when creating new year files.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (configService.defaultGoals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No default goals set yet. Add your first default goal to get started!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...configService.defaultGoals.map((goal) => _buildGoalTile(goal, configService)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(Goal goal, ConfigService configService) {
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
            _getIconData(goal.icon),
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
                  configService.updateGoal(updatedGoal);
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
                  _editGoal(goal, configService);
                } else if (value == 'delete') {
                  _deleteGoal(goal, configService);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('FF${colorString.substring(1)}', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getIconData(String iconName) {
    return IconUtils.getIconData(iconName);
  }

  Future<void> _selectDataDirectory(ConfigService configService) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Data Directory',
      );
      
      if (result != null && mounted) {
        await configService.setDataDirectory(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data directory updated to: $result')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting directory: $e')),
        );
      }
    }
  }

  Future<void> _addCategory(ConfigService configService) async {
    final result = await showDialog<TimeEntryCategory>(
      context: context,
      builder: (context) => const EditCategoryDialog(),
    );
    
    if (result != null) {
      await configService.addCategory(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${result.name}" added')),
        );
      }
    }
  }

  Future<void> _editCategory(TimeEntryCategory category, ConfigService configService) async {
    final result = await showDialog<TimeEntryCategory>(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        isEditing: true,
      ),
    );
    
    if (result != null) {
      await configService.updateCategory(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${result.name}" updated')),
        );
      }
    }
  }

  Future<void> _deleteCategory(TimeEntryCategory category, ConfigService configService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
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
    );
    
    if (confirmed == true) {
      try {
        await configService.removeCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }

  Future<void> _addGoal(ConfigService configService) async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => const EditGoalDialog(),
    );
    
    if (result != null) {
      await configService.addGoal(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal "${result.title}" added')),
        );
      }
    }
  }

  Future<void> _editGoal(Goal goal, ConfigService configService) async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => EditGoalDialog(
        goal: goal,
        isEditing: true,
      ),
    );
    
    if (result != null) {
      await configService.updateGoal(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal "${result.title}" updated')),
        );
      }
    }
  }

  Future<void> _deleteGoal(Goal goal, ConfigService configService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"? This action cannot be undone.'),
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
    );
    
    if (confirmed == true) {
      await configService.removeGoal(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal "${goal.title}" deleted')),
        );
      }
    }
  }
}
