import 'package:json_annotation/json_annotation.dart';

part 'monthly_file.g.dart';

@JsonSerializable()
class MonthlyFile {
  final int year;
  final int month;
  final MonthlyOverview overview;
  final List<MonthlyTask> tasks;
  final List<DailyEntry> dailyEntries;

  const MonthlyFile({
    required this.year,
    required this.month,
    required this.overview,
    required this.tasks,
    required this.dailyEntries,
  });

  factory MonthlyFile.fromJson(Map<String, dynamic> json) => _$MonthlyFileFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyFileToJson(this);

  String get fileName => '${month.toString().padLeft(2, '0')}.md';
  String get yearMonthKey => '${year}_${month.toString().padLeft(2, '0')}';

  String toMarkdown() {
    final monthName = _getMonthName(month);
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# $monthName $year\n');
    
    // Overview
    buffer.writeln('## Overview');
    buffer.writeln(overview.toMarkdown());
    buffer.writeln();
    
    // Tasks
    buffer.writeln('## Tasks');
    for (final task in tasks) {
      buffer.writeln(task.toMarkdown());
    }
    buffer.writeln();
    
    // Daily Entries
    buffer.writeln('## Daily Entries\n');
    for (final entry in dailyEntries) {
      buffer.writeln(entry.toMarkdown());
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

@JsonSerializable()
class MonthlyOverview {
  final int totalDays;
  final int completedTasks;
  final int totalTasks;
  final Duration studyHours;
  final Duration workHours;
  final Duration familyHours;
  final Duration quotidianHours;
  final Duration idleHours;

  const MonthlyOverview({
    required this.totalDays,
    required this.completedTasks,
    required this.totalTasks,
    required this.studyHours,
    required this.workHours,
    required this.familyHours,
    required this.quotidianHours,
    required this.idleHours,
  });

  factory MonthlyOverview.fromJson(Map<String, dynamic> json) => _$MonthlyOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyOverviewToJson(this);

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('- **Total Days**: $totalDays');
    buffer.writeln('- **Completed Tasks**: $completedTasks/$totalTasks');
    buffer.writeln('- **Study Hours**: ${_formatDuration(studyHours)}');
    buffer.writeln('- **Work Hours**: ${_formatDuration(workHours)}');
    buffer.writeln('- **Family Hours**: ${_formatDuration(familyHours)}');
    buffer.writeln('- **Quotidian Hours**: ${_formatDuration(quotidianHours)}');
    buffer.writeln('- **Idle Hours**: ${_formatDuration(idleHours)}');
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

@JsonSerializable()
class MonthlyTask {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? project;
  final String priority;

  const MonthlyTask({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    this.completedAt,
    this.project,
    required this.priority,
  });

  factory MonthlyTask.fromJson(Map<String, dynamic> json) => _$MonthlyTaskFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyTaskToJson(this);

  String toMarkdown() {
    final checkbox = isCompleted ? '[x]' : '[ ]';
    final projectTag = project != null ? ' #$project' : '';
    final priorityTag = priority != 'medium' ? ' #$priority' : '';
    
    return '$checkbox $title$projectTag$priorityTag';
  }
}

@JsonSerializable()
class DailyEntry {
  final DateTime date;
  final String content;
  final List<String> tags;

  const DailyEntry({
    required this.date,
    required this.content,
    required this.tags,
  });

  factory DailyEntry.fromJson(Map<String, dynamic> json) => _$DailyEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyEntryToJson(this);

  String toMarkdown() {
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    
    final buffer = StringBuffer();
    buffer.writeln('### $formattedDate - $dayOfWeek');
    
    // Split content by lines and format
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        if (line.startsWith('**') && line.endsWith('**:')) {
          // Section header (Morning, Afternoon, Evening, etc.)
          buffer.writeln(line);
        } else {
          // Regular content
          buffer.writeln(line);
        }
      }
    }
    
    // Add tags if any
    if (tags.isNotEmpty) {
      final tagString = tags.map((tag) => '#$tag').join(' ');
      buffer.writeln('\n$tagString');
    }
    
    return buffer.toString();
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
