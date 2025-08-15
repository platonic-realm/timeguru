import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';

class AddTimeEntryDialog extends StatefulWidget {
  final TimeEntry? entry;

  const AddTimeEntryDialog({super.key, this.entry});

  @override
  State<AddTimeEntryDialog> createState() => _AddTimeEntryDialogState();
}

class _AddTimeEntryDialogState extends State<AddTimeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endTime = DateTime.now();
  String _selectedCategory = 'Idle';
  
  final List<String> _categories = [
    'Idle',
    'Study',
    'Work',
    'Quotidian',
    'Family',
    'Unknown',
  ];

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entry != null;
    if (_isEditing) {
      final entry = widget.entry!;
      _typeController.text = entry.type;
      _descriptionController.text = entry.description;
      _selectedCategory = entry.category;
      _startTime = entry.startTime;
      _endTime = entry.endTime;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Time Entry' : 'Add Time Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type field
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Activity Type',
                  hintText: 'e.g., PhD, Sleep, Shopping',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an activity type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the activity',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Time selection
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      'Start Time',
                      _startTime,
                      (time) => setState(() => _startTime = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      'End Time',
                      _endTime,
                      (time) => setState(() => _endTime = time),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Duration display
              _buildDurationDisplay(),
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
          onPressed: _submitForm,
          child: Text(_isEditing ? 'Update Entry' : 'Add Entry'),
        ),
      ],
    );
  }

  Widget _buildTimeField(
    String label,
    DateTime time,
    ValueChanged<DateTime> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context, time, onChanged),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDisplay() {
    final duration = _endTime.difference(_startTime);
    final isValid = duration.isNegative == false;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.schedule : Icons.error,
            color: isValid 
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            isValid 
                ? 'Duration: ${_formatDuration(duration)}'
                : 'Invalid time range',
            style: TextStyle(
              color: isValid 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    DateTime initialTime,
    ValueChanged<DateTime> onChanged,
  ) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );
    
    if (time != null) {
      final newDateTime = DateTime(
        initialTime.year,
        initialTime.month,
        initialTime.day,
        time.hour,
        time.minute,
      );
      onChanged(newDateTime);
    }
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    
    final duration = _endTime.difference(_startTime);
    if (duration.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final provider = context.read<AppProvider>();
    
    if (_isEditing) {
      // Update existing entry
      final updatedEntry = widget.entry!.copyWith(
        type: _typeController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        duration: duration,
      );
      provider.updateTimeEntry(updatedEntry);
    } else {
      // Create new entry
      provider.addTimeEntry(
        type: _typeController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );
    }
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Time entry updated successfully' : 'Time entry added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
