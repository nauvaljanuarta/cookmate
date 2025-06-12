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

 
}
