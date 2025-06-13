import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:pocketbase/pocketbase.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String authorName;
  final String authorImageUrl;
  final List<String> ingredients;
  final List<String> steps;
 
  final int times;
  final int servings;
  final String difficulty;
  final List<String> categories;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl = 'https://placehold.co/600x400?text=No+Image',
    required this.authorName,
    required this.authorImageUrl,
    required this.ingredients,
    required this.steps,
    required this.times,
    
    required this.servings,
    required this.difficulty,
    required this.categories,
    this.isFavorite = false,
  });

  factory Recipe.fromRecord(RecordModel record) {
    final data = record.data;

    String categoryName = 'Uncategorized';
    final categoryRecords = record.get<List<RecordModel>>('expand.category_id');
    if (categoryRecords.isNotEmpty) {
      categoryName = categoryRecords.first.getStringValue('name');
    }

    // Mengambil data pembuat resep (author)
    String authorName = 'Unknown Author';
    String authorImageUrl = 'https://placehold.co/100?text=?';
    final userRecords = record.get<List<RecordModel>>('expand.user_id');
    if (userRecords.isNotEmpty) {
      final userRecord = userRecords.first;
      authorName = userRecord.getStringValue('username');
      final profileImageName = userRecord.getStringValue('profileImage');
      if (profileImageName.isNotEmpty) {
        authorImageUrl = PocketBaseClient.instance.files.getUrl(userRecord, profileImageName).toString();
      }
    }
    
    // Membuat URL untuk gambar resep
    String imageUrl;
    if (data['image'] != null && data['image'].isNotEmpty) {
      imageUrl = PocketBaseClient.instance.files.getUrl(record, data['image']).toString();
    } else {
      imageUrl = 'https://placehold.co/600x400?text=No+Image';
    }

    // Membersihkan tag HTML dari deskripsi
    String description = data['description'] ?? 'No Description';
    final RegExp htmlTags = RegExp(r'<[^>]*>');
    description = description.replaceAll(htmlTags, '').replaceAll('&nbsp;', ' ').trim();

    return Recipe(
      id: record.id,
      name: data['name'] ?? 'No name',
      description: description,
      imageUrl: imageUrl, 
      authorName: authorName,
      authorImageUrl: authorImageUrl,
      difficulty: data['difficulty'] ?? 'Unknown',
      categories: [categoryName],
      times: (data['times'] ?? 0).toInt(),
     
      servings: 4, 
      ingredients: [], 
      steps: [], 
    );
  }
}
