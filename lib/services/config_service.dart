import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'file_service.dart';

class TimeEntryCategory {
  final String id;
  final String name;
  final String color;
  final String icon;
  final bool isDefault;

  const TimeEntryCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
  });

  factory TimeEntryCategory.fromJson(Map<String, dynamic> json) {
    return TimeEntryCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  factory TimeEntryCategory.fromExcelRow(Map<String, String> excelRow) {
    return TimeEntryCategory(
      id: excelRow['name']?.toLowerCase().replaceAll(' ', '_') ?? 'unknown',
      name: excelRow['name'] ?? 'Unknown',
      color: excelRow['color'] ?? '#2196F3',
      icon: excelRow['icon'] ?? 'category',
      isDefault: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
    };
  }

  Map<String, String> toExcelRow() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
    };
  }

  TimeEntryCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
  }) {
    return TimeEntryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final List<String> tags;
  final String color;
  final String icon;
  final bool isCompleted;

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.tags,
    required this.color,
    required this.icon,
    this.isCompleted = false,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      tags: List<String>.from(json['tags'] as List),
      color: json['color'] as String,
      icon: json['icon'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'tags': tags,
      'color': color,
      'icon': icon,
      'isCompleted': isCompleted,
    };
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? tags,
    String? color,
    String? icon,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class AppConfig {
  final String? dataDirectory;
  final ThemeMode themeMode;
  final List<TimeEntryCategory> categories;
  final List<Goal> goals;
  final bool autoSyncCalendar;
  final bool createICalFiles;

  const AppConfig({
    this.dataDirectory,
    this.themeMode = ThemeMode.system,
    this.categories = const [],
    this.goals = const [],
    this.autoSyncCalendar = true,
    this.createICalFiles = true,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      dataDirectory: json['dataDirectory'] as String?,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => TimeEntryCategory.fromJson(e as Map<String, dynamic>))
          .toList() ?? _getDefaultCategories(),
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      autoSyncCalendar: json['autoSyncCalendar'] as bool? ?? true,
      createICalFiles: json['createICalFiles'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataDirectory': dataDirectory,
      'themeMode': themeMode.name,
      'categories': categories.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'autoSyncCalendar': autoSyncCalendar,
      'createICalFiles': createICalFiles,
    };
  }

  AppConfig copyWith({
    String? dataDirectory,
    ThemeMode? themeMode,
    List<TimeEntryCategory>? categories,
    List<Goal>? goals,
    bool? autoSyncCalendar,
    bool? createICalFiles,
  }) {
    return AppConfig(
      dataDirectory: dataDirectory ?? this.dataDirectory,
      themeMode: themeMode ?? this.themeMode,
      categories: categories ?? this.categories,
      goals: goals ?? this.goals,
      autoSyncCalendar: autoSyncCalendar ?? this.autoSyncCalendar,
      createICalFiles: createICalFiles ?? this.createICalFiles,
    );
  }

  static List<TimeEntryCategory> _getDefaultCategories() {
    return [
      const TimeEntryCategory(
        id: 'work',
        name: 'Work',
        color: '#FF6B6B',
        icon: 'work',
        isDefault: true,
      ),
      const TimeEntryCategory(
        id: 'study',
        name: 'Study',
        color: '#4ECDC4',
        icon: 'school',
        isDefault: true,
      ),
      const TimeEntryCategory(
        id: 'family',
        name: 'Family',
        color: '#45B7D1',
        icon: 'family_restroom',
        isDefault: true,
      ),
      const TimeEntryCategory(
        id: 'quotidian',
        name: 'Quotidian',
        color: '#96CEB4',
        icon: 'home',
        isDefault: true,
      ),
      const TimeEntryCategory(
        id: 'idle',
        name: 'Idle',
        color: '#FFEAA7',
        icon: 'hourglass_empty',
        isDefault: true,
      ),
    ];
  }
}

class ConfigService extends ChangeNotifier {
  static const String _configFileName = 'timeguru.json';
  AppConfig _config = const AppConfig();
  FileService? _fileService;
  bool _isInitialized = false;
  
  // Separate lists for default and year-specific data
  List<TimeEntryCategory> _defaultCategories = [];
  List<Goal> _defaultGoals = [];
  List<TimeEntryCategory> _yearCategories = [];
  List<Goal> _yearGoals = [];

  // Getters
  bool get isInitialized => _isInitialized;
  String? get dataDirectory => _config.dataDirectory;
  ThemeMode get themeMode => _config.themeMode;
  bool get autoSyncCalendar => _config.autoSyncCalendar;
  bool get createICalFiles => _config.createICalFiles;
  
  // Get default categories and goals (from JSON config)
  List<TimeEntryCategory> get defaultCategories => _defaultCategories;
  List<Goal> get defaultGoals => _defaultGoals;
  
  // Get year-specific categories and goals (from Excel files)
  List<TimeEntryCategory> get yearCategories => _yearCategories;
  List<Goal> get yearGoals => _yearGoals;
  
  // For backward compatibility, return year-specific data as the main categories/goals
  List<TimeEntryCategory> get categories => _yearCategories;
  List<Goal> get goals => _yearGoals;
  
  // Get year-specific categories and goals
  List<TimeEntryCategory> getYearCategories(int year) {
    // This will be loaded from Excel files
    return [];
  }
  
  List<Goal> getYearGoals(int year) {
    // This will be loaded from Excel files
    return [];
  }

  // Load year-specific data (categories and goals) from Excel
  Future<void> loadYearData(int year) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      
      // Load year-specific categories and goals
      final yearCategories = await _fileService!.loadYearCategories(year);
      final yearGoals = await _fileService!.loadYearGoals(year);
      
      _yearCategories = yearCategories;
      _yearGoals = yearGoals;
      
      notifyListeners();
      debugPrint('ConfigService: Loaded year $year data - ${yearCategories.length} categories, ${yearGoals.length} goals');
    } catch (e) {
      debugPrint('ConfigService: Failed to load year $year data: $e');
      // If loading fails, create the year file with default data
      await createYearFile(year);
      
      // After creating, try to load again
      try {
        final yearCategories = await _fileService!.loadYearCategories(year);
        final yearGoals = await _fileService!.loadYearGoals(year);
        
        _yearCategories = yearCategories;
        _yearGoals = yearGoals;
        
        notifyListeners();
        debugPrint('ConfigService: Loaded year $year data after creation - ${yearCategories.length} categories, ${yearGoals.length} goals');
      } catch (e2) {
        debugPrint('ConfigService: Failed to load year $year data after creation: $e2');
      }
    }
  }

  // Create a new year file with default categories and goals
  Future<void> createYearFile(int year) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Use default categories and goals as templates
      await _fileService!.createYearFile(year, _defaultCategories, _defaultGoals);
      debugPrint('ConfigService: Created year $year file with ${_defaultCategories.length} default categories and ${_defaultGoals.length} default goals');
    } catch (e) {
      debugPrint('ConfigService: Failed to create year $year file: $e');
    }
  }

  // Save year-specific categories
  Future<void> saveYearCategories(int year, List<TimeEntryCategory> categories) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      await _fileService!.saveYearCategories(year, categories);
      debugPrint('ConfigService: Saved ${categories.length} categories for year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to save categories for year $year: $e');
    }
  }

  // Save year-specific goals
  Future<void> saveYearGoals(int year, List<Goal> goals) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      await _fileService!.saveYearGoals(year, goals);
      debugPrint('ConfigService: Saved ${goals.length} goals for year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to save goals for year $year: $e');
    }
  }

  void setFileService(FileService fileService) {
    _fileService = fileService;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConfig();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ConfigService: Failed to initialize: $e');
      // Use default config if loading fails
      _config = const AppConfig();
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadConfig() async {
    final configFile = await _getConfigFile();
    
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _config = AppConfig.fromJson(json);
      
      // Load default categories and goals from config
      _defaultCategories = List<TimeEntryCategory>.from(_config.categories);
      _defaultGoals = List<Goal>.from(_config.goals);
      
      debugPrint('ConfigService: Loaded ${_defaultCategories.length} default categories and ${_defaultGoals.length} default goals from config');
    } else {
      // Create default config
      _config = const AppConfig();
      _defaultCategories = List<TimeEntryCategory>.from(_config.categories);
      _defaultGoals = List<Goal>.from(_config.goals);
      await _saveConfig();
      debugPrint('ConfigService: Created default config with ${_defaultCategories.length} categories and ${_defaultGoals.length} goals');
    }
  }

  Future<void> _saveConfig() async {
    try {
      final configFile = await _getConfigFile();
      final json = _config.toJson();
      final content = jsonEncode(json);
      await configFile.writeAsString(content);
      debugPrint('ConfigService: Successfully saved config to ${configFile.path}');
      debugPrint('ConfigService: Config contains ${_config.categories.length} categories and ${_config.goals.length} goals');
    } catch (e) {
      debugPrint('ConfigService: Failed to save config: $e');
      rethrow;
    }
  }

  Future<File> _getConfigFile() async {
    final configDir = Directory('${Platform.environment['HOME']}/.config');
    debugPrint('ConfigService: Config directory path: ${configDir.path}');
    
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
      debugPrint('ConfigService: Created config directory');
    }
    
    final configFile = File('${configDir.path}/$_configFileName');
    debugPrint('ConfigService: Config file path: ${configFile.path}');
    debugPrint('ConfigService: Config file exists: ${await configFile.exists()}');
    
    return configFile;
  }

  Future<void> setDataDirectory(String directory) async {
    _config = _config.copyWith(dataDirectory: directory);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    debugPrint('ConfigService: Setting theme mode to ${mode.name}');
    _config = _config.copyWith(themeMode: mode);
    await _saveConfig();
    debugPrint('ConfigService: Theme mode saved, notifying listeners');
    notifyListeners();
    debugPrint('ConfigService: Listeners notified for theme change');
  }

  Future<void> saveCategoriesToExcel(int year) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      final excelCategories = _config.categories.map((category) => 
        category.toExcelRow()
      ).toList();

      await _fileService!.saveCategories(year, excelCategories);
      debugPrint('ConfigService: Saved ${excelCategories.length} categories to Excel');
    } catch (e) {
      debugPrint('ConfigService: Failed to save categories to Excel: $e');
    }
  }

  Future<void> addCategory(TimeEntryCategory category) async {
    debugPrint('ConfigService: Adding category "${category.name}" with ID ${category.id}');
    debugPrint('ConfigService: Current default categories count: ${_defaultCategories.length}');
    
    final newCategories = List<TimeEntryCategory>.from(_defaultCategories);
    newCategories.add(category);
    debugPrint('ConfigService: New default categories count: ${newCategories.length}');
    
    _defaultCategories = newCategories;
    _config = _config.copyWith(categories: newCategories);
    debugPrint('ConfigService: Updated config, default categories count: ${_defaultCategories.length}');
    
    // Save to config file only (these are default categories)
    debugPrint('ConfigService: About to save config to file...');
    await _saveConfig();
    debugPrint('ConfigService: Config saved successfully');
    
    notifyListeners();
    debugPrint('ConfigService: Notified listeners');
  }

  Future<void> updateCategory(TimeEntryCategory category) async {
    final newCategories = _defaultCategories.map((c) {
      return c.id == category.id ? category : c;
    }).toList();
    
    _defaultCategories = newCategories;
    _config = _config.copyWith(categories: newCategories);
    
    // Save to config file only (these are default categories)
    await _saveConfig();
    notifyListeners();
  }

  Future<void> removeCategory(String categoryId) async {
    final category = _defaultCategories.firstWhere((c) => c.id == categoryId);
    if (category.isDefault) {
      throw Exception('Cannot remove default categories');
    }
    
    final newCategories = _defaultCategories.where((c) => c.id != categoryId).toList();
    
    _defaultCategories = newCategories;
    _config = _config.copyWith(categories: newCategories);
    
    // Save to config file only (these are default categories)
    await _saveConfig();
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    debugPrint('ConfigService: Adding goal "${goal.title}" with ID ${goal.id}');
    debugPrint('ConfigService: Current default goals count: ${_defaultGoals.length}');
    
    final newGoals = List<Goal>.from(_defaultGoals);
    newGoals.add(goal);
    debugPrint('ConfigService: New default goals count: ${newGoals.length}');
    
    _defaultGoals = newGoals;
    _config = _config.copyWith(goals: newGoals);
    debugPrint('ConfigService: Updated config, default goals count: ${_defaultGoals.length}');
    
    debugPrint('ConfigService: About to save config to file...');
    await _saveConfig();
    debugPrint('ConfigService: Config saved successfully');
    
    notifyListeners();
    debugPrint('ConfigService: Notified listeners');
  }

  Future<void> updateGoal(Goal goal) async {
    final newGoals = _defaultGoals.map((g) {
      return g.id == goal.id ? goal : g;
    }).toList();
    
    _defaultGoals = newGoals;
    _config = _config.copyWith(goals: newGoals);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> removeGoal(String goalId) async {
    final newGoals = _defaultGoals.where((g) => g.id != goalId).toList();
    
    _defaultGoals = newGoals;
    _config = _config.copyWith(goals: newGoals);
    await _saveConfig();
    notifyListeners();
  }

  // Year-specific category and goal management
  Future<void> addYearCategory(int year, TimeEntryCategory category) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year categories
      final yearCategories = await _fileService!.loadYearCategories(year);
      yearCategories.add(category);
      
      // Save back to Excel
      await _fileService!.saveYearCategories(year, yearCategories);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(categories: yearCategories);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Added category "${category.name}" to year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to add category to year $year: $e');
    }
  }

  Future<void> updateYearCategory(int year, TimeEntryCategory category) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year categories
      final yearCategories = await _fileService!.loadYearCategories(year);
      final updatedCategories = yearCategories.map((c) {
        return c.id == category.id ? category : c;
      }).toList();
      
      // Save back to Excel
      await _fileService!.saveYearCategories(year, updatedCategories);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(categories: updatedCategories);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Updated category "${category.name}" in year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to update category in year $year: $e');
    }
  }

  Future<void> removeYearCategory(int year, String categoryId) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year categories
      final yearCategories = await _fileService!.loadYearCategories(year);
      final updatedCategories = yearCategories.where((c) => c.id != categoryId).toList();
      
      // Save back to Excel
      await _fileService!.saveYearCategories(year, updatedCategories);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(categories: updatedCategories);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Removed category from year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to remove category from year $year: $e');
    }
  }

  Future<void> addYearGoal(int year, Goal goal) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year goals
      final yearGoals = await _fileService!.loadYearGoals(year);
      yearGoals.add(goal);
      
      // Save back to Excel
      await _fileService!.saveYearGoals(year, yearGoals);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(goals: yearGoals);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Added goal "${goal.title}" to year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to add goal to year $year: $e');
    }
  }

  Future<void> updateYearGoal(int year, Goal goal) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year goals
      final yearGoals = await _fileService!.loadYearGoals(year);
      final updatedGoals = yearGoals.map((g) {
        return g.id == goal.id ? goal : g;
      }).toList();
      
      // Save back to Excel
      await _fileService!.saveYearGoals(year, updatedGoals);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(goals: updatedGoals);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Updated goal "${goal.title}" in year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to update goal in year $year: $e');
    }
  }

  Future<void> removeYearGoal(int year, String goalId) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      // Load current year goals
      final yearGoals = await _fileService!.loadYearGoals(year);
      final updatedGoals = yearGoals.where((g) => g.id != goalId).toList();
      
      // Save back to Excel
      await _fileService!.saveYearGoals(year, updatedGoals);
      
      // Update local config if this is the current year
      if (year == DateTime.now().year) {
        _config = _config.copyWith(goals: updatedGoals);
        notifyListeners();
      }
      
      debugPrint('ConfigService: Removed goal from year $year');
    } catch (e) {
      debugPrint('ConfigService: Failed to remove goal from year $year: $e');
    }
  }

  TimeEntryCategory? getCategoryById(String id) {
    try {
      return _config.categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Goal? getGoalById(String id) {
    try {
      return _config.goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TimeEntryCategory> getActiveCategories() {
    return _config.categories.where((c) => !c.isDefault || c.id != 'idle').toList();
  }
}
