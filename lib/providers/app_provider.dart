import 'package:flutter/foundation.dart';
import '../models/monthly_file.dart';
import '../models/time_entry.dart';
import '../services/file_service.dart';
import '../services/config_service.dart';
import '../services/calendar_service.dart';

class AppProvider extends ChangeNotifier {
  final FileService _fileService;
  final ConfigService _configService;
  final CalendarService _calendarService;

  // Current state
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  DateTime _selectedDate = DateTime.now(); // Global selected date
  MonthlyFile? _currentMonthlyFile;
  List<TimeEntry> _timeEntries = [];
  bool _isLoading = false;
  String? _error;

  AppProvider({
    required FileService fileService,
    required ConfigService configService,
    required CalendarService calendarService,
  }) : _fileService = fileService,
       _configService = configService,
       _calendarService = calendarService;

  // Getters
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  DateTime get selectedDate => _selectedDate;
  MonthlyFile? get currentMonthlyFile => _currentMonthlyFile;
  List<TimeEntry> get timeEntries => _timeEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available years and months
  List<int> get availableYears => _fileService.getAvailableYears();
  List<int> get availableMonths => _fileService.getAvailableMonths(_currentYear);

  // Initialize the provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _fileService.initialize();
      
      // Load current month
      await loadMonth(_currentYear, _currentMonth);
      
      // Load current year's time entries
      await loadTimeEntries(_currentYear);
      
      _setError(null);
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('NewAppProvider: Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load a specific month
  Future<void> loadMonth(int year, int month) async {
    try {
      _setLoading(true);
      _setError(null);
      
      _currentYear = year;
      _currentMonth = month;
      
      // Load monthly file
      _currentMonthlyFile = await _fileService.loadMonthlyFile(year, month);
      
      // If no monthly file exists, create a default one
      if (_currentMonthlyFile == null) {
        _currentMonthlyFile = _createDefaultMonthlyFile(year, month);
        await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load month: $e');
      debugPrint('NewAppProvider: Load month error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update the globally selected date
  Future<void> updateSelectedDate(DateTime newDate) async {
    if (_selectedDate.year != newDate.year || _selectedDate.month != newDate.month) {
      // Load the new month if it's different
      await loadMonth(newDate.year, newDate.month);
    }
    
    _selectedDate = newDate;
    notifyListeners();
  }

  // Go to today
  Future<void> goToToday() async {
    final today = DateTime.now();
    await updateSelectedDate(today);
  }

  // Go to specific date
  Future<void> goToDate(DateTime date) async {
    await updateSelectedDate(date);
  }

  // Load time entries for a specific year
  Future<void> loadTimeEntries(int year) async {
    try {
      _timeEntries = await _fileService.loadTimeEntries(year);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load time entries: $e');
      debugPrint('NewAppProvider: Load time entries error: $e');
    }
  }

  // Create a new monthly file
  MonthlyFile _createDefaultMonthlyFile(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    return MonthlyFile(
      year: year,
      month: month,
      overview: MonthlyOverview(
        totalDays: daysInMonth,
        completedTasks: 0,
        totalTasks: 0,
        studyHours: Duration.zero,
        workHours: Duration.zero,
        familyHours: Duration.zero,
        quotidianHours: Duration.zero,
        idleHours: Duration.zero,
      ),
      tasks: [],
      dailyEntries: [],
    );
  }

  // TASK MANAGEMENT
  
  Future<void> addTask(MonthlyTask task) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedTasks = List<MonthlyTask>.from(_currentMonthlyFile!.tasks);
      updatedTasks.add(task);
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: updatedTasks,
        dailyEntries: _currentMonthlyFile!.dailyEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      _updateOverview();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add task: $e');
      debugPrint('NewAppProvider: Add task error: $e');
    }
  }

  Future<void> updateTask(MonthlyTask updatedTask) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedTasks = _currentMonthlyFile!.tasks.map((task) {
        return task.id == updatedTask.id ? updatedTask : task;
      }).toList();
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: updatedTasks,
        dailyEntries: _currentMonthlyFile!.dailyEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      _updateOverview();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update task: $e');
      debugPrint('NewAppProvider: Update task error: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedTasks = _currentMonthlyFile!.tasks.where((task) => task.id != taskId).toList();
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: updatedTasks,
        dailyEntries: _currentMonthlyFile!.dailyEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      _updateOverview();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete task: $e');
      debugPrint('NewAppProvider: Delete task error: $e');
    }
  }

  // DAILY ENTRY MANAGEMENT
  
  Future<void> addDailyEntry(DailyEntry entry) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedEntries = List<DailyEntry>.from(_currentMonthlyFile!.dailyEntries);
      updatedEntries.add(entry);
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: _currentMonthlyFile!.tasks,
        dailyEntries: updatedEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add daily entry: $e');
      debugPrint('NewAppProvider: Add daily entry error: $e');
    }
  }

  Future<void> updateDailyEntry(DailyEntry updatedEntry) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedEntries = _currentMonthlyFile!.dailyEntries.map((entry) {
        return entry.date.isAtSameMomentAs(updatedEntry.date) ? updatedEntry : entry;
      }).toList();
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: _currentMonthlyFile!.tasks,
        dailyEntries: updatedEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update daily entry: $e');
      debugPrint('NewAppProvider: Update daily entry error: $e');
    }
  }

  Future<void> deleteDailyEntry(DateTime date) async {
    try {
      if (_currentMonthlyFile == null) return;
      
      final updatedEntries = _currentMonthlyFile!.dailyEntries
          .where((entry) => !entry.date.isAtSameMomentAs(date))
          .toList();
      
      _currentMonthlyFile = MonthlyFile(
        year: _currentMonthlyFile!.year,
        month: _currentMonthlyFile!.month,
        overview: _currentMonthlyFile!.overview,
        tasks: _currentMonthlyFile!.tasks,
        dailyEntries: updatedEntries,
      );
      
      await _fileService.saveMonthlyFile(_currentMonthlyFile!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete daily entry: $e');
      debugPrint('NewAppProvider: Delete daily entry error: $e');
    }
  }

  // TIME ENTRY MANAGEMENT
  
  Future<void> addTimeEntry(TimeEntry entry) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Add to local list
      _timeEntries.add(entry);
      
      // Save to file
      await _fileService.saveTimeEntries(_currentYear, _timeEntries);
      
      // Update calendar if enabled
      if (_configService.config.autoSyncCalendar) {
        await _calendarService.addTimeEntryToCalendar(entry);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add time entry: $e');
      debugPrint('AppProvider: Add time entry error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTimeEntry(TimeEntry entry) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Update in local list
      final index = _timeEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _timeEntries[index] = entry;
        
        // Save to file
        await _fileService.saveTimeEntries(_currentYear, _timeEntries);
        
        // Update calendar if enabled
        if (_configService.config.autoSyncCalendar) {
          await _calendarService.updateTimeEntryInCalendar(entry);
        }
        
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update time entry: $e');
      debugPrint('AppProvider: Update time entry error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTimeEntry(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Remove from local list
      _timeEntries.removeWhere((e) => e.id == id);
      
      // Save to file
      await _fileService.saveTimeEntries(_currentYear, _timeEntries);
      
      // Remove from calendar if enabled
      if (_configService.config.autoSyncCalendar) {
        await _calendarService.removeTimeEntryFromCalendar(id);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete time entry: $e');
      debugPrint('AppProvider: Delete time entry error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // OVERVIEW MANAGEMENT
  
  void _updateOverview() {
    if (_currentMonthlyFile == null) return;
    
    final totalTasks = _currentMonthlyFile!.tasks.length;
    final completedTasks = _currentMonthlyFile!.tasks.where((task) => task.isCompleted).length;
    
    // Calculate hours from time entries for current month
    final monthEntries = _timeEntries.where((entry) {
      return entry.date.year == _currentYear && entry.date.month == _currentMonth;
    }).toList();
    
    Duration studyHours = Duration.zero;
    Duration workHours = Duration.zero;
    Duration familyHours = Duration.zero;
    Duration quotidianHours = Duration.zero;
    Duration idleHours = Duration.zero;
    
    for (final entry in monthEntries) {
      switch (entry.category.toLowerCase()) {
        case 'study':
          studyHours += entry.duration;
          break;
        case 'work':
          workHours += entry.duration;
          break;
        case 'family':
          familyHours += entry.duration;
          break;
        case 'quotidian':
          quotidianHours += entry.duration;
          break;
        case 'idle':
          idleHours += entry.duration;
          break;
      }
    }
    
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    
    final updatedOverview = MonthlyOverview(
      totalDays: daysInMonth,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      studyHours: studyHours,
      workHours: workHours,
      familyHours: familyHours,
      quotidianHours: quotidianHours,
      idleHours: idleHours,
    );
    
    _currentMonthlyFile = MonthlyFile(
      year: _currentMonthlyFile!.year,
      month: _currentMonthlyFile!.month,
      overview: updatedOverview,
      tasks: _currentMonthlyFile!.tasks,
      dailyEntries: _currentMonthlyFile!.dailyEntries,
    );
  }

  // UTILITY METHODS
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  // Get daily entry for a specific date
  DailyEntry? getDailyEntry(DateTime date) {
    if (_currentMonthlyFile == null) return null;
    
    return _currentMonthlyFile!.dailyEntries.firstWhere(
      (entry) => entry.date.year == date.year && 
                  entry.date.month == date.month && 
                  entry.date.day == date.day,
      orElse: () => DailyEntry(
        date: date,
        content: '',
        tags: [],
      ),
    );
  }

  // Get tasks for a specific project
  List<MonthlyTask> getTasksByProject(String? project) {
    if (_currentMonthlyFile == null) return [];
    
    if (project == null) return _currentMonthlyFile!.tasks;
    
    return _currentMonthlyFile!.tasks.where((task) => task.project == project).toList();
  }

  // Get tasks by priority
  List<MonthlyTask> getTasksByPriority(String priority) {
    if (_currentMonthlyFile == null) return [];
    
    return _currentMonthlyFile!.tasks.where((task) => task.priority == priority).toList();
  }

  // SETTINGS METHODS
  
  ConfigService get configService => _configService;
  String get dataDirectoryPath => _fileService.dataDirectoryPath;
  
  Future<void> setDataDirectory(String path) async {
    try {
      await _fileService.initialize();
      // The FileService will use the config service to set the directory
      // This method is mainly for compatibility with the settings screen
    } catch (e) {
      _setError('Failed to set data directory: $e');
      debugPrint('AppProvider: Set data directory error: $e');
    }
  }
}
