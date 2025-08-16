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
  static const String _configFileName = 'TimeGuru.json';
  AppConfig _config = const AppConfig();
  bool _isInitialized = false;
  FileService? _fileService;

  AppConfig get config => _config;
  bool get isInitialized => _isInitialized;
  String? get dataDirectory => _config.dataDirectory;
  ThemeMode get themeMode => _config.themeMode;
  List<TimeEntryCategory> get categories => _config.categories;
  List<Goal> get goals => _config.goals;

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
    } else {
      // Create default config
      _config = const AppConfig();
      await _saveConfig();
    }
  }

  Future<void> _saveConfig() async {
    final configFile = await _getConfigFile();
    final json = _config.toJson();
    final content = jsonEncode(json);
    await configFile.writeAsString(content);
  }

  Future<File> _getConfigFile() async {
    final configDir = Directory('${Platform.environment['HOME']}/.config');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return File('${configDir.path}/$_configFileName');
  }

  Future<void> setDataDirectory(String directory) async {
    _config = _config.copyWith(dataDirectory: directory);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _config = _config.copyWith(themeMode: mode);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> loadCategoriesFromExcel(int year) async {
    if (_fileService == null || _config.dataDirectory == null) return;

    try {
      final excelCategories = await _fileService!.loadCategories(year);
      final categories = excelCategories.map((excelRow) => 
        TimeEntryCategory.fromExcelRow(excelRow)
      ).toList();

      _config = _config.copyWith(categories: categories);
      notifyListeners();
      debugPrint('ConfigService: Loaded ${categories.length} categories from Excel');
    } catch (e) {
      debugPrint('ConfigService: Failed to load categories from Excel: $e');
    }
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
    final newCategories = List<TimeEntryCategory>.from(_config.categories);
    newCategories.add(category);
    _config = _config.copyWith(categories: newCategories);
    
    // Save to both config file and Excel
    await _saveConfig();
    if (_fileService != null && _config.dataDirectory != null) {
      await saveCategoriesToExcel(DateTime.now().year);
    }
    
    notifyListeners();
  }

  Future<void> updateCategory(TimeEntryCategory category) async {
    final newCategories = _config.categories.map((c) {
      return c.id == category.id ? category : c;
    }).toList();
    _config = _config.copyWith(categories: newCategories);
    
    // Save to both config file and Excel
    await _saveConfig();
    if (_fileService != null && _config.dataDirectory != null) {
      await saveCategoriesToExcel(DateTime.now().year);
    }
    
    notifyListeners();
  }

  Future<void> removeCategory(String categoryId) async {
    final category = _config.categories.firstWhere((c) => c.id == categoryId);
    if (category.isDefault) {
      throw Exception('Cannot remove default categories');
    }
    
    final newCategories = _config.categories.where((c) => c.id != categoryId).toList();
    _config = _config.copyWith(categories: newCategories);
    
    // Save to both config file and Excel
    await _saveConfig();
    if (_fileService != null && _config.dataDirectory != null) {
      await saveCategoriesToExcel(DateTime.now().year);
    }
    
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    final newGoals = List<Goal>.from(_config.goals);
    newGoals.add(goal);
    _config = _config.copyWith(goals: newGoals);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    final newGoals = _config.goals.map((g) {
      return g.id == goal.id ? goal : g;
    }).toList();
    _config = _config.copyWith(goals: newGoals);
    await _saveConfig();
    notifyListeners();
  }

  Future<void> removeGoal(String goalId) async {
    final newGoals = _config.goals.where((g) => g.id != goalId).toList();
    _config = _config.copyWith(goals: newGoals);
    await _saveConfig();
    notifyListeners();
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
