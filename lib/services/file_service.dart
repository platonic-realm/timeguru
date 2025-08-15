import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/time_entry.dart';
import '../models/daily_summary.dart';
import '../models/task.dart';
import '../models/diary_entry.dart';
import 'config_service.dart';

class FileService {
  late Directory _dataDirectory;
  late Directory _timeEntriesDir;
  late Directory _dailySummariesDir;
  late Directory _tasksDir;
  late Directory _diaryDir;
  late Directory _monthlyDir;
  late Directory _memosDir;
  
  final ConfigService _configService;

  FileService(this._configService);

  Future<void> initialize() async {
    await _setupDataDirectory();
    await _createDirectoryStructure();
  }

  Future<void> _setupDataDirectory() async {
    String? customPath = _configService.dataDirectory;
    
    debugPrint('FileService: Checking for custom data directory path...');
    debugPrint('FileService: Custom path from config: $customPath');
    
    if (customPath != null && Directory(customPath).existsSync()) {
      debugPrint('FileService: Using custom directory: $customPath');
      _dataDirectory = Directory(customPath);
    } else {
      // Don't create default directory automatically - wait for user to configure
      debugPrint('FileService: No custom directory configured yet');
      throw Exception('Data directory not configured. Please set a data directory in settings first.');
    }
    
    debugPrint('FileService: Final data directory: ${_dataDirectory.path}');
  }

  Future<void> _createDirectoryStructure() async {
    _timeEntriesDir = Directory(path.join(_dataDirectory.path, 'time_entries'));
    _dailySummariesDir = Directory(path.join(_dataDirectory.path, 'daily_summaries'));
    _tasksDir = Directory(path.join(_dataDirectory.path, 'tasks'));
    _diaryDir = Directory(path.join(_dataDirectory.path, 'diary'));
    _monthlyDir = Directory(path.join(_dataDirectory.path, 'monthly'));
    _memosDir = Directory(path.join(_dataDirectory.path, 'memos'));

    // Create directories if they don't exist
    await _timeEntriesDir.create(recursive: true);
    await _dailySummariesDir.create(recursive: true);
    await _tasksDir.create(recursive: true);
    await _diaryDir.create(recursive: true);
    await _monthlyDir.create(recursive: true);
    await _memosDir.create(recursive: true);
  }

  Future<void> setDataDirectory(String path) async {
    final newDir = Directory(path);
    if (!newDir.existsSync()) {
      await newDir.create(recursive: true);
    }
    
    await _configService.setDataDirectory(path);
    
    _dataDirectory = newDir;
    await _createDirectoryStructure();
  }

  String get dataDirectoryPath => _dataDirectory.path;
  
  Future<void> reloadDataDirectory() async {
    await _setupDataDirectory();
    await _createDirectoryStructure();
  }
  
  String? getConfiguredDataDirectory() {
    return _configService.dataDirectory;
  }
  
  bool isUsingConfiguredDirectory() {
    final configuredPath = _configService.dataDirectory;
    return configuredPath != null && configuredPath == _dataDirectory.path;
  }

  // Time Entries
  Future<void> saveTimeEntry(TimeEntry entry) async {
    final fileName = '${entry.date.toIso8601String().split('T')[0]}_${entry.id}.json';
    final file = File(path.join(_timeEntriesDir.path, fileName));
    await file.writeAsString(jsonEncode(entry.toJson()));
  }

  Future<List<TimeEntry>> loadTimeEntries(DateTime date) async {
    final files = _timeEntriesDir.listSync().whereType<File>().where((file) {
      return path.basename(file.path).startsWith(date.toIso8601String().split('T')[0]);
    });

    final entries = <TimeEntry>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        entries.add(TimeEntry.fromJson(json));
      } catch (e) {
        debugPrint('Error loading time entry from ${file.path}: $e');
      }
    }

    return entries;
  }

  // Daily Summaries
  Future<void> saveDailySummary(DailySummary summary) async {
    final fileName = '${summary.date.toIso8601String().split('T')[0]}.json';
    final file = File(path.join(_dailySummariesDir.path, fileName));
    await file.writeAsString(jsonEncode(summary.toJson()));
  }

  Future<DailySummary?> loadDailySummary(DateTime date) async {
    final fileName = '${date.toIso8601String().split('T')[0]}.json';
    final file = File(path.join(_dailySummariesDir.path, fileName));
    
    if (!file.existsSync()) return null;
    
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      return DailySummary.fromJson(json);
    } catch (e) {
      debugPrint('Error loading daily summary from ${file.path}: $e');
      return null;
    }
  }

  // Tasks
  Future<void> saveTask(Task task) async {
    final fileName = '${task.id}.json';
    final file = File(path.join(_tasksDir.path, fileName));
    await file.writeAsString(jsonEncode(task.toJson()));
  }

  Future<List<Task>> loadAllTasks() async {
    final files = _tasksDir.listSync().whereType<File>().where((file) {
      return path.extension(file.path) == '.json';
    });

    final tasks = <Task>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        tasks.add(Task.fromJson(json));
      } catch (e) {
        debugPrint('Error loading task from ${file.path}: $e');
      }
    }

    return tasks;
  }

  Future<void> deleteTask(String taskId) async {
    final fileName = '$taskId.json';
    final file = File(path.join(_tasksDir.path, fileName));
    if (file.existsSync()) {
      await file.delete();
    }
  }

  // Diary Entries
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    // Save as JSON for app use
    final jsonFileName = '${entry.id}.json';
    final jsonFile = File(path.join(_diaryDir.path, jsonFileName));
    await jsonFile.writeAsString(jsonEncode(entry.toJson()));

    // Save as Markdown for Obsidian
    final markdownFileName = '${entry.date.toIso8601String().split('T')[0]}_${entry.type.name}.md';
    final markdownFile = File(path.join(_diaryDir.path, markdownFileName));
    await markdownFile.writeAsString(entry.markdownContent);
  }

  Future<List<DiaryEntry>> loadDiaryEntries(DateTime date) async {
    final files = _diaryDir.listSync().whereType<File>().where((file) {
      return path.basename(file.path).startsWith(date.toIso8601String().split('T')[0]) &&
             path.extension(file.path) == '.json';
    });

    final entries = <DiaryEntry>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        entries.add(DiaryEntry.fromJson(json));
      } catch (e) {
        debugPrint('Error loading diary entry from ${file.path}: $e');
      }
    }

    return entries;
  }

  Future<void> deleteDiaryEntry(String id) async {
    // Find and delete the JSON file
    final files = _diaryDir.listSync().whereType<File>().where((file) {
      return path.basename(file.path).startsWith('$id.') &&
             path.extension(file.path) == '.json';
    });

    for (final file in files) {
      await file.delete();
    }

    // Also try to delete the markdown file if it exists
    final markdownFiles = _diaryDir.listSync().whereType<File>().where((file) {
      return path.basename(file.path).contains(id) &&
             path.extension(file.path) == '.md';
    });

    for (final file in markdownFiles) {
      await file.delete();
    }
  }

  // Monthly Memos
  Future<void> saveMonthlyMemo(DiaryEntry memo) async {
    if (memo.type != DiaryEntryType.monthly) {
      throw ArgumentError('Entry must be of type monthly');
    }

    final fileName = '${memo.date.year}_${memo.date.month.toString().padLeft(2, '0')}.md';
    final file = File(path.join(_monthlyDir.path, fileName));
    await file.writeAsString(memo.markdownContent);
  }

  Future<DiaryEntry?> loadMonthlyMemo(int year, int month) async {
    final fileName = '${year}_${month.toString().padLeft(2, '0')}.md';
    final file = File(path.join(_monthlyDir.path, fileName));
    
    if (!file.existsSync()) return null;
    
    try {
      final content = await file.readAsString();
      // Parse markdown content back to DiaryEntry
      // This is a simplified parser - you might want to use a proper markdown parser
      final lines = content.split('\n');
      final frontmatter = <String, String>{};
      int contentStart = 0;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i] == '---') {
          if (contentStart == 0) {
            contentStart = i + 1;
          } else {
            break;
          }
        } else if (contentStart > 0 && lines[i].contains(':')) {
          final parts = lines[i].split(':');
          if (parts.length >= 2) {
            frontmatter[parts[0].trim()] = parts[1].trim();
          }
        }
      }
      
      final title = lines[contentStart + 1].replaceFirst('# ', '');
      final diaryContent = lines.skip(contentStart + 2).join('\n');
      
      return DiaryEntry(
        id: frontmatter['id'] ?? '',
        date: DateTime.parse(frontmatter['date'] ?? ''),
        title: title,
        content: diaryContent,
        type: DiaryEntryType.monthly,
        tags: frontmatter['tags']?.replaceAll('[', '').replaceAll(']', '').split(', ').map((t) => t.trim()).toList() ?? [],
        createdAt: DateTime.parse(frontmatter['created'] ?? ''),
        updatedAt: frontmatter['updated'] != null ? DateTime.parse(frontmatter['updated']!) : null,
      );
    } catch (e) {
      debugPrint('Error loading monthly memo from ${file.path}: $e');
      return null;
    }
  }

  // Export data for backup
  Future<void> exportData(String exportPath) async {
    final exportDir = Directory(exportPath);
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }

    // Copy all data directories
    await _copyDirectory(_timeEntriesDir, Directory(path.join(exportPath, 'time_entries')));
    await _copyDirectory(_dailySummariesDir, Directory(path.join(exportPath, 'daily_summaries')));
    await _copyDirectory(_tasksDir, Directory(path.join(exportPath, 'tasks')));
    await _copyDirectory(_diaryDir, Directory(path.join(exportPath, 'diary')));
    await _copyDirectory(_monthlyDir, Directory(path.join(exportPath, 'monthly')));
    await _copyDirectory(_memosDir, Directory(path.join(exportPath, 'memos')));
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      await destination.create(recursive: true);
    }

    final files = source.listSync().whereType<File>();
    for (final file in files) {
      final fileName = path.basename(file.path);
      final destFile = File(path.join(destination.path, fileName));
      await file.copy(destFile.path);
    }
  }
}
