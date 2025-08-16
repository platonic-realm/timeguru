import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config_service.dart';
import '../utils/icon_utils.dart';

class EditGoalDialog extends StatefulWidget {
  final Goal? goal;
  final bool isEditing;

  const EditGoalDialog({
    super.key,
    this.goal,
    this.isEditing = false,
  });

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _colorController;
  late TextEditingController _iconController;
  late DateTime _selectedDate;
  String _selectedIcon = 'flag';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController = TextEditingController(text: widget.goal!.title);
      _descriptionController = TextEditingController(text: widget.goal!.description);
      _tagsController = TextEditingController(text: widget.goal!.tags.join(', '));
      _colorController = TextEditingController(text: widget.goal!.color);
      _iconController = TextEditingController(text: widget.goal!.icon);
      _selectedDate = widget.goal!.deadline;
      _selectedIcon = widget.goal!.icon;
      _selectedColor = _parseColor(widget.goal!.color);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _tagsController = TextEditingController();
      _colorController = TextEditingController(text: '#2196F3');
      _iconController = TextEditingController(text: 'flag');
      _selectedDate = DateTime.now().add(const Duration(days: 30));
      _selectedColor = Colors.blue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('FF${colorString.substring(1)}', radix: 16));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Goal' : 'Add Goal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
              
              // Deadline Selection
              ListTile(
                title: const Text('Deadline'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'work, personal, urgent',
                ),
              ),
              const SizedBox(height: 16),
              
              // Icon Selection
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: const InputDecoration(
                  labelText: 'Icon',
                  border: OutlineInputBorder(),
                ),
                items: IconUtils.getAvailableIcons().map((icon) {
                  return DropdownMenuItem(
                    value: icon,
                    child: Row(
                      children: [
                        Icon(IconUtils.getIconData(icon)),
                        const SizedBox(width: 8),
                        Text(IconUtils.getIconDisplayName(icon)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedIcon = value;
                      _iconController.text = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Color Selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color (Hex)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^#[0-9A-Fa-f]{6}$')),
                      ],
                      validator: (value) {
                        if (value == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                          return 'Please enter a valid hex color (e.g., #2196F3)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                          setState(() {
                            _selectedColor = _parseColor(value);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showColorPicker(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(
                        Icons.color_lens,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
          onPressed: _saveGoal,
          child: Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _colorController.text = _colorToHex(color);
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      
      final goal = Goal(
        id: widget.goal?.id ?? _titleController.text.trim().toLowerCase().replaceAll(' ', '_'),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDate,
        tags: tags,
        color: _colorController.text.trim(),
        icon: _selectedIcon,
        isCompleted: widget.goal?.isCompleted ?? false,
      );
      
      Navigator.of(context).pop(goal);
    }
  }
}

// Simple Color Picker Widget (reused from EditCategoryDialog)
class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color == pickerColor;
        
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      },
    );
  }
}
