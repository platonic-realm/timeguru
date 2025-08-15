import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ConfigService {
  static const String _configFileName = 'timeguru_config.json';
  late File _configFile;
  late Map<String, dynamic> _config;
  bool _initialized = false;

  // Configuration keys
  static const String _dataDirectoryKey = 'data_directory';
  static const String _themeModeKey = 'theme_mode';
  static const String _autoSyncKey = 'auto_sync_calendar';
  static const String _createICalKey = 'create_ical_files';

  // Default configuration
  static const Map<String, dynamic> _defaultConfig = {
    'data_directory': null,
    'theme_mode': 'system',
    'auto_sync_calendar': true,
    'create_ical_files': true,
  };

  Future<void> initialize() async {
    if (_initialized) return;

    // Get the executable directory
    final executableDir = await _getExecutableDirectory();
    _configFile = File(path.join(executableDir, _configFileName));

    // Load or create configuration
    await _loadConfig();
    _initialized = true;
  }

  Future<String> _getExecutableDirectory() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // For development, use the project directory; for production, use executable directory
      if (Platform.resolvedExecutable.contains('build')) {
        // Development mode - use project directory
        final currentDir = Directory.current;
        return currentDir.path;
      } else {
        // Production mode - use executable directory
        final executablePath = Platform.resolvedExecutable;
        return path.dirname(executablePath);
      }
    } else {
      // For mobile platforms, this won't be used but we need to handle it
      throw UnsupportedError('ConfigService is not supported on mobile platforms');
    }
  }

  Future<void> _loadConfig() async {
    try {
      debugPrint('ConfigService: Loading config from: ${_configFile.path}');
      if (await _configFile.exists()) {
        final content = await _configFile.readAsString();
        debugPrint('ConfigService: Config file content: $content');
        _config = Map<String, dynamic>.from(jsonDecode(content));
        debugPrint('ConfigService: Loaded config: $_config');
        
        // Ensure all default keys exist
        for (final entry in _defaultConfig.entries) {
          if (!_config.containsKey(entry.key)) {
            _config[entry.key] = entry.value;
          }
        }
      } else {
        debugPrint('ConfigService: Config file does not exist, creating default');
        // Create default configuration
        _config = Map<String, dynamic>.from(_defaultConfig);
        await _saveConfig();
      }
    } catch (e) {
      debugPrint('ConfigService: Error loading config: $e');
      // Fallback to default configuration
      _config = Map<String, dynamic>.from(_defaultConfig);
      await _saveConfig();
    }
  }

  Future<void> _saveConfig() async {
    try {
      final content = jsonEncode(_config);
      await _configFile.writeAsString(content);
      debugPrint('ConfigService: Configuration saved to: ${_configFile.path}');
    } catch (e) {
      debugPrint('ConfigService: Error saving config: $e');
      rethrow;
    }
  }

  // Data directory configuration
  String? get dataDirectory => _config[_dataDirectoryKey];
  
  Future<void> setDataDirectory(String? path) async {
    _config[_dataDirectoryKey] = path;
    await _saveConfig();
  }

  // Theme configuration
  String get themeMode => _config[_themeModeKey] ?? 'system';
  
  Future<void> setThemeMode(String mode) async {
    _config[_themeModeKey] = mode;
    await _saveConfig();
  }

  // Calendar configuration
  bool get autoSyncCalendar => _config[_autoSyncKey] ?? true;
  
  Future<void> setAutoSyncCalendar(bool value) async {
    _config[_autoSyncKey] = value;
    await _saveConfig();
  }

  bool get createICalFiles => _config[_createICalKey] ?? true;
  
  Future<void> setCreateICalFiles(bool value) async {
    _config[_createICalKey] = value;
    await _saveConfig();
  }

  // Get all configuration
  Map<String, dynamic> get allConfig => Map.unmodifiable(_config);

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _config = Map<String, dynamic>.from(_defaultConfig);
    await _saveConfig();
  }

  // Get configuration file path (for debugging)
  String get configFilePath => _configFile.path;

  // Check if configuration is initialized
  bool get isInitialized => _initialized;
}
