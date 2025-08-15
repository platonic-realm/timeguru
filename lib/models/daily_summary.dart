import 'package:json_annotation/json_annotation.dart';

part 'daily_summary.g.dart';

@JsonSerializable()
class DailySummary {
  final String id;
  final DateTime date;
  final Duration idle;
  final Duration study;
  final Duration work;
  final Duration quotidian;
  final Duration family;
  final Duration unknown;
  final Duration total;

  DailySummary({
    required this.id,
    required this.date,
    required this.idle,
    required this.study,
    required this.work,
    required this.quotidian,
    required this.family,
    required this.unknown,
    required this.total,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => _$DailySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailySummaryToJson(this);

  DailySummary copyWith({
    String? id,
    DateTime? date,
    Duration? idle,
    Duration? study,
    Duration? work,
    Duration? quotidian,
    Duration? family,
    Duration? unknown,
    Duration? total,
  }) {
    return DailySummary(
      id: id ?? this.id,
      date: date ?? this.date,
      idle: idle ?? this.idle,
      study: study ?? this.study,
      work: work ?? this.work,
      quotidian: quotidian ?? this.quotidian,
      family: family ?? this.family,
      unknown: unknown ?? this.unknown,
      total: total ?? this.total,
    );
  }

  @override
  String toString() {
    return 'DailySummary(id: $id, date: $date, idle: $idle, study: $study, work: $work, quotidian: $quotidian, family: $family, unknown: $unknown, total: $total)';
  }
}
