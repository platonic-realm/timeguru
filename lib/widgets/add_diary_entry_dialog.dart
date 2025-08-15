import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/diary_entry.dart';

class AddDiaryEntryDialog extends StatefulWidget {
  final DiaryEntry? entry;
  final DiaryEntryType? type;

  const AddDiaryEntryDialog({
    super.key,
    this.entry,
    this.type,
  });

  @override
  State<AddDiaryEntryDialog> createState() => _AddDiaryEntryDialogState();
}

class _AddDiaryEntryDialogState extends State<AddDiaryEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  DiaryEntryType _selectedType = DiaryEntryType.daily;
  bool _isEditing = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entry != null;
    _selectedType = widget.type ?? DiaryEntryType.daily;
    
    if (_isEditing) {
      final entry = widget.entry!;
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _tagsController.text = entry.tags.join(', ');
      _selectedDate = entry.date;
      _selectedType = entry.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isEditing ? 'Edit Entry' : 'New Entry',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter entry title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Type and Date row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DiaryEntryType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                              ),
                              items: DiaryEntryType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
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
                                      Icons.calendar_today,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, y').format(_selectedDate),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tags field
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'Enter tags separated by commas',
                          border: OutlineInputBorder(),
                          helperText: 'Example: work, personal, ideas',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Content field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content *',
                          hintText: _getContentHint(),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: null,
                        minLines: 10,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Markdown preview toggle
                      Row(
                        children: [
                          Icon(
                            Icons.preview,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Markdown Preview',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _showPreview,
                            onChanged: (value) {
                              setState(() {
                                _showPreview = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Markdown Preview
            if (_showPreview) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Markdown(
                          data: _contentController.text.isEmpty 
                              ? '*No content to preview*'
                              : _contentController.text,
                          styleSheet: MarkdownStyleSheet(
                            h1: Theme.of(context).textTheme.headlineMedium,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            p: Theme.of(context).textTheme.bodyMedium,
                            listBullet: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isEditing ? 'Update' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getContentHint() {
    switch (_selectedType) {
      case DiaryEntryType.daily:
        return 'Write about your day, thoughts, and experiences...\n\n# Today\'s Highlights\n- What went well?\n- What could be improved?\n- Tomorrow\'s goals';
      case DiaryEntryType.monthly:
        return 'Reflect on the past month...\n\n# Monthly Summary\n## Achievements\n## Challenges\n## Goals for next month';
      case DiaryEntryType.memo:
        return 'Write your notes, ideas, or thoughts...\n\n# Notes\n- Key points\n- Ideas to explore\n- Action items';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    
    final provider = context.read<AppProvider>();
    
    if (_isEditing) {
      // Update existing entry
      final updatedEntry = widget.entry!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
        tags: tags,
        updatedAt: DateTime.now(),
      );
      provider.updateDiaryEntry(updatedEntry);
    } else {
      // Create new entry
      provider.addDiaryEntry(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        tags: tags,
      );
    }
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Entry updated successfully' : 'Entry created successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
