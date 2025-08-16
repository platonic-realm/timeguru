import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/time_entry.dart';
import '../models/task.dart';

class CalendarService {
  Future<void> initialize() async {
    // Simplified initialization - focus on iCal generation
    debugPrint('Calendar service initialized (iCal generation only)');
  }

  // Create iCal file for a time entry
  Future<String> createICalFile(TimeEntry entry) async {
    final buffer = StringBuffer();
    
    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//TimeGuru//Time Tracking//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    
    // Event
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${entry.id}');
    buffer.writeln('DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
    buffer.writeln('DTSTART:${entry.startTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
    buffer.writeln('DTEND:${entry.endTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
    buffer.writeln('SUMMARY:${entry.type} - ${entry.description}');
    buffer.writeln('DESCRIPTION:${entry.description}\\nCategory: ${entry.category}\\nDuration: ${_formatDuration(entry.duration)}');
    buffer.writeln('CATEGORIES:${entry.category}');
    buffer.writeln('END:VEVENT');
    
    // Calendar footer
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }

  // Create iCal file for a task
  Future<String> createTaskICalFile(Task task) async {
    if (task.dueDate == null) return '';
    
    final buffer = StringBuffer();
    
    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//TimeGuru//Task Management//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    
    // Event
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${task.id}');
    buffer.writeln('DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
    buffer.writeln('DTSTART:${task.dueDate!.toUtc().toIso8601String().split('T')[0]}');
    buffer.writeln('DTEND:${task.dueDate!.add(Duration(days: 1)).toUtc().toIso8601String().split('T')[0]}');
    buffer.writeln('SUMMARY:${task.title}');
    buffer.writeln('DESCRIPTION:${task.description}\\nPriority: ${task.priority.name}\\nStatus: ${task.status.name}');
    buffer.writeln('CATEGORIES:Task');
    if (task.project != null) {
      buffer.writeln('LOCATION:${task.project}');
    }
    buffer.writeln('END:VEVENT');
    
    // Calendar footer
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }

  // Simplified calendar integration methods
  Future<bool> addTimeEntryToCalendar(TimeEntry entry) async {
    // For now, just return success - focus on iCal generation
    debugPrint('Time entry would be added to calendar: ${entry.description}');
    return true;
  }

  Future<bool> addTaskToCalendar(Task task) async {
    // For now, just return success - focus on iCal generation
    debugPrint('Task would be added to calendar: ${task.title}');
    return true;
  }

  Future<bool> removeEventFromCalendar(String eventId) async {
    // For now, just return success - focus on iCal generation
    debugPrint('Event would be removed from calendar: $eventId');
    return true;
  }

  Future<bool> updateTimeEntryInCalendar(TimeEntry entry) async {
    // For now, just return success - focus on iCal generation
    debugPrint('Time entry would be updated in calendar: ${entry.description}');
    return true;
  }

  Future<bool> removeTimeEntryFromCalendar(String entryId) async {
    // For now, just return success - focus on iCal generation
    debugPrint('Time entry would be removed from calendar: $entryId');
    return true;
  }

  // Export iCal files to a directory
  Future<void> exportICalFiles(List<TimeEntry> timeEntries, List<Task> tasks, String exportPath) async {
    final exportDir = Directory(exportPath);
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }

    // Export time entries
    for (final entry in timeEntries) {
      final icalContent = await createICalFile(entry);
      final fileName = 'time_entry_${entry.id}.ics';
      final file = File(path.join(exportPath, fileName));
      await file.writeAsString(icalContent);
    }

    // Export tasks
    for (final task in tasks.where((t) => t.dueDate != null)) {
      final icalContent = await createTaskICalFile(task);
      if (icalContent.isNotEmpty) {
        final fileName = 'task_${task.id}.ics';
        final file = File(path.join(exportPath, fileName));
        await file.writeAsString(icalContent);
      }
    }

    // Create a combined calendar file
    final combinedCalendar = await _createCombinedCalendar(timeEntries, tasks);
    final combinedFile = File(path.join(exportPath, 'timeguru_combined.ics'));
    await combinedFile.writeAsString(combinedCalendar);
  }

  // Create a combined calendar with all events
  Future<String> _createCombinedCalendar(List<TimeEntry> timeEntries, List<Task> tasks) async {
    final buffer = StringBuffer();
    
    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//TimeGuru//Combined Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:TimeGuru Combined');
    buffer.writeln('X-WR-CALDESC:TimeGuru - Time tracking, tasks, and activities');
    
    // Add time entries
    for (final entry in timeEntries) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:time_${entry.id}');
      buffer.writeln('DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
      buffer.writeln('DTSTART:${entry.startTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
      buffer.writeln('DTEND:${entry.endTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
      buffer.writeln('SUMMARY:${entry.type} - ${entry.description}');
      buffer.writeln('DESCRIPTION:${entry.description}\\nCategory: ${entry.category}\\nDuration: ${_formatDuration(entry.duration)}');
      buffer.writeln('CATEGORIES:${entry.category}');
      buffer.writeln('END:VEVENT');
    }
    
    // Add tasks
    for (final task in tasks.where((t) => t.dueDate != null)) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:task_${task.id}');
      buffer.writeln('DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z');
      buffer.writeln('DTSTART:${task.dueDate!.toUtc().toIso8601String().split('T')[0]}');
      buffer.writeln('DTEND:${task.dueDate!.add(Duration(days: 1)).toUtc().toIso8601String().split('T')[0]}');
      buffer.writeln('SUMMARY:${task.title}');
      buffer.writeln('DESCRIPTION:${task.description}\\nPriority: ${task.priority.name}\\nStatus: ${task.status.name}');
      buffer.writeln('CATEGORIES:Task');
      if (task.project != null) {
        buffer.writeln('LOCATION:${task.project}');
      }
      buffer.writeln('END:VEVENT');
    }
    
    // Calendar footer
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Get calendar events for a specific date range
  Future<List<Map<String, dynamic>>> getCalendarEvents(DateTime start, DateTime end) async {
    // Simplified - return empty list for now
    debugPrint('Calendar events requested for ${start.toIso8601String()} to ${end.toIso8601String()}');
    return [];
  }
}
