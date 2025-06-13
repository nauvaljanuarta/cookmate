import 'dart:io';
import 'dart:async';
import 'package:cookmate2/models/meal_ingredient.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/step.dart';
import 'package:pocketbase/pocketbase.dart';

class IngredientInput {
  final String ingredientId;
  final String quantity;
  final String unit;

  IngredientInput({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
  });
}

class RecipeService {
  final PocketBase _pb = PocketBaseClient.instance;

  Future<List<Recipe>> getAllRecipes({int limit = 50}) async {
    try {
      final result = await _pb.collection('meals').getList(
            page: 1,
            perPage: limit,
            sort: '-created',
            expand: 'user_id,category_id,meal_ingredient(meal_id).ingredient_id',
          );
      return result.items.map((record) => Recipe.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching all recipes: $e');
      rethrow;
    }
  }

  Future<List<RecordModel>> getMealCategories() async {
    try {
      return await _pb.collection('meal_categories').getFullList(sort: 'name');
    } catch (e) {
      print('Error fetching meal categories: $e');
      rethrow;
    }
  }

  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final records = await _pb.collection('meals').getFullList(
            filter: 'user_id = "$userId"',
            expand: 'user_id,category_id',
          );
      return records.map((record) => Recipe.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching user recipes: $e');
      return [];
    }
  }

  Future<List<Step>> getStepsForRecipe(String recipeId) async {
    try {
      final records = await _pb.collection('steps').getFullList(
            filter: 'meal_id = "$recipeId"',
            sort: '+number',
          );
      return records.map((record) => Step.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting steps for recipe $recipeId: $e');
      return [];
    }
  }

  Future<List<MealIngredient>> getIngredientsForRecipe(String recipeId) async {
    try {
      final records = await _pb.collection('meal_ingredient').getFullList(
            filter: 'meal_id = "$recipeId"',
            expand: 'ingredient_id', // Penting untuk mendapatkan nama bahan
          );
      return records.map((record) => MealIngredient.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting ingredients for recipe $recipeId: $e');
      return [];
    }
  }

  Future<RecordModel> addIngredient(String name, [String? description]) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description ?? ''
      };
      return await _pb.collection('ingredients').create(body: body);
    } catch (e) {
      print('Error creating ingredient: $e');
      rethrow;
    }
  }

  Future<List<RecordModel>> searchIngredients(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final result = await _pb.collection('ingredients').getList(perPage: 15, filter: 'name ~ "${query.trim()}"');
      return result.items;
    } catch (e) {
      print('Error searching ingredients: $e');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    if (query.trim().isEmpty) return [];

    final Set<String> mealIds = {};

    final mealNameFilter = 'name ~ "$query" || description ~ "$query"';
    final mealsByName = await _pb.collection('meals').getFullList(filter: mealNameFilter);
    for (var meal in mealsByName) {
      mealIds.add(meal.id);
    }

    final ingredients = await _pb.collection('ingredients').getFullList(filter: 'name ~ "$query"');
    if (ingredients.isNotEmpty) {
      final ingredientIdFilters = ingredients.map((i) => 'ingredient_id = "${i.id}"').join(' || ');
      final mealIngredients = await _pb.collection('meal_ingredient').getFullList(filter: '($ingredientIdFilters)');
      for (var mi in mealIngredients) {
        mealIds.add(mi.data['meal_id']);
      }
    }

    final categories = await _pb.collection('meal_categories').getFullList(filter: 'name ~ "$query"');
    if (categories.isNotEmpty) {
      final categoryIdFilters = categories.map((c) => 'category_id ?~ "${c.id}"').join(' || ');
      final mealsByCategory = await _pb.collection('meals').getFullList(filter: '($categoryIdFilters)');
      for (var meal in mealsByCategory) {
        mealIds.add(meal.id);
      }
    }

    if (mealIds.isEmpty) return [];

    final finalFilter = mealIds.map((id) => 'id = "$id"').join(' || ');
    final finalResult = await _pb.collection('meals').getFullList(
          filter: finalFilter,
          expand: 'user_id,category_id,meal_ingredient(meal_id).ingredient_id',
        );

    return finalResult.map((record) => Recipe.fromRecord(record)).toList();
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
    if (!_pb.authStore.isValid) throw Exception("User not authenticated.");

    final userId = _pb.authStore.model.id;

    final mealBody = <String, dynamic>{
      "name": name,
      "description": description,
      "times": int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      "difficulty": difficulty,
      "user_id": userId,
      "category_id": categoryIds,
    };

    List<http.MultipartFile> files = [];
    if (imageFile != null) {
      files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: basename(imageFile.path)));
    }

    final newMealRecord = await _pb.collection('meals').create(body: mealBody, files: files);
    final newMealId = newMealRecord.id;

    try {
      final stepFutures = instructions.where((t) => t.isNotEmpty).map((text) {
        final stepBody = {
          "meal_id": newMealId,
          "description": text,
          "number": instructions.indexOf(text) + 1
        };
        return _pb.collection('steps').create(body: stepBody);
      });

      final ingredientFutures = ingredients.map((input) {
        final body = {
          "meal_id": newMealId,
          "ingredient_id": input.ingredientId,
          "quantity": double.tryParse(input.quantity) ?? 0,
          "unit": input.unit
        };
        return _pb.collection('meal_ingredient').create(body: body);
      });

      await Future.wait([
        ...stepFutures,
        ...ingredientFutures
      ]);
    } catch (e) {
      await _pb.collection('meals').delete(newMealId);
      throw Exception('Failed to save related records. Check API Rules. Error: $e');
    }
  }

  Future<void> updateRecipe({
    required String recipeId,
    required String name,
    required String description,
    required String prepTime,
    required String difficulty,
    required List<String> categoryIds,
    required List<IngredientInput> ingredients,
    required List<String> instructions,
    File? imageFile,
  }) async {
    // 1. Update data utama pada koleksi 'meals'
    final mealBody = <String, dynamic>{
      "name": name,
      "description": description,
      "times": int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      "difficulty": difficulty,
      "category_id": categoryIds,
    };

    List<http.MultipartFile> files = [];
    if (imageFile != null) {
      files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: basename(imageFile.path)));
    }

    await _pb.collection('meals').update(recipeId, body: mealBody, files: files);

    final oldSteps = await _pb.collection('steps').getFullList(filter: 'meal_id = "$recipeId"');
    final oldIngredients = await _pb.collection('meal_ingredient').getFullList(filter: 'meal_id = "$recipeId"');

    final deletionFutures = [
      ...oldSteps.map((s) => _pb.collection('steps').delete(s.id)),
      ...oldIngredients.map((i) => _pb.collection('meal_ingredient').delete(i.id)),
    ];
    await Future.wait(deletionFutures);

    // 3. Buat kembali 'steps' dan 'meal_ingredient' yang baru
    final creationFutures = [
      ...instructions.where((t) => t.isNotEmpty).map((text) {
        final stepBody = {
          "meal_id": recipeId,
          "description": text,
          "number": instructions.indexOf(text) + 1
        };
        return _pb.collection('steps').create(body: stepBody);
      }),
      ...ingredients.map((input) {
        final body = {
          "meal_id": recipeId,
          "ingredient_id": input.ingredientId,
          "quantity": double.tryParse(input.quantity) ?? 0,
          "unit": input.unit
        };
        return _pb.collection('meal_ingredient').create(body: body);
      }),
    ];
    await Future.wait(creationFutures);
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      final stepsRecords = await _pb.collection('steps').getFullList(filter: 'meal_id = "$recipeId"');
      final stepDeletions = stepsRecords.map((step) => _pb.collection('steps').delete(step.id));

      final ingredientsRecords = await _pb.collection('meal_ingredient').getFullList(filter: 'meal_id = "$recipeId"');
      final ingredientDeletions = ingredientsRecords.map((ing) => _pb.collection('meal_ingredient').delete(ing.id));

      await Future.wait([
        ...stepDeletions,
        ...ingredientDeletions
      ]);

      await _pb.collection('meals').delete(recipeId);
    } catch (e) {
      print('Error deleting recipe $recipeId: $e');
      rethrow;
    }
  }
}
