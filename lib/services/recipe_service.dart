import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:pocketbase/pocketbase.dart';

class RecipeService {
  final PocketBase _pb = PocketBaseClient.instance;

  // Mengambil semua resep yang dibuat oleh pengguna tertentu.
  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final records = await _pb.collection('meals').getFullList(
            filter: 'user_id = "$userId"',
            expand: 'category_id,user_id',
          );
      return records.map((record) {
        try {
          return Recipe.fromRecord(record);
        } catch (e) {
          print('Failed to parse recipe record ${record.id}: $e');
          return null;
        }
      }).whereType<Recipe>().toList();
    } catch (e) {
      print('Error fetching user recipes: $e');
      return [];
    }
  }

  // Fungsi untuk mengambil semua resep, dengan opsi limit.
  Future<List<Recipe>> getAllRecipes({int limit = 50}) async {
    try {
      final result = await _pb.collection('meals').getList(
            page: 1,
            perPage: limit,
            sort: '-created', // Mengurutkan dari yang terbaru
            expand: 'category_id,user_id',
          );
      return result.items.map((record) {
        try {
          return Recipe.fromRecord(record);
        } catch (e) {
          print('Failed to parse recipe record ${record.id}: $e');
          return null;
        }
      }).whereType<Recipe>().toList();
    } catch (e) {
      print('Error fetching all recipes: $e');
      return [];
    }
  }
}
