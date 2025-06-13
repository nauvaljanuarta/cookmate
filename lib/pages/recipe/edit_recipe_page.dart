// import 'dart:io';
// import 'package:cookmate2/config/theme.dart';
// import 'package:cookmate2/models/recipe.dart';
// import 'package:cookmate2/models/step.dart' as model_step;
// import 'package:cookmate2/models/meal_ingredient.dart';
// import 'package:cookmate2/services/recipe_service.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart'; // PERBAIKAN: Impor Material untuk SnackBar
// import 'package:image_picker/image_picker.dart';
// import 'package:pocketbase/pocketbase.dart';

// class EditRecipePage extends StatefulWidget {
//   final Recipe recipe;

//   const EditRecipePage({super.key, required this.recipe});

//   @override
//   State<EditRecipePage> createState() => _EditRecipePageState();
// }

// class _EditRecipePageState extends State<EditRecipePage> {
//   final _formKey = GlobalKey<FormState>();
//   final _recipeService = RecipeService();
//   bool _isLoading = true;

//   // Controllers for basic info
//   late TextEditingController _nameController;
//   late TextEditingController _descriptionController;
//   late TextEditingController _prepTimeController;
//   String _difficultyValue = 'Medium';
//   File? _imageFile;
//   String? _networkImageUrl;

//   // Controllers for dynamic fields
//   final List<TextEditingController> _stepControllers = [];
//   final List<IngredientInput> _ingredients = [];
  
//   // State for categories
//   List<RecordModel> _allCategories = [];
//   final List<String> _selectedCategoryIds = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeForm();
//     _loadInitialData();
//   }
  
//   void _initializeForm() {
//     _nameController = TextEditingController(text: widget.recipe.title);
//     _descriptionController = TextEditingController(text: widget.recipe.description);
//     _prepTimeController = TextEditingController(text: '${widget.recipe.prepTimeMinutes + widget.recipe.cookTimeMinutes}');
//     _difficultyValue = widget.recipe.difficulty;
//     _networkImageUrl = widget.recipe.imageUrl;
    
//     // PERBAIKAN: Model Recipe seharusnya memiliki 'categoryIds'. 
//     // Jika tidak ada, pastikan Anda menambahkannya di model Recipe Anda.
//     // Untuk sementara, kita asumsikan properti ini ada.
//     _selectedCategoryIds.addAll(widget.recipe.categoryIds); 
//   }

//   Future<void> _loadInitialData() async {
//     try {
//       final categories = await _recipeService.getMealCategories();
//       final steps = await _recipeService.getStepsForRecipe(widget.recipe.id);
//       final ingredients = await _recipeService.getIngredientsForRecipe(widget.recipe.id);

//       if (mounted) {
//         setState(() {
//           _allCategories = categories;
          
//           for (var step in steps) {
//             _stepControllers.add(TextEditingController(text: step.description));
//           }

//           for (var ing in ingredients) {
//             _ingredients.add(IngredientInput(
//               ingredientId: ing.ingredientId,
//               quantity: ing.quantity.toString(),
//               unit: ing.unit,
//             ));
//           }
          
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         _showErrorDialog("Failed to load recipe data: $e");
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _prepTimeController.dispose();
//     for (var controller in _stepControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
  
//   void _addStepField() {
//     setState(() => _stepControllers.add(TextEditingController()));
//   }

//   void _removeStepField(int index) {
//     setState(() {
//       _stepControllers[index].dispose();
//       _stepControllers.removeAt(index);
//     });
//   }
  
//   Future<void> _submitForm() async {
//     if (_formKey.currentState?.validate() != true) return;
    
//     setState(() => _isLoading = true);
    
//     try {
//       await _recipeService.updateRecipe(
//         recipeId: widget.recipe.id,
//         name: _nameController.text,
//         description: _descriptionController.text,
//         prepTime: _prepTimeController.text,
//         difficulty: _difficultyValue,
//         categoryIds: _selectedCategoryIds,
//         ingredients: _ingredients,
//         instructions: _stepControllers.map((c) => c.text).toList(),
//         imageFile: _imageFile,
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe updated successfully!'), backgroundColor: Colors.green));
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//        _showErrorDialog("Error updating recipe: $e");
//     } finally {
//        if (mounted) {
//          setState(() => _isLoading = false);
//        }
//     }
//   }

//   void _showErrorDialog(String message) {
//     showCupertinoDialog(
//       context: context,
//       builder: (context) => CupertinoAlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context))],
//       )
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         middle: const Text('Edit Recipe'),
//         trailing: CupertinoButton(
//           padding: EdgeInsets.zero,
//           child: _isLoading ? const CupertinoActivityIndicator() : const Text('Save'),
//           onPressed: _isLoading ? null : _submitForm,
//         ),
//       ),
//       child: SafeArea(
//         child: _isLoading && _stepControllers.isEmpty
//             ? const Center(child: CupertinoActivityIndicator())
//             : Form(
//                 key: _formKey,
//                 child: ListView(
//                   padding: const EdgeInsets.all(16.0),
//                   children: [
//                     // --- UI LENGKAP UNTUK FORM EDIT ---
//                     const Text('Recipe Name', style: AppTheme.subheadingStyle),
//                     const SizedBox(height: 8),
//                     CupertinoTextField(
//                       controller: _nameController,
//                       placeholder: 'e.g., Nasi Goreng Spesial',
//                     ),
//                     const SizedBox(height: 24),

//                     const Text('Description', style: AppTheme.subheadingStyle),
//                     const SizedBox(height: 8),
//                     CupertinoTextField(
//                       controller: _descriptionController,
//                       placeholder: 'A short story about your recipe',
//                       maxLines: 4,
//                     ),
//                     const SizedBox(height: 24),

//                     // ... (Tambahkan UI untuk image picker, categories, difficulty, dll. di sini) ...

//                     const Text('Instructions', style: AppTheme.subheadingStyle),
//                     const SizedBox(height: 8),
//                     ..._stepControllers.asMap().entries.map((entry) {
//                       int idx = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: Row(
//                           children: [
//                             Text('${idx + 1}.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                             const SizedBox(width: 8),
//                             Expanded(child: CupertinoTextField(controller: entry.value, placeholder: 'Write a step')),
//                             CupertinoButton(
//                               padding: const EdgeInsets.all(4),
//                               child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed),
//                               onPressed: () => _removeStepField(idx),
//                             )
//                           ],
//                         ),
//                       );
//                     }),
//                     CupertinoButton(
//                       child: const Text('Add Step'),
//                       onPressed: _addStepField,
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
