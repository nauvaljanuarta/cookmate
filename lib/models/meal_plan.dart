import 'package:cookmate2/models/recipe.dart';
import 'package:pocketbase/pocketbase.dart';

class MealPlan {
  final String id;
  final String userId;
  final String dayId;
  final String mealId;
  final Map<String, dynamic> expand;

  MealPlan({
    required this.id,
    required this.userId,
    required this.dayId,
    required this.mealId,
    required this.expand,
  });

  // Helper untuk mendapatkan data resep dengan mudah
  Recipe? get meal {
    if (expand.containsKey('meal_id')) {
      final mealRecord = expand['meal_id'] as RecordModel;
      return Recipe.fromRecord(mealRecord);
    }
    return null;
  }

  factory MealPlan.fromRecord(RecordModel record) {
    return MealPlan(
      id: record.id,
      userId: record.data['user_id'],
      dayId: record.data['day_id'],
      mealId: record.data['meal_id'],
      expand: record.expand,
    );
  }
}
