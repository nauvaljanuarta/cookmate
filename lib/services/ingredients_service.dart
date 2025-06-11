import 'dart:async';
import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:pocketbase/pocketbase.dart';

class IngredientService {
  final PocketBase _pb = PocketBaseClient.instance;


  Future<List<RecordModel>> searchIngredients(String query) async {
    if (query.isEmpty) return [];
    try {
      final result = await _pb.collection('ingredients').getList(
            perPage: 10,
            filter: 'name ~ "${query.trim()}"',
          );
      return result.items;
    } catch (e) {
      print('Error searching ingredients: $e');
      return [];
    }
  }

  Future<RecordModel> createIngredient(String name, [String? description]) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description ?? '',
      };
      final record = await _pb.collection('ingredients').create(body: body);
      return record;
    } catch (e) {
      print('Error creating ingredient: $e');
      rethrow;
    }
  }

  Future<void> addIngredientToMeal({
    required String mealId,
    required String ingredientId,
    required String quantity,
    required String unit,
  }) async {
    try {
      final body = <String, dynamic>{
        "meal_id": mealId,
        "ingredient_id": ingredientId,
        "quantity": double.tryParse(quantity) ?? 0,
        "unit": unit.trim(),
      };
      await _pb.collection('meal_ingredient').create(body: body);
    } catch (e) {
      print('Error adding ingredient to meal: $e');
      rethrow;
    }
  }
}
