import 'dart:async';
import 'dart:io';

import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/step.dart' as model_step;
import 'package:cookmate2/pages/recipe/select_ingredient_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

// Helper class untuk state bahan di UI.
class UIIngredient {
  String ingredientId;
  String name;
  TextEditingController qtyController;
  TextEditingController unitController;

  UIIngredient({
    required this.ingredientId,
    required this.name,
    required String quantity,
    required String unit,
  })  : qtyController = TextEditingController(text: quantity),
        unitController = TextEditingController(text: unit);
  
  void dispose() {
    qtyController.dispose();
    unitController.dispose();
  }
}

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;

  const EditRecipePage({super.key, required this.recipe});

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _recipeService = RecipeService();
  bool _isLoading = true;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _timesController;
  late TextEditingController _servingsController;
  String _selectedDifficulty = 'MD';
  
  // State
  List<RecordModel> _allCategories = [];
  final List<String> _selectedCategoryIds = [];
  final List<UIIngredient> _ingredients = [];
  final List<TextEditingController> _instructionControllers = [];
  File? _imageFile;
  String? _networkImageUrl;
  final _picker = ImagePicker();

  // Data mapping untuk Difficulty
  final Map<String, String> _difficultyOptions = {
    'EZ': 'Easy',
    'MD': 'Medium',
    'HD': 'Hard',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timesController.dispose();
    _servingsController.dispose();
    for (var controller in _ingredients) { controller.dispose(); }
    for (var controller in _instructionControllers) { controller.dispose(); }
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> _loadInitialData() async {
    _nameController = TextEditingController(text: widget.recipe.name);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _timesController = TextEditingController(text: widget.recipe.times.toString());
    _servingsController = TextEditingController(text: widget.recipe.servings.toString());
    _networkImageUrl = widget.recipe.imageUrl;
    
    _selectedDifficulty = widget.recipe.difficulty;
    if (!_difficultyOptions.keys.contains(_selectedDifficulty)) {
      _selectedDifficulty = 'MD';
    }

    try {
      final results = await Future.wait([
        _recipeService.getMealCategories(),
        _recipeService.getStepsForRecipe(widget.recipe.id),
        _recipeService.getIngredientsForRecipe(widget.recipe.id),
      ]);

      if (mounted) {
        setState(() {
          _allCategories = results[0] as List<RecordModel>;
          for (var categoryName in widget.recipe.categories) {
            final matchingCategory = _allCategories.firstWhere(
              (cat) => cat.data['name'] == categoryName, orElse: () => RecordModel());
            if (matchingCategory.id.isNotEmpty) {
              _selectedCategoryIds.add(matchingCategory.id);
            }
          }

          final steps = results[1] as List<model_step.Step>;
          for (var step in steps) {
            _instructionControllers.add(TextEditingController(text: step.description));
          }

          final ingredientRecords = results[2] as List<RecordModel>;
          for (var record in ingredientRecords) {
            _ingredients.add(UIIngredient(
              ingredientId: record.data['ingredient_id'],
              name: record.expand['ingredient_id']?.first.data['name'] ?? 'Unknown',
              quantity: (record.data['quantity'] ?? 0).toString(),
              unit: record.data['unit'] ?? '',
            ));
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar("Failed to load recipe data: $e");
      }
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty || _timesController.text.isEmpty || _servingsController.text.isEmpty) {
      _showErrorSnackbar('Please fill all recipe details.'); return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showErrorSnackbar('Please select at least one category.'); return;
    }
    final ingredients = _ingredients
        .where((c) => c.ingredientId.isNotEmpty && c.qtyController.text.isNotEmpty)
        .map((c) => IngredientInput(
            ingredientId: c.ingredientId,
            quantity: c.qtyController.text,
            unit: c.unitController.text,
          )).toList();
    if (ingredients.isEmpty) {
      _showErrorSnackbar('At least one valid ingredient with quantity is required.'); return;
    }
    final instructions = _instructionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
    if (instructions.isEmpty) {
      _showErrorSnackbar('At least one instruction is required.'); return;
    }

    setState(() => _isLoading = true);

    try {
      await _recipeService.updateRecipe(
        recipeId: widget.recipe.id,
        name: _nameController.text,
        description: _descriptionController.text,
        times: _timesController.text,
        servings: _servingsController.text,
        difficulty: _selectedDifficulty,
        categoryIds: _selectedCategoryIds,
        ingredients: ingredients,
        instructions: instructions,
        imageFile: _imageFile,
      );
      if (mounted) {
        _showFeedbackDialog('Success', 'Recipe updated successfully!', isError: false);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update recipe: $e');
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showFeedbackDialog(String title, String content, {bool isError = true}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (!isError) Navigator.of(context).pop(true);
            },
          )
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }
  
  void _addIngredientRow() => setState(() => _ingredients.add(UIIngredient(ingredientId: '', name: 'Select Ingredient', quantity: '', unit: '')));
  void _removeIngredientRow(int index) {
      if (_ingredients.length > 0) { // Allow removing the last one too
        setState(() {
            _ingredients[index].dispose();
            _ingredients.removeAt(index);
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
  
  void _showErrorSnackbar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Recipe'),
         trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading ? const CupertinoActivityIndicator() : const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: _isLoading
        ? const Center(child: CupertinoActivityIndicator(radius: 20))
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildImagePicker(), const SizedBox(height: 24),
              _buildSectionTitle('Recipe Details'),
              _buildTextField(_nameController, 'Recipe Name'),
              _buildTextField(_descriptionController, 'Description', maxLines: 3),
              Row(
                children: [
                  Expanded(child: _buildTextField(_servingsController, 'Servings', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_timesController, 'Time (min)', keyboardType: TextInputType.number)),
                ],
              ),
              _buildPickerField('Difficulty', _difficultyOptions[_selectedDifficulty]!, _difficultyOptions.values.toList(),
                  (v) => setState(() => _selectedDifficulty = _difficultyOptions.keys.firstWhere((k) => _difficultyOptions[k] == v, orElse: () => 'MD'))),
              _buildMultiSelectPickerField(
                  'Categories', _getSelectedCategoryNames().isNotEmpty ? _getSelectedCategoryNames() : 'Select categories', _showCategorySelectionDialog),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Ingredients'),
              _buildIngredientSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Instructions'),
              ..._buildInstructionFields(),
            ],
          ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
        child: Text(title, style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold)));
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
            image: _imageFile != null
                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(_networkImageUrl!), fit: BoxFit.cover)
                    : null)),
        child: (_imageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(CupertinoIcons.photo_camera, size: 50, color: CupertinoColors.systemGrey),
                  SizedBox(height: 8), Text('Tap to change image'),
                ]))
            : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        keyboardType: keyboardType,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIngredientSection() {
    return Column(
      children: [
        if (_ingredients.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('No ingredients added yet.')),
        for (int i = 0; i < _ingredients.length; i++) _buildSingleIngredientField(i),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(child: const Text('+ Add Ingredient'), onPressed: _addIngredientRow),
        ),
      ],
    );
  }

  Widget _buildSingleIngredientField(int index) {
    final uiIngredient = _ingredients[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: CupertinoButton(
              color: CupertinoColors.systemGrey6,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () async {
                  final selected = await Navigator.push<RecordModel>(context,
                      CupertinoPageRoute(builder: (context) => const SelectIngredientPage()));
                  if (selected != null && mounted) {
                    setState(() {
                      uiIngredient.ingredientId = selected.id;
                      uiIngredient.name = selected.data['name'];
                    });
                  }
              },
              child: Text(
                uiIngredient.name,
                style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: CupertinoTextField(controller: uiIngredient.qtyController, placeholder: 'Qty', keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: CupertinoTextField(controller: uiIngredient.unitController, placeholder: 'Unit')),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 4),
            child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed, size: 24),
            onPressed: () => _removeIngredientRow(index),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildInstructionFields() {
    return [
      if (_instructionControllers.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('No instructions added yet.')),
      ..._instructionControllers.asMap().entries.map((entry) {
        int i = entry.key;
        return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _instructionControllers[i],
                  placeholder: 'Step ${i + 1}',
                  maxLines: null,
                  decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_instructionControllers.length > 1)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 8),
                  child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed, size: 24),
                  onPressed: () => _removeInstructionField(i),
                ),
            ]));
      }).toList(),
      Align(
        alignment: Alignment.centerRight,
        child: CupertinoButton(child: const Text('+ Add Step'), onPressed: _addInstructionField),
      )
    ];
  }

  String _getSelectedCategoryNames() {
    if (_selectedCategoryIds.isEmpty) return '';
    return _allCategories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.data['name'].toString())
        .join(', ');
  }

  Widget _buildPickerField(String title, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () => _showPicker(context, options, (index) => onChanged(options[index])),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
            Row(children: [
              Text(currentValue, style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey)),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.systemGrey),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectPickerField(String title, String currentValue, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: CupertinoTheme.of(context).textTheme.textStyle),
            const SizedBox(width: 16),
            Expanded(
                child: Text(currentValue,
                    textAlign: TextAlign.end,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_up_chevron_down, size: 16, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> items, ValueChanged<int> onSelectedItemChanged) {
    final initialIndex = items.indexOf(_difficultyOptions[_selectedDifficulty]!);
    showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: initialIndex >= 0 ? initialIndex : 0),
                itemExtent: 32.0,
                onSelectedItemChanged: onSelectedItemChanged,
                children: items.map((item) => Center(child: Text(item))).toList())));
  }

  void _showCategorySelectionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        // Gunakan StatefulBuilder agar dialog bisa punya state sendiri
        return StatefulBuilder(builder: (BuildContext context, StateSetter modalSetState) {
          return CupertinoActionSheet(
            title: const Text('Select Categories'),
            message: const Text('You can select more than one category.'),
            actions: _allCategories.map((category) {
              final bool isSelected = _selectedCategoryIds.contains(category.id);
              return CupertinoActionSheetAction(
                onPressed: () {
                  modalSetState(() {
                    if (isSelected) {
                      _selectedCategoryIds.remove(category.id);
                    } else {
                      _selectedCategoryIds.add(category.id);
                    }
                  });
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(category.data['name']),
                  if (isSelected) const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryColor),
                ]),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                    Navigator.pop(context);
                    // Refresh UI utama setelah dialog ditutup
                    setState(() {});
                },
                child: const Text('Done')),
          );
        });
      },
    );
  }
}
