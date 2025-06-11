import 'dart:io';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class IngredientController {
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;

  IngredientController()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        unit = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _recipeService = RecipeService();
  bool _isLoading = false;

  // Controllers for main fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();

  // State for dropdown/picker
  String _selectedDifficulty = 'Medium';
  String? _selectedCategoryId;
  List<RecordModel> _categories = [];

  // Lists for dynamic text controllers
  final List<IngredientController> _ingredientControllers = [
    IngredientController()
  ];
  final List<TextEditingController> _instructionControllers = [
    TextEditingController()
  ];

  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _recipeService.getMealCategories();
      if (mounted && categories.isNotEmpty) {
        setState(() {
          _categories = categories;
          _selectedCategoryId = categories.first.id;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileSize = await File(pickedFile.path).length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image size exceeds 5MB limit.')),
        );
        return;
      }
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionField(int index) {
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientControllers.add(IngredientController());
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitRecipe() async {
    // Manual validation
    if (_nameController.text.isEmpty) {
      _showValidationError('Recipe Name cannot be empty.');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      _showValidationError('Description cannot be empty.');
      return;
    }
    if (_prepTimeController.text.isEmpty ||
        int.tryParse(_prepTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')) == null) {
      _showValidationError('Prep Time must contain a valid number.');
      return;
    }
    if (_selectedCategoryId == null) {
      _showValidationError('Please select a category.');
      return;
    }
    final ingredients = _ingredientControllers
        .map((c) => IngredientInput(
              name: c.name.text,
              quantity: c.quantity.text,
              unit: c.unit.text,
            ))
        .where((i) => i.name.isNotEmpty)
        .toList();
    if (ingredients.isEmpty) {
      _showValidationError('At least one ingredient is required.');
      return;
    }
    final instructions = _instructionControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
    if (instructions.isEmpty) {
      _showValidationError('At least one instruction is required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await _recipeService.createRecipe(
        name: _nameController.text,
        description: _descriptionController.text,
        prepTime: _prepTimeController.text,
        difficulty: _selectedDifficulty,
        categoryIds: [_selectedCategoryId!],
        ingredients: ingredients,
        instructions: instructions,
        imageFile: _image,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving recipe: $e');
      if (mounted) {
        _showValidationError(
            'Failed to add recipe: ${e is ClientException ? e.response['message'] : e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add New Recipe'),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _submitRecipe,
                child: const Text('Save'),
              ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildSectionTitle('Recipe Details'),
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Recipe Name',
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Description',
              maxLines: 3,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _prepTimeController,
              placeholder: 'Prep Time (e.g., 30 min)',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            _buildPickerField(
              'Difficulty',
              _selectedDifficulty,
              ['EZ', 'Medium', 'Hard'],
              (newValue) {
                setState(() {
                  _selectedDifficulty = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            _categories.isEmpty
                ? const Center(child: CupertinoActivityIndicator())
                : _buildPickerField(
                    'Category',
                    _categories
                        .firstWhere(
                          (c) => c.id == _selectedCategoryId,
                          orElse: () => _categories.first,
                        )
                        .data['name'],
                    _categories.map((c) => c.data['name'].toString()).toList(),
                    (newValue) {
                      setState(() {
                        _selectedCategoryId = _categories
                            .firstWhere((c) => c.data['name'] == newValue)
                            .id;
                      });
                    },
                  ),
            const SizedBox(height: 24),
            _buildSectionTitle('Ingredients'),
            ..._buildIngredientFields(),
            const SizedBox(height: 24),
            _buildSectionTitle('Instructions'),
            ..._buildDynamicTextFields(
              _instructionControllers,
              'Step',
              _addInstructionField,
              _removeInstructionField,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPickerField(
      String title, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () {
        _showPicker(context, options, (index) {
          onChanged(options[index]);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
            Row(
              children: [
                Text(
                  currentValue,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(color: CupertinoColors.systemGrey),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> items, ValueChanged<int> onSelectedItemChanged) {
    final initialIndex = items.indexOf(
      _categories
          .firstWhere(
            (c) => c.id == _selectedCategoryId,
            orElse: () => _categories.first,
          )
          .data['name'],
    );
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoPicker(
          scrollController:
              FixedExtentScrollController(initialItem: initialIndex >= 0 ? initialIndex : 0),
          itemExtent: 32.0,
          onSelectedItemChanged: onSelectedItemChanged,
          children: items.map((item) => Center(child: Text(item))).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildIngredientFields() {
    List<Widget> fields = [];
    for (int i = 0; i < _ingredientControllers.length; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: CupertinoTextField(
                  controller: _ingredientControllers[i].name,
                  placeholder: 'Ingredient Name',
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CupertinoTextField(
                  controller: _ingredientControllers[i].quantity,
                  placeholder: 'Qty',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: CupertinoTextField(
                  controller: _ingredientControllers[i].unit,
                  placeholder: 'Unit',
                  padding: const EdgeInsets.all(10),
                ),
              ),
              if (_ingredientControllers.length > 1)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 4),
                  child: const Icon(
                    CupertinoIcons.minus_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 24,
                  ),
                  onPressed: () => _removeIngredientRow(i),
                ),
            ],
          ),
        ),
      );
    }
    fields.add(
      Align(
        alignment: Alignment.centerRight,
        child: CupertinoButton(
          child: const Text('+ Add Ingredient'),
          onPressed: _addIngredientRow,
        ),
      ),
    );
    return fields;
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(12),
          image: _image != null
              ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
              : null,
        ),
        child: _image == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.photo_camera,
                      size: 50,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 8),
                    Text('Tap to select an image'),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  List<Widget> _buildDynamicTextFields(
      List<TextEditingController> controllers, String placeholder, VoidCallback onAdd, Function(int) onRemove) {
    List<Widget> fields = [];
    for (int i = 0; i < controllers.length; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controllers[i],
                  placeholder: '$placeholder ${i + 1}',
                  padding: const EdgeInsets.all(12),
                ),
              ),
              if (controllers.length > 1)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 8),
                  child: const Icon(
                    CupertinoIcons.minus_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 24,
                  ),
                  onPressed: () => onRemove(i),
                ),
            ],
          ),
        ),
      );
    }
    fields.add(
      Align(
        alignment: Alignment.centerRight,
        child: CupertinoButton(
          child: const Text('+ Add Step'),
          onPressed: onAdd,
        ),
      ),
    );
    return fields;
  }
}