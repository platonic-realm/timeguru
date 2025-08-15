import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedPriority = 'all';
  String _selectedProject = 'all';
  String _sortBy = 'dueDate';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = provider.tasks;
          
          if (tasks.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildTasksList(context, provider, tasks);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start organizing your work by creating your first task',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create First Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, AppProvider provider, List<Task> tasks) {
    // Apply filtering and sorting
    final filteredTasks = _filterTasks(tasks);
    final sortedTasks = _sortTasks(filteredTasks);
    
    final pendingTasks = sortedTasks.where((t) => t.status == TaskStatus.pending).toList();
    final inProgressTasks = sortedTasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks = sortedTasks.where((t) => t.status == TaskStatus.completed).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: TabBar(
              tabs: [
                Tab(
                  text: 'Pending (${pendingTasks.length})',
                  icon: const Icon(Icons.schedule),
                ),
                Tab(
                  text: 'In Progress (${inProgressTasks.length})',
                  icon: const Icon(Icons.play_circle),
                ),
                Tab(
                  text: 'Completed (${completedTasks.length})',
                  icon: const Icon(Icons.check_circle),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskSection(context, provider, pendingTasks, 'pending'),
                _buildTaskSection(context, provider, inProgressTasks, 'inProgress'),
                _buildTaskSection(context, provider, completedTasks, 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(BuildContext context, AppProvider provider, List<Task> tasks, String section) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSectionIcon(section),
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _getSectionEmptyText(section),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            onEdit: () => _showEditTaskDialog(context, task),
            onDelete: () => _showDeleteConfirmation(context, task),
            onStatusChange: (newStatus) => _updateTaskStatus(context, task, newStatus),
          ),
        );
      },
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'pending':
        return Icons.schedule;
      case 'inProgress':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.task;
    }
  }

  String _getSectionEmptyText(String section) {
    switch (section) {
      case 'pending':
        return 'No pending tasks';
      case 'inProgress':
        return 'No tasks in progress';
      case 'completed':
        return 'No completed tasks';
      default:
        return 'No tasks';
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(task: task),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
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
              context.read<AppProvider>().deleteTask(task.id);
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

  void _updateTaskStatus(BuildContext context, Task task, TaskStatus newStatus) {
    final updatedTask = task.copyWith(status: newStatus);
    if (newStatus == TaskStatus.completed) {
      updatedTask.copyWith(completedAt: DateTime.now());
    }
    context.read<AppProvider>().updateTask(updatedTask);
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      bool matchesPriority = _selectedPriority == 'all' || 
          task.priority.name.toLowerCase() == _selectedPriority;
      bool matchesProject = _selectedProject == 'all' || 
          (task.project != null && task.project == _selectedProject);
      return matchesPriority && matchesProject;
    }).toList();
  }

  List<Task> _sortTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    
    switch (_sortBy) {
      case 'dueDate':
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return _sortAscending ? 1 : -1;
          if (b.dueDate == null) return _sortAscending ? -1 : 1;
          return _sortAscending 
              ? a.dueDate!.compareTo(b.dueDate!)
              : b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case 'priority':
        sortedTasks.sort((a, b) {
          final priorityOrder = {
            TaskPriority.high: 3,
            TaskPriority.medium: 2,
            TaskPriority.low: 1,
          };
          final aPriority = priorityOrder[a.priority] ?? 0;
          final bPriority = priorityOrder[b.priority] ?? 0;
          return _sortAscending 
              ? aPriority.compareTo(bPriority)
              : bPriority.compareTo(aPriority);
        });
        break;
      case 'title':
        sortedTasks.sort((a, b) {
          return _sortAscending 
              ? a.title.compareTo(b.title)
              : b.title.compareTo(a.title);
        });
        break;
      case 'createdAt':
        sortedTasks.sort((a, b) {
          return _sortAscending 
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    
    return sortedTasks;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Tasks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Priority filter
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                    const DropdownMenuItem(value: 'high', child: Text('High')),
                    const DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    const DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPriority = value ?? 'all';
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Project filter
                DropdownButtonFormField<String>(
                  value: _selectedProject,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Projects')),
                    ...context.read<AppProvider>().tasks
                        .where((t) => t.project != null)
                        .map((t) => t.project!)
                        .toSet()
                        .map((project) => DropdownMenuItem(
                              value: project,
                              child: Text(project),
                            )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedProject = value ?? 'all';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedPriority = 'all';
                    _selectedProject = 'all';
                  });
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Sort Tasks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sort by field
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'dueDate', child: Text('Due Date')),
                    const DropdownMenuItem(value: 'priority', child: Text('Priority')),
                    const DropdownMenuItem(value: 'title', child: Text('Title')),
                    const DropdownMenuItem(value: 'createdAt', child: Text('Created Date')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value ?? 'dueDate';
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Sort order
                Row(
                  children: [
                    const Text('Sort Order: '),
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Ascending')),
                          ButtonSegment(value: false, label: Text('Descending')),
                        ],
                        selected: {_sortAscending},
                        onSelectionChanged: (Set<bool> selection) {
                          setDialogState(() {
                            _sortAscending = selection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _sortBy = 'dueDate';
                    _sortAscending = true;
                  });
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
