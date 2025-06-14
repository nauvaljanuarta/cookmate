import 'dart:async';
import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/day.dart';
import 'package:cookmate2/models/meal_plan.dart';
import 'package:pocketbase/pocketbase.dart';

class MealPlanService {
  final PocketBase _pb = PocketBaseClient.instance;

  Future<List<Day>> getDays() async {
    try {
      final records = await _pb.collection('days').getFullList(sort: 'order');
      return records.map((record) => Day.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching days: $e');
      return [];
    }
  }

  Future<List<MealPlan>> getMealPlansForDay(String dayId) async {
    if (!_pb.authStore.isValid) return [];
    final userId = _pb.authStore.model.id;

    try {
      final records = await _pb.collection('meal_plans').getFullList(
            filter: 'user_id = "$userId" && day_id = "$dayId"',
            expand: 'meal_id.user_id, meal_id.category_id',
          );
      return records.map((record) => MealPlan.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching meal plans for day $dayId: $e');
      return [];
    }
  }

  Future<void> addMealPlan({required String mealId, required String dayId}) async {
    if (!_pb.authStore.isValid) throw Exception("User not authenticated.");
    final userId = _pb.authStore.model.id;

    final body = <String, dynamic>{
      "user_id": userId,
      "day_id": dayId,
      "meal_id": mealId,
    };

    try {
      await _pb.collection('meal_plans').getFirstListItem(
        'user_id = "$userId" && day_id = "$dayId" && meal_id = "$mealId"'
      );
      print('Meal plan already exists.');
    } on ClientException catch(e) {
      if (e.statusCode == 404) {
        try {
          await _pb.collection('meal_plans').create(body: body);
        } catch (e) {
          print('Error creating meal plan: $e');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _pb.collection('meal_plans').delete(mealPlanId);
    } catch (e) {
      print('Error deleting meal plan $mealPlanId: $e');
      rethrow;
    }
  }

  Future<bool> checkIfMealIsPlanned(String mealId) async {
    if (!_pb.authStore.isValid) return false;
    final userId = _pb.authStore.model.id;
    try {
      await _pb.collection('meal_plans').getFirstListItem(
            'user_id = "$userId" && meal_id = "$mealId"',
          );
      return true;
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }
}