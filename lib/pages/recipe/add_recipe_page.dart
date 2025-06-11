import 'dart:async';
import 'dart:io';

import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/pages/recipe/select_ingredient_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

class AddRecipePage extends StatefulWidget {
  // PERBAIKAN: Menghapus callback `onRecipeAdded` dari constructor
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

/// Controller untuk setiap baris bahan di UI.
class RecipeIngredientController {
  RecordModel? selectedIngredient;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    unitController.dispose();
  }
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _recipeService = RecipeService();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();

  String _selectedDifficulty = 'Medium';
  List<RecordModel> _categories = [];
  final List<String> _selectedCategoryIds = [];

  List<RecipeIngredientController> _ingredientControllers = [RecipeIngredientController()];
  List<TextEditingController> _instructionControllers = [TextEditingController()];

  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    for (var controller in _ingredientControllers) { controller.dispose(); }
    for (var controller in _instructionControllers) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _recipeService.getMealCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to load categories: $e');
    }
  }

  Future<void> _navigateToSelectIngredient(int index) async {
    final selectedIngredient = await Navigator.push<RecordModel>(
      context,
      CupertinoPageRoute(builder: (context) => const SelectIngredientPage()),
    );
    if (selectedIngredient != null && mounted) {
      setState(() {
        _ingredientControllers[index].selectedIngredient = selectedIngredient;
      });
    }
  }
  
  Future<void> _submitRecipe() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty || _prepTimeController.text.isEmpty) {
      _showValidationError('Please fill all recipe details.'); return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showValidationError('Please select at least one category.'); return;
    }

    final ingredients = _ingredientControllers
        .where((c) => c.selectedIngredient != null && c.quantityController.text.isNotEmpty)
        .map((c) => IngredientInput(
              ingredientId: c.selectedIngredient!.id,
              quantity: c.quantityController.text,
              unit: c.unitController.text,
            )).toList();

    if (ingredients.isEmpty) {
      _showValidationError('At least one valid ingredient with quantity is required.'); return;
    }

    final instructions = _instructionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
    if (instructions.isEmpty) {
      _showValidationError('At least one instruction is required.'); return;
    }

    setState(() => _isLoading = true);

    try {
      await _recipeService.createRecipe(
        name: _nameController.text,
        description: _descriptionController.text,
        prepTime: _prepTimeController.text,
        difficulty: _selectedDifficulty,
        categoryIds: _selectedCategoryIds,
        ingredients: ingredients,
        instructions: instructions,
        imageFile: _image,
      );
      if (mounted) {
        await _showSuccessAndReset();
      }
    } catch (e) {
      if(mounted) {
        _showErrorSnackbar('Failed to add recipe: $e');
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _showSuccessAndReset() async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const CupertinoAlertDialog(
          title: Text('Success!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.systemGreen, size: 60),
              SizedBox(height: 15),
              Text('Recipe has been saved.'),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog
      _resetForm(); // Panggil fungsi untuk membersihkan form
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _prepTimeController.clear();
      _image = null;
      _selectedDifficulty = 'Medium';
      _selectedCategoryIds.clear();

      for (var controller in _ingredientControllers) {
        controller.dispose();
      }
      _ingredientControllers = [RecipeIngredientController()];
      
      for (var controller in _instructionControllers) {
        controller.dispose();
      }
      _instructionControllers = [TextEditingController()];

      _isLoading = false; 
    });
  }

  void _addIngredientRow() => setState(() => _ingredientControllers.add(RecipeIngredientController()));
  
  void _removeIngredientRow(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers[index].dispose();
        _ingredientControllers.removeAt(index);
      });
    }
  }
  
  void _addInstructionField() => setState(() => _instructionControllers.add(TextEditingController()));

  void _removeInstructionField(int index) {
    if (_instructionControllers.length > 1) {
      setState(() {
        _instructionControllers[index].dispose();
        _instructionControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }
  
  void _showValidationError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  void _showErrorSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add New Recipe'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  _buildImagePicker(), const SizedBox(height: 20),
                  _buildSectionTitle('Recipe Details'),
                  _buildTextField(_nameController, 'Recipe Name'),
                  _buildTextField(_descriptionController, 'Description', maxLines: 3),
                  _buildTextField(_prepTimeController, 'Prep Time (e.g., 30 min)', keyboardType: TextInputType.number),
                  _buildPickerField('Difficulty', _selectedDifficulty, ['EZ', 'Medium', 'Hard'], (v) => setState(() => _selectedDifficulty = v)),
                  _categories.isEmpty ? const Center(child: CupertinoActivityIndicator()) : _buildMultiSelectPickerField(
                    'Categories', _getSelectedCategoryNames().isNotEmpty ? _getSelectedCategoryNames() : 'Select one or more', _showCategorySelectionDialog),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ingredients'),
                  _buildIngredientSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Instructions'), ..._buildInstructionFields(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIngredientSection() {
    return Column(
      children: [
        for (int i = 0; i < _ingredientControllers.length; i++)
          _buildSingleIngredientField(i),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(child: const Text('+ Add Ingredient'), onPressed: _addIngredientRow),
        ),
      ],
    );
  }
  
  Widget _buildSingleIngredientField(int index) {
    final controller = _ingredientControllers[index];
    final ingredientName = controller.selectedIngredient?.data['name'] ?? 'Select Ingredient';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: CupertinoButton(
              color: controller.selectedIngredient != null ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey6,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () => _navigateToSelectIngredient(index),
              child: Text(
                ingredientName,
                style: TextStyle(
                  color: controller.selectedIngredient != null ? CupertinoColors.label.resolveFrom(context) : CupertinoColors.placeholderText.resolveFrom(context),
                  overflow: TextOverflow.ellipsis
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: CupertinoTextField(controller: controller.quantityController, placeholder: 'Qty', keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: CupertinoTextField(controller: controller.unitController, placeholder: 'Unit')),
          if (_ingredientControllers.length > 1)
            CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed, size: 24),
              onPressed: () => _removeIngredientRow(index),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: AppTheme.primaryColor,
          onPressed: _isLoading ? null : _submitRecipe,
          child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text(
                'Save Recipe',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(title, style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold)));
  }
  
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: CupertinoColors.systemGrey5, borderRadius: BorderRadius.circular(12),
          image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null),
        child: _image == null ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.photo_camera, size: 50, color: CupertinoColors.systemGrey),
              SizedBox(height: 8), Text('Tap to select an image'),
            ])) : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0),
      child: CupertinoTextField(controller: controller, placeholder: placeholder, maxLines: maxLines, keyboardType: keyboardType,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Widget> _buildInstructionFields() {
    List<Widget> fields = [];
    for (int i = 0; i < _instructionControllers.length; i++) {
      fields.add(Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [
        Expanded(child: CupertinoTextField(controller: _instructionControllers[i], placeholder: 'Step ${i + 1}', maxLines: null)),
        if (_instructionControllers.length > 1) CupertinoButton(padding: const EdgeInsets.only(left: 8),
            child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed, size: 24),
            onPressed: () => _removeInstructionField(i)),
      ])));
    }
    fields.add(Align(alignment: Alignment.centerRight,
      child: CupertinoButton(child: const Text('+ Add Step'), onPressed: _addInstructionField),
    ));
    return fields;
  }
  
  String _getSelectedCategoryNames() {
    if (_selectedCategoryIds.isEmpty) return '';
    return _categories.where((c) => _selectedCategoryIds.contains(c.id)).map((c) => c.data['name'].toString()).join(', ');
  }

  Widget _buildPickerField(String title, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () => _showPicker(context, options, (index) => onChanged(options[index])),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
          Row(children: [
            Text(currentValue, style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey)),
            const SizedBox(width: 8), const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMultiSelectPickerField(String title, String currentValue, VoidCallback onTap) {
     return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: CupertinoTheme.of(context).textTheme.textStyle), const SizedBox(width: 16),
          Expanded(child: Text(currentValue, textAlign: TextAlign.end, style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8), const Icon(CupertinoIcons.chevron_up_chevron_down, size: 16, color: CupertinoColors.systemGrey),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> items, ValueChanged<int> onSelectedItemChanged) {
    showCupertinoModalPopup(context: context, builder: (_) => Container(height: 250, color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoPicker(itemExtent: 32.0, onSelectedItemChanged: onSelectedItemChanged, children: items.map((item) => Center(child: Text(item))).toList())));
  }

  void _showCategorySelectionDialog() {
    showCupertinoModalPopup(context: context, builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter modalSetState) {
            return CupertinoActionSheet(
              title: const Text('Select Categories'), message: const Text('You can select more than one category.'),
              actions: _categories.map((category) {
                final bool isSelected = _selectedCategoryIds.contains(category.id);
                return CupertinoActionSheetAction(
                  onPressed: () {
                    modalSetState(() {
                      if (isSelected) { _selectedCategoryIds.remove(category.id); } else { _selectedCategoryIds.add(category.id); }
                    });
                    setState(() {});
                  },
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(category.data['name']),
                    if (isSelected) const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryColor),
                  ]),
                );
              }).toList(),
              cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true, onPressed: () => Navigator.pop(context), child: const Text('Done')),
            );
          },
        );
      },
    );
  }
}
