import 'package:json_annotation/json_annotation.dart';

part 'time_entry.g.dart';

@JsonSerializable()
class TimeEntry {
  final String id;
  final DateTime date;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final String category;
  final Duration duration;

  TimeEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.category,
    required this.duration,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) => _$TimeEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TimeEntryToJson(this);

  TimeEntry copyWith({
    String? id,
    DateTime? date,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? category,
    Duration? duration,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'TimeEntry(id: $id, date: $date, type: $type, startTime: $startTime, endTime: $endTime, description: $description, category: $category, duration: $duration)';
  }
}
