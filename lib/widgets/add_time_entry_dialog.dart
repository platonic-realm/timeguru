import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/time_entry.dart';
import '../services/config_service.dart';
import '../utils/icon_utils.dart';

class AddTimeEntryDialog extends StatefulWidget {
  final TimeEntry? timeEntry;
  final bool isEditing;

  const AddTimeEntryDialog({
    super.key,
    this.timeEntry,
    this.isEditing = false,
  });

  @override
  State<AddTimeEntryDialog> createState() => _AddTimeEntryDialogState();
}

class _AddTimeEntryDialogState extends State<AddTimeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _typeController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.timeEntry != null) {
      _descriptionController = TextEditingController(text: widget.timeEntry!.description);
      _typeController = TextEditingController(text: widget.timeEntry!.type);
      _selectedDate = widget.timeEntry!.date;
      _startTime = TimeOfDay.fromDateTime(widget.timeEntry!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.timeEntry!.endTime);
      _selectedCategoryId = widget.timeEntry!.category;
    } else {
      _descriptionController = TextEditingController();
      _typeController = TextEditingController();
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.now().replacing(hour: _startTime.hour + 1);
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, configService, child) {
        final categories = configService.getActiveCategories();
        
        return AlertDialog(
          title: Text(widget.isEditing ? 'Edit Time Entry' : 'Add Time Entry'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Selection
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _parseColor(category.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              IconUtils.getIconData(category.icon),
                              color: _parseColor(category.color),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
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
                      border: OutlineInputBorder(),
                      hintText: 'What did you do?',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Selection
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Selection
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Time'),
                          subtitle: Text(_startTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectStartTime(context),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Time'),
                          subtitle: Text(_endTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectEndTime(context),
                        ),
                      ),
                    ],
                  ),
                  
                  // Duration Display
                  if (_startTime != _endTime)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${_calculateDuration()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
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
              onPressed: _saveTimeEntry,
              child: Text(widget.isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
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

  String _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes <= 0) return '0 minutes';
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Ensure end time is after start time
        if (_endTime.hour * 60 + _endTime.minute <= _startTime.hour * 60 + _startTime.minute) {
          _endTime = _startTime.replacing(hour: _startTime.hour + 1);
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _saveTimeEntry() {
    if (_formKey.currentState!.validate()) {
      // Create DateTime objects for start and end times
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      DateTime endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // If end time is before start time, it's on the next day
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
      
      final duration = endDateTime.difference(startDateTime);
      
      final timeEntry = TimeEntry(
        id: widget.timeEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _typeController.text.trim().isNotEmpty ? _typeController.text.trim() : 'General',
        description: _descriptionController.text.trim(),
        category: _selectedCategoryId!,
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        duration: duration,
      );
      
      Navigator.of(context).pop(timeEntry);
    }
  }
}
