import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config_service.dart';
import '../utils/icon_utils.dart';

class EditCategoryDialog extends StatefulWidget {
  final TimeEntryCategory? category;
  final bool isEditing;

  const EditCategoryDialog({
    super.key,
    this.category,
    this.isEditing = false,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late TextEditingController _iconController;
  String _selectedIcon = 'work';
  Color _selectedColor = Colors.red;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController = TextEditingController(text: widget.category!.name);
      _colorController = TextEditingController(text: widget.category!.color);
      _iconController = TextEditingController(text: widget.category!.icon);
      _selectedIcon = widget.category!.icon;
      _selectedColor = _parseColor(widget.category!.color);
    } else {
      _nameController = TextEditingController();
      _colorController = TextEditingController(text: '#FF6B6B');
      _iconController = TextEditingController(text: 'work');
      _selectedColor = Colors.red;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('FF${colorString.substring(1)}', radix: 16));
      }
      return Colors.red;
    } catch (e) {
      return Colors.red;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
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
                          return 'Please enter a valid hex color (e.g., #FF6B6B)';
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
          onPressed: _saveCategory,
          child: Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
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

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = TimeEntryCategory(
        id: widget.category?.id ?? _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
        name: _nameController.text.trim(),
        color: _colorController.text.trim(),
        icon: _selectedIcon,
        isDefault: false,
      );
      
      Navigator.of(context).pop(category);
    }
  }
}

// Simple Color Picker Widget
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
