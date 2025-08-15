import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/time_entry.dart';
import '../models/daily_summary.dart';
import '../models/task.dart';
import '../models/diary_entry.dart';
import '../services/file_service.dart';
import '../services/calendar_service.dart';
import '../services/config_service.dart';

class AppProvider extends ChangeNotifier {
  final ConfigService _configService;
  final FileService _fileService;
  final CalendarService _calendarService;
  final Uuid _uuid = Uuid();

  // Current state
  DateTime _selectedDate = DateTime.now();
  List<TimeEntry> _timeEntries = [];
  DailySummary? _currentDailySummary;
  List<Task> _tasks = [];
  List<DiaryEntry> _diaryEntries = [];

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  AppProvider({
    required ConfigService configService,
    required FileService fileService,
    required CalendarService calendarService,
  }) : _configService = configService,
       _fileService = fileService,
       _calendarService = calendarService {
    _loadInitialData();
  }

  // Getters
  DateTime get selectedDate => _selectedDate;
  List<TimeEntry> get timeEntries => _timeEntries;
  DailySummary? get currentDailySummary => _currentDailySummary;
  List<Task> get tasks => _tasks;
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get dataDirectoryPath => _fileService.dataDirectoryPath;
  ConfigService get configService => _configService;

  // Set selected date and reload data
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await _loadDataForDate(date);
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    _setLoading(true);
    try {
      await _loadDataForDate(_selectedDate);
      await _loadAllTasks();
      _clearError();
    } catch (e) {
      _setError('Failed to load initial data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load data for a specific date
  Future<void> _loadDataForDate(DateTime date) async {
    try {
      _timeEntries = await _fileService.loadTimeEntries(date);
      _currentDailySummary = await _fileService.loadDailySummary(date);
      _diaryEntries = await _fileService.loadDiaryEntries(date);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load data for ${date.toIso8601String()}: $e');
    }
  }

  // Load all tasks
  Future<void> _loadAllTasks() async {
    try {
      _tasks = await _fileService.loadAllTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    }
  }

  // Time Entry Management
  Future<void> addTimeEntry({
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    required String description,
    required String category,
  }) async {
    try {
      final entry = TimeEntry(
        id: _uuid.v4(),
        date: _selectedDate,
        type: type,
        startTime: startTime,
        endTime: endTime,
        description: description,
        category: category,
        duration: endTime.difference(startTime),
      );

      await _fileService.saveTimeEntry(entry);
      _timeEntries.add(entry);
      
      // Update daily summary
      await _updateDailySummary();
      
      // Add to calendar if enabled
      await _calendarService.addTimeEntryToCalendar(entry);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add time entry: $e');
    }
  }

  Future<void> updateTimeEntry(TimeEntry entry) async {
    try {
      await _fileService.saveTimeEntry(entry);
      final index = _timeEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _timeEntries[index] = entry;
        await _updateDailySummary();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update time entry: $e');
    }
  }

  Future<void> deleteTimeEntry(String entryId) async {
    try {
      _timeEntries.removeWhere((e) => e.id == entryId);
      
      // Remove from calendar
      await _calendarService.removeEventFromCalendar(entryId);
      
      await _updateDailySummary();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete time entry: $e');
    }
  }

  // Task Management
  Future<void> addTask({
    required String title,
    required String description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? project,
    List<String> tags = const [],
  }) async {
    try {
      final task = Task(
        id: _uuid.v4(),
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        project: project,
        tags: tags,
        createdAt: DateTime.now(),
      );

      await _fileService.saveTask(task);
      _tasks.add(task);
      
      // Add to calendar if has due date
      if (dueDate != null) {
        await _calendarService.addTaskToCalendar(task);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _fileService.saveTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _fileService.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      
      // Remove from calendar
      await _calendarService.removeEventFromCalendar(taskId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete task: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _tasks[index].copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await updateTask(task);
      }
    } catch (e) {
      _setError('Failed to complete task: $e');
    }
  }

  // Diary Management
  Future<void> addDiaryEntry({
    required String title,
    required String content,
    required DiaryEntryType type,
    List<String> tags = const [],
  }) async {
    try {
      final entry = DiaryEntry(
        id: _uuid.v4(),
        date: _selectedDate,
        title: title,
        content: content,
        type: type,
        tags: tags,
        createdAt: DateTime.now(),
      );

      await _fileService.saveDiaryEntry(entry);
      _diaryEntries.add(entry);
      
      if (type == DiaryEntryType.monthly) {
        await _fileService.saveMonthlyMemo(entry);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add diary entry: $e');
    }
  }

  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    try {
      await _fileService.saveDiaryEntry(entry);
      final index = _diaryEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _diaryEntries[index] = entry;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update diary entry: $e');
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    try {
      await _fileService.deleteDiaryEntry(id);
      _diaryEntries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete diary entry: $e');
    }
  }

  // Daily Summary Management
  Future<void> _updateDailySummary() async {
    try {
      // Calculate totals from time entries
      Duration idle = Duration.zero;
      Duration study = Duration.zero;
      Duration work = Duration.zero;
      Duration quotidian = Duration.zero;
      Duration family = Duration.zero;
      Duration unknown = Duration.zero;

      for (final entry in _timeEntries) {
        switch (entry.category.toLowerCase()) {
          case 'idle':
            idle += entry.duration;
            break;
          case 'study':
            study += entry.duration;
            break;
          case 'work':
            work += entry.duration;
            break;
          case 'quotidian':
            quotidian += entry.duration;
            break;
          case 'family':
            family += entry.duration;
            break;
          default:
            unknown += entry.duration;
            break;
        }
      }

      final total = idle + study + work + quotidian + family + unknown;

      final summary = DailySummary(
        id: _currentDailySummary?.id ?? _uuid.v4(),
        date: _selectedDate,
        idle: idle,
        study: study,
        work: work,
        quotidian: quotidian,
        family: family,
        unknown: unknown,
        total: total,
      );

      await _fileService.saveDailySummary(summary);
      _currentDailySummary = summary;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update daily summary: $e');
    }
  }

  // Settings
  Future<void> setDataDirectory(String path) async {
    try {
      await _fileService.setDataDirectory(path);
      // Reload all data from the new directory
      await _loadInitialData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set data directory: $e');
    }
  }
  
  Future<void> reloadDataDirectory() async {
    try {
      await _fileService.reloadDataDirectory();
      await _loadInitialData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reload data directory: $e');
    }
  }

  // Export functionality
  Future<void> exportData(String exportPath) async {
    try {
      await _fileService.exportData(exportPath);
      await _calendarService.exportICalFiles(_timeEntries, _tasks, exportPath);
    } catch (e) {
      _setError('Failed to export data: $e');
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadDataForDate(_selectedDate);
    await _loadAllTasks();
  }
}
