import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import '../models/monthly_file.dart';
import '../models/time_entry.dart';
import 'config_service.dart';

class FileService {
  late Directory _dataDirectory;
  final ConfigService _configService;

  FileService(this._configService);

  Future<void> initialize() async {
    await _setupDataDirectory();
  }

  Future<void> _setupDataDirectory() async {
    String? customPath = _configService.dataDirectory;
    
    if (customPath != null && Directory(customPath).existsSync()) {
      _dataDirectory = Directory(customPath);
    } else {
      throw Exception('Data directory not configured. Please set a data directory in settings first.');
    }
  }

  // MARKDOWN FILES (Monthly overview + daily entries + tasks)
  
  Future<void> saveMonthlyFile(MonthlyFile monthlyFile) async {
    final yearDir = Directory(path.join(_dataDirectory.path, monthlyFile.year.toString()));
    if (!yearDir.existsSync()) {
      await yearDir.create(recursive: true);
    }
    
    final markdownFile = File(path.join(yearDir.path, monthlyFile.fileName));
    await markdownFile.writeAsString(monthlyFile.toMarkdown());
    
    debugPrint('FileService: Saved monthly file: ${markdownFile.path}');
  }

  Future<MonthlyFile?> loadMonthlyFile(int year, int month) async {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) return null;
    
    final markdownFile = File(path.join(yearDir.path, '${month.toString().padLeft(2, '0')}.md'));
    if (!markdownFile.existsSync()) return null;
    
    try {
      final content = await markdownFile.readAsString();
      return _parseMarkdownFile(year, month, content);
    } catch (e) {
      debugPrint('FileService: Error loading monthly file: $e');
      return null;
    }
  }

  MonthlyFile _parseMarkdownFile(int year, int month, String content) {
    // This is a simplified parser - in production you might want to use a proper markdown parser
    final lines = content.split('\n');
    
    final overview = _parseOverview(lines);
    final tasks = _parseTasks(lines);
    final dailyEntries = _parseDailyEntries(lines);
    
    return MonthlyFile(
      year: year,
      month: month,
      overview: overview,
      tasks: tasks,
      dailyEntries: dailyEntries,
    );
  }

  MonthlyOverview _parseOverview(List<String> lines) {
    // Default values
    return const MonthlyOverview(
      totalDays: 0,
      completedTasks: 0,
      totalTasks: 0,
      studyHours: Duration.zero,
      workHours: Duration.zero,
      familyHours: Duration.zero,
      quotidianHours: Duration.zero,
      idleHours: Duration.zero,
    );
  }

  List<MonthlyTask> _parseTasks(List<String> lines) {
    final tasks = <MonthlyTask>[];
    bool inTasksSection = false;
    
    for (final line in lines) {
      if (line.trim() == '## Tasks') {
        inTasksSection = true;
        continue;
      }
      
      if (inTasksSection && line.trim().startsWith('##')) {
        break; // Exit tasks section
      }
      
      if (inTasksSection && line.trim().startsWith('- [')) {
        final task = _parseTaskLine(line);
        if (task != null) {
          tasks.add(task);
        }
      }
    }
    
    return tasks;
  }

  MonthlyTask? _parseTaskLine(String line) {
    try {
      final trimmed = line.trim();
      if (!trimmed.startsWith('- [')) return null;
      
      final checkboxEnd = trimmed.indexOf(']');
      if (checkboxEnd == -1) return null;
      
      final isCompleted = trimmed[2] == 'x';
      final titleStart = checkboxEnd + 1;
      final title = trimmed.substring(titleStart).trim();
      
      return MonthlyTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        isCompleted: isCompleted,
        priority: 'medium',
      );
    } catch (e) {
      debugPrint('FileService: Error parsing task line: $e');
      return null;
    }
  }

  List<DailyEntry> _parseDailyEntries(List<String> lines) {
    final entries = <DailyEntry>[];
    bool inDailySection = false;
    String currentDate = '';
    String currentContent = '';
    List<String> currentTags = [];
    
    for (final line in lines) {
      if (line.trim() == '## Daily Entries') {
        inDailySection = true;
        continue;
      }
      
      if (inDailySection && line.trim().startsWith('###')) {
        // Save previous entry if exists
        if (currentDate.isNotEmpty && currentContent.isNotEmpty) {
          entries.add(_createDailyEntry(currentDate, currentContent, currentTags));
        }
        
        // Start new entry
        currentDate = line.trim().substring(4); // Remove "### "
        currentContent = '';
        currentTags = [];
        continue;
      }
      
      if (inDailySection && line.trim().startsWith('#')) {
        // Check for tags
        final tagMatches = RegExp(r'#(\w+)').allMatches(line);
        currentTags.addAll(tagMatches.map((m) => m.group(1)!));
      }
      
      if (inDailySection && currentDate.isNotEmpty) {
        currentContent += '$line\n';
      }
    }
    
    // Add last entry
    if (currentDate.isNotEmpty && currentContent.isNotEmpty) {
      entries.add(_createDailyEntry(currentDate, currentContent, currentTags));
    }
    
    return entries;
  }

  DailyEntry _createDailyEntry(String dateString, String content, List<String> tags) {
    // Parse date from format "01.06.2025 - Sunday"
    final datePart = dateString.split(' - ')[0];
    final parts = datePart.split('.');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    
    return DailyEntry(
      date: DateTime(year, month, day),
      content: content.trim(),
      tags: tags,
    );
  }

  // EXCEL FILES (Time entries per year)
  
  Future<void> saveTimeEntries(int year, List<TimeEntry> timeEntries) async {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) {
      await yearDir.create(recursive: true);
    }
    
    final excelFile = File(path.join(yearDir.path, '$year.xlsx'));
    await _createExcelFile(excelFile, timeEntries);
    
    debugPrint('FileService: Saved Excel file: ${excelFile.path}');
  }

  Future<void> saveCategories(int year, List<Map<String, String>> categories) async {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) {
      await yearDir.create(recursive: true);
    }
    
    final excelFile = File(path.join(yearDir.path, '$year.xlsx'));
    
    // Load existing Excel file if it exists, or create new one
    Excel excel;
    if (await excelFile.exists()) {
      try {
        final bytes = await excelFile.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        debugPrint('FileService: Error loading existing Excel file, creating new one: $e');
        excel = Excel.createExcel();
      }
    } else {
      excel = Excel.createExcel();
    }
    
    // Update or create Categories sheet
    final categoriesSheet = excel['Categories'];
    
    // Clear existing content by setting cells to null (but limit to reasonable bounds)
    final maxRows = categoriesSheet.maxRows;
    final maxCols = categoriesSheet.maxCols;
    
    // Only clear cells that actually exist (limit to prevent Excel errors)
    for (int row = 0; row <= maxRows && row < 1000; row++) {
      for (int col = 0; col <= maxCols && col < 100; col++) {
        try {
          final cell = categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          if (cell.value != null) {
            cell.value = null;
          }
        } catch (e) {
          // Skip cells that can't be accessed
          break;
        }
      }
    }
    
    // Headers
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Name';
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Color';
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'Icon';
    
    // Data
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final row = i + 1;
      
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = category['name'];
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = category['color'];
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = category['icon'];
    }
    
    final bytes = excel.encode();
    await excelFile.writeAsBytes(bytes!);
    
    debugPrint('FileService: Saved categories to Excel file: ${excelFile.path}');
  }

  Future<List<TimeEntry>> loadTimeEntries(int year) async {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) return [];
    
    final excelFile = File(path.join(yearDir.path, '$year.xlsx'));
    if (!excelFile.existsSync()) return [];
    
    try {
      final bytes = await excelFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      return _parseExcelFile(excel);
    } catch (e) {
      debugPrint('FileService: Error loading Excel file: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> loadCategories(int year) async {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) return [];
    
    final excelFile = File(path.join(yearDir.path, '$year.xlsx'));
    if (!excelFile.existsSync()) return [];
    
    try {
      final bytes = await excelFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      if (!excel.tables.containsKey('Categories')) {
        debugPrint('FileService: No Categories sheet found in Excel file');
        return [];
      }
      
      return _parseCategoriesSheet(excel);
    } catch (e) {
      debugPrint('FileService: Error loading categories from Excel file: $e');
      return [];
    }
  }

  List<Map<String, String>> _parseCategoriesSheet(Excel excel) {
    final categories = <Map<String, String>>[];
    final sheet = excel['Categories'];
    
    // Skip header row and find actual data rows
    for (int row = 1; row <= sheet.maxRows; row++) {
      try {
        final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        
        // Stop parsing if we hit an empty row
        if (nameCell.value == null || nameCell.value.toString().trim().isEmpty) {
          break;
        }
        
        final colorCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        final iconCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
        
        final name = nameCell.value.toString();
        final color = colorCell.value?.toString() ?? '#2196F3';
        final icon = iconCell.value?.toString() ?? 'category';
        
        categories.add({
          'name': name,
          'color': color,
          'icon': icon,
        });
      } catch (e) {
        debugPrint('FileService: Error parsing category row $row: $e');
        // Continue to next row instead of breaking
      }
    }
    
    return categories;
  }

  Future<void> _createExcelFile(File file, List<TimeEntry> timeEntries) async {
    final excel = Excel.createExcel();
    
    // Create Time Entries sheet
    final sheet = excel['Time Entries'];
    
    // Headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Date';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Start Time';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'End Time';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'Duration';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'Category';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'Description';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = 'Type';
    
    // Data
    for (int i = 0; i < timeEntries.length; i++) {
      final entry = timeEntries[i];
      final row = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = entry.date.toIso8601String().split('T')[0];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = entry.startTime.toIso8601String();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = entry.endTime.toIso8601String();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = entry.duration.inMinutes;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = entry.category;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = entry.description;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = entry.type;
    }
    
    // Create Categories sheet
    final categoriesSheet = excel['Categories'];
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Name';
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Color';
    categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'Icon';
    
    // Add default categories
    final defaultCategories = [
      {'name': 'Work', 'color': '#2196F3', 'icon': 'work'},
      {'name': 'Personal', 'color': '#4CAF50', 'icon': 'person'},
      {'name': 'Study', 'color': '#FF9800', 'icon': 'school'},
      {'name': 'Exercise', 'color': '#F44336', 'icon': 'fitness_center'},
      {'name': 'Sleep', 'color': '#9C27B0', 'icon': 'bedtime'},
      {'name': 'Entertainment', 'color': '#FF5722', 'icon': 'movie'},
      {'name': 'Travel', 'color': '#00BCD4', 'icon': 'flight'},
      {'name': 'Shopping', 'color': '#795548', 'icon': 'shopping_cart'},
      {'name': 'Cooking', 'color': '#FFC107', 'icon': 'restaurant'},
      {'name': 'Social', 'color': '#E91E63', 'icon': 'group'},
    ];
    
    for (int i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      final row = i + 1;
      
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = category['name'];
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = category['color'];
      categoriesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = category['icon'];
    }
    
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
  }

  List<TimeEntry> _parseExcelFile(Excel excel) {
    final entries = <TimeEntry>[];
    final sheet = excel['Time Entries'];
    
    // Skip header row and find actual data rows
    for (int row = 1; row <= sheet.maxRows; row++) {
      try {
        final dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        
        // Stop parsing if we hit an empty row
        if (dateCell.value == null || dateCell.value.toString().trim().isEmpty) {
          break;
        }
        
        final date = DateTime.parse(dateCell.value.toString());
        final startValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value;
        final endValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value;
        final categoryValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value;
        final descriptionValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value;
        final typeValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value;

        final startTime = DateTime.parse(startValue.toString());
        final endTime = DateTime.parse(endValue.toString());
        final category = categoryValue?.toString() ?? '';
        final description = descriptionValue?.toString() ?? '';
        final type = typeValue?.toString() ?? '';
        
        final duration = endTime.difference(startTime);
        
        entries.add(TimeEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: date,
          type: type,
          startTime: startTime,
          endTime: endTime,
          description: description,
          category: category,
          duration: duration,
        ));
      } catch (e) {
        debugPrint('FileService: Error parsing Excel row $row: $e');
        // Continue to next row instead of breaking
      }
    }
    
    return entries;
  }

  // UTILITY METHODS
  
  List<int> getAvailableYears() {
    if (!_dataDirectory.existsSync()) return [];
    
    return _dataDirectory
        .listSync()
        .whereType<Directory>()
        .map((dir) => int.tryParse(path.basename(dir.path)))
        .where((year) => year != null)
        .map((year) => year!)
        .toList()
      ..sort();
  }

  List<int> getAvailableMonths(int year) {
    final yearDir = Directory(path.join(_dataDirectory.path, year.toString()));
    if (!yearDir.existsSync()) return [];
    
    return yearDir
        .listSync()
        .whereType<File>()
        .where((file) => path.extension(file.path) == '.md')
        .map((file) => int.tryParse(path.basenameWithoutExtension(file.path)))
        .where((month) => month != null)
        .map((month) => month!)
        .toList()
      ..sort();
  }

  String get dataDirectoryPath => _dataDirectory.path;
  
  Future<void> setDataDirectory(String path) async {
    // This method is for compatibility with the old system
    // The actual directory is managed by ConfigService
    debugPrint('FileService: setDataDirectory called with $path');
  }
}
