import 'package:cookmate2/models/recipe.dart';
import 'package:pocketbase/pocketbase.dart';

class MealPlan {
  final String id;
  final String dayId;
  final String mealId;
  final String userId;
  final Recipe? meal; 

  MealPlan({
    required this.id,
    required this.dayId,
    required this.mealId,
    required this.userId,
    this.meal,
  });

  factory MealPlan.fromRecord(RecordModel record) {
    final mealDataList = record.expand['meal_id'];

    return MealPlan(
      id: record.id,
      dayId: record.data['day_id'],
      mealId: record.data['meal_id'],
      userId: record.data['user_id'],
      meal: (mealDataList is List && mealDataList!.isNotEmpty)
          ? Recipe.fromRecord(mealDataList.first)
          : null,
    );
  }
}