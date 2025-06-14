import 'package:pocketbase/pocketbase.dart';

class Day {
  final String id;
  final String name;

  Day({
    required this.id,
    required this.name,
  });

  factory Day.fromRecord(RecordModel record) {
    return Day(
      id: record.id,
      name: record.data['name'] ?? 'Unknown Day',
    );
  }
}