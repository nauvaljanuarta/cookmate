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
    // Mengakses data dari 'expand' untuk mendapatkan nama bahan
    final ingredientRecord = (record.expand['ingredient_id'] ?? []).isNotEmpty
        ? record.expand['ingredient_id']!.first
        : null;

    return MealIngredient(
      name: ingredientRecord?.data['name'] ?? 'Unknown Ingredient',
      quantity: record.data['quantity'] ?? 0,
      unit: record.data['unit'] ?? '',
    );
  }

  // Getter untuk memformat tampilan bahan menjadi lebih rapi, contoh: "2 sdm Garam"
  String get formatted {
    // Hanya tampilkan jumlah jika lebih dari 0
    final quantityString = quantity > 0
        ? (quantity.truncateToDouble() == quantity
            ? quantity.toInt().toString()
            : quantity.toString())
        : '';

    // Menggabungkan semua bagian dan membersihkan spasi berlebih
    return '$quantityString $unit $name'.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
