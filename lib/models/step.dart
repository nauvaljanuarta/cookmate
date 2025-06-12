import 'package:pocketbase/pocketbase.dart';

class Step {
  final int number;
  final String description;

  Step({
    required this.number,
    required this.description,
  });

  factory Step.fromRecord(RecordModel record) {
    return Step(
      number: record.data['number'] ?? 0,
      description: record.data['description'] ?? '',
    );
  }
}
