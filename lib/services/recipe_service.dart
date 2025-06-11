import 'dart:async';
import 'dart:io';

import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pocketbase/pocketbase.dart';

// Model untuk menampung input bahan dari UI
class IngredientInput {
  final String name;
  final String quantity;
  final String unit;

  IngredientInput({required this.name, required this.quantity, required this.unit});
}

class RecipeService {
  final PocketBase _pb = PocketBaseClient.instance;


  Future<RecordModel> createCategory(String name) async {
    try {
      final body = <String, dynamic>{'name': name};
      final record = await _pb.collection('meal_categories').create(body: body);
      return record;
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  Future<RecordModel> addIngredient(String name) async {
    try {
      final body = <String, dynamic>{'name': name};
      final record = await _pb.collection('ingredients').create(body: body);
      return record;
    } catch (e) {
      print('Error creating ingredient: $e');
      rethrow;
    }
  }

  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final records = await _pb.collection('meals').getFullList(
            filter: 'user_id = "$userId"',
            expand: 'user_id, category_id', 
          );
      return records.map((record) => Recipe.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching user recipes: $e');
      return [];
    }
  }

  Future<List<Recipe>> getAllRecipes({int limit = 50}) async {
    try {
      final result = await _pb.collection('meals').getList(
            page: 1,
            perPage: limit,
            sort: '-created',
            expand: 'user_id, category_id',
          );
      return result.items.map((record) => Recipe.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching all recipes: $e');
      return [];
    }
  }

  Future<List<RecordModel>> getMealCategories() async {
    try {
      final records = await _pb.collection('meal_categories').getFullList(sort: 'name');
      return records;
    } catch (e) {
      print('Error fetching meal categories: $e');
      return [];
    }
  }

  Future<List<RecordModel>> getIngredients() async {
    try {
      final records = await _pb.collection('ingredients').getFullList(sort: 'name');
      return records;
    } catch (e) {
      print('Error fetching ingredients: $e');
      return [];
    }
  }

  Future<void> createRecipe({
    required String name,
    required String description,
    required String prepTime,
    required String difficulty,
    required List<String> categoryIds,
    required List<IngredientInput> ingredients,
    required List<String> instructions,
    File? imageFile,
  }) async {
    final userId = _pb.authStore.model.id;

    final mealBody = <String, dynamic>{
      "name": name,
      "description": description,
      "times": int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      "difiiculty": difficulty,
      "user_id": userId,
      "category_id": categoryIds,
    };

    List<http.MultipartFile> files = [];
    if (imageFile != null) {
      files.add(http.MultipartFile.fromBytes(
        'image',
        await imageFile.readAsBytes(),
        filename: basename(imageFile.path),
      ));
    }
    
    final newMealRecord = await _pb.collection('meals').create(body: mealBody, files: files);
    final newMealId = newMealRecord.id;

    for (int i = 0; i < instructions.length; i++) {
        if(instructions[i].isNotEmpty){
            final stepBody = {
                "meal_id": newMealId,
                "description": instructions[i],
                "number": i + 1,
            };
            await _pb.collection('steps').create(body: stepBody);
        }
    }

    for (final ingredientInput in ingredients) {
      if (ingredientInput.name.isEmpty) continue;

      String ingredientId;
      try {
        final existingIngredient = await _pb.collection('ingredients')
            .getFirstListItem('name = "${ingredientInput.name.trim()}"');
        ingredientId = existingIngredient.id;
      } catch (_) {
        final newIngredientRecord = await _pb.collection('ingredients')
            .create(body: {'name': ingredientInput.name.trim()});
        ingredientId = newIngredientRecord.id;
      }

      final mealIngredientBody = {
        "meal_id": newMealId,
        "ingredient_id": ingredientId,
        "quantitiy": double.tryParse(ingredientInput.quantity) ?? 0,
        "unit": ingredientInput.unit.trim(),
      };
      await _pb.collection('meal_ingredient').create(body: mealIngredientBody);
    }
  }
}
