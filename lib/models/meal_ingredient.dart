import 'package:pocketbase/pocketbase.dart';

class MealIngredient {
  final String name;
  final num quantity;
  final String unit;

  MealIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory MealIngredient.fromRecord(RecordModel record) {
    final ingredientRecord = (record.expand['ingredient_id'] ?? []).isNotEmpty
        ? record.expand['ingredient_id']!.first
        : null;

    return MealIngredient(
      name: ingredientRecord?.data['name'] ?? 'Unknown Ingredient',
      quantity: record.data['quantity'] ?? 0,
      unit: record.data['unit'] ?? '',
    );
  }

  String get formatted {
    final quantityString = quantity > 0
        ? (quantity.truncateToDouble() == quantity
            ? quantity.toInt().toString()
            : quantity.toString())
        : '';

    return '$quantityString $unit $name'.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
