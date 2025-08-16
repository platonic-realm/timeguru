import 'package:flutter/material.dart';
import '../models/monthly_file.dart';

class AddMonthlyTaskDialog extends StatefulWidget {
  final MonthlyTask? task;
  final bool isEditing;

  const AddMonthlyTaskDialog({
    super.key,
    this.task,
    this.isEditing = false,
  });

  @override
  State<AddMonthlyTaskDialog> createState() => _AddMonthlyTaskDialogState();
}

class _AddMonthlyTaskDialogState extends State<AddMonthlyTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectController = TextEditingController();
  String _selectedPriority = 'medium';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _projectController.text = widget.task!.project ?? '';
      _selectedPriority = widget.task!.priority;
      _isCompleted = widget.task!.isCompleted;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Task' : 'Add New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Project
              TextFormField(
                controller: _projectController,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  hintText: 'Enter project name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Priority
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'medium';
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Completed checkbox
              if (widget.isEditing)
                CheckboxListTile(
                  title: const Text('Mark as completed'),
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = MonthlyTask(
        id: widget.isEditing ? widget.task!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isCompleted: _isCompleted,
        completedAt: _isCompleted ? DateTime.now() : null,
        project: _projectController.text.trim().isEmpty ? null : _projectController.text.trim(),
        priority: _selectedPriority,
      );
      
      Navigator.of(context).pop(task);
    }
  }
}
