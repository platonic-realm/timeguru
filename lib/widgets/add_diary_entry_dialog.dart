import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/monthly_file.dart';

class AddDiaryEntryDialog extends StatefulWidget {
  final DailyEntry? entry;
  final bool isEditing;
  final DateTime? selectedDate;

  const AddDiaryEntryDialog({
    super.key,
    this.entry,
    this.isEditing = false,
    this.selectedDate,
  });

  @override
  State<AddDiaryEntryDialog> createState() => _AddDiaryEntryDialogState();
}

class _AddDiaryEntryDialogState extends State<AddDiaryEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    
    if (widget.isEditing && widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _tagsController.text = widget.entry!.tags.join(', ');
      _selectedDate = widget.entry!.date;
    }
  }

  @override
  void dispose() {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.isEditing ? 'Edit Diary Entry' : 'Add New Diary Entry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Date picker
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Content *',
                                style: Theme.of(context).textTheme.titleMedium,
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
                              const SizedBox(width: 8),
                              Text(
                                'Preview',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          if (!_showPreview)
                            Expanded(
                              child: TextFormField(
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  hintText: 'Write about your day...\n\nYou can use Markdown formatting:\n**Morning**: Started with...\n**Afternoon**: Worked on...\n**Evening**: Relaxed with...',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: null,
                                expands: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter some content';
                                  }
                                  return null;
                                },
                              ),
                            )
                          else
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                    
                    const SizedBox(height: 20),
                    
                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Enter tags separated by commas (e.g., work, study, family)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
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
                          onPressed: _saveEntry,
                          child: Text(widget.isEditing ? 'Update' : 'Add Entry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      
      final entry = DailyEntry(
        date: _selectedDate,
        content: _contentController.text.trim(),
        tags: tags,
      );
      
      Navigator.of(context).pop(entry);
    }
  }
}
