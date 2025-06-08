import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:pocketbase/pocketbase.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String authorName;
  final String authorImageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final List<String> categories;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = 'https://placehold.co/600x400?text=No+Image',
    required this.authorName,
    required this.authorImageUrl,
    required this.ingredients,
    required this.steps,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.categories,
    this.isFavorite = false,
  });

  // Factory constructor untuk membuat objek Recipe dari RecordModel PocketBase.
  factory Recipe.fromRecord(RecordModel record) {
    final data = record.data;
    
    // Mengambil data kategori
    final categoryRecords = record.get<List<RecordModel>>('expand.category_id');
    final categoryName = categoryRecords.isNotEmpty
        ? categoryRecords.first.getStringValue('name')
        : 'Uncategorized';

    // Mengambil data pengguna (pembuat resep) dari relasi 'user_id'.
    final userRecords = record.get<List<RecordModel>>('expand.user_id');
    String authorName = 'Unknown Author';
    String authorImageUrl = 'https://placehold.co/100?text=?';
    if (userRecords.isNotEmpty) {
      final userRecord = userRecords.first;
      authorName = userRecord.getStringValue('username');
      final profileImageName = userRecord.getStringValue('profileImage');
      if (profileImageName.isNotEmpty) {
        authorImageUrl = PocketBaseClient.instance.files.getUrl(userRecord, profileImageName).toString();
      }
    }
    
    // Membuat URL untuk gambar resep.
    String imageUrl;
    if (data['image'] != null && data['image'].isNotEmpty) {
      imageUrl = PocketBaseClient.instance.files.getUrl(record, data['image']).toString();
    } else {
      imageUrl = 'https://placehold.co/600x400?text=No+Image';
    }

    // Membersihkan tag HTML dari deskripsi.
    String description = data['description'] ?? 'No Description';
    final RegExp htmlTags = RegExp(r'<[^>]*>');
    description = description.replaceAll(htmlTags, '').replaceAll('&nbsp;', ' ').trim();

    return Recipe(
      id: record.id,
      title: data['name'] ?? 'No Title',
      description: description,
      imageUrl: imageUrl, 
      authorName: authorName,
      authorImageUrl: authorImageUrl,
      difficulty: data['difiiculty'] ?? 'Unknown',
      categories: [categoryName],
      prepTimeMinutes: (data['times'] ?? 0).toInt(),
      cookTimeMinutes: 0, 
      servings: 4, 
      ingredients: [], 
      steps: [], 
    );
  }
}
