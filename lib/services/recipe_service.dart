import 'dart:io';

import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pocketbase/pocketbase.dart';

// Model sederhana untuk menampung input bahan dari UI
class IngredientInput {
  final String name;
  final String quantity;
  final String unit;

  IngredientInput({required this.name, required this.quantity, required this.unit});
}

class RecipeService {
  final PocketBase _pb = PocketBaseClient.instance;

  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final records = await _pb.collection('meals').getFullList(
            filter: 'user_id = "$userId"',
            expand: 'category_id,user_id',
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
            expand: 'category_id,user_id',
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


  Future<void> createRecipe({
    required String name,
    required String description,
    required String prepTime,
    required String difficulty,
    required String categoryId,
    required List<IngredientInput> ingredients,
    required List<String> instructions,
    File? imageFile,
  }) async {
    final userId = _pb.authStore.model!.id;
    final mealBody = <String, dynamic>{
      "name": name,
      "description": description,
      "times": int.tryParse(prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      "difiiculty": difficulty,
      "user_id": userId,
      "category_id": categoryId,
      "steps": instructions, // Field 'steps' harus ada di PocketBase dengan tipe JSON
    };

    List<http.MultipartFile> files = [];
    if (imageFile != null) {
      files.add(http.MultipartFile.fromBytes(
        'image',
        await imageFile.readAsBytes(),
        filename: basename(imageFile.path),
      ));
    }

    // Kirim data utama dan dapatkan record yang baru dibuat
    final newMealRecord = await _pb.collection('meals').create(body: mealBody, files: files);
    final newMealId = newMealRecord.id;

    // 2. Proses setiap bahan satu per satu
    for (final ingredientInput in ingredients) {
      if (ingredientInput.name.isEmpty) continue;

      String ingredientId;

      // 3. Cek apakah bahan sudah ada di tabel 'ingredients'
      try {
        final existingIngredient = await _pb.collection('ingredients')
            .getFirstListItem('name = "${ingredientInput.name.trim()}"');
        ingredientId = existingIngredient.id;
      } catch (_) {
        // Jika tidak ada, buat bahan baru
        final newIngredientRecord = await _pb.collection('ingredients')
            .create(body: {'name': ingredientInput.name.trim()});
        ingredientId = newIngredientRecord.id;
      }

      // 4. Buat record di tabel penghubung 'meal_ingredient'
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
