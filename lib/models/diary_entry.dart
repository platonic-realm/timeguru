import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

@JsonSerializable()
class DiaryEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final DiaryEntryType type;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.type,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => _$DiaryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    DiaryEntryType? type,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get markdownContent {
    final buffer = StringBuffer();
    
    // Add frontmatter for Obsidian compatibility
    buffer.writeln('---');
    buffer.writeln('id: $id');
    buffer.writeln('date: ${date.toIso8601String()}');
    buffer.writeln('type: ${type.name}');
    if (tags.isNotEmpty) {
      buffer.writeln('tags: [${tags.join(', ')}]');
    }
    buffer.writeln('created: ${createdAt.toIso8601String()}');
    if (updatedAt != null) {
      buffer.writeln('updated: ${updatedAt!.toIso8601String()}');
    }
    buffer.writeln('---');
    buffer.writeln();
    
    // Add title
    buffer.writeln('# $title');
    buffer.writeln();
    
    // Add content
    buffer.writeln(content);
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, date: $date, title: $title, type: $type)';
  }
}

enum DiaryEntryType { daily, monthly, memo }
