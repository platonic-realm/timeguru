import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeguru/providers/app_provider.dart';
import 'package:timeguru/screens/home_screen.dart';
import 'package:timeguru/screens/settings_screen.dart';
import 'package:timeguru/screens/tasks_screen.dart';
import 'package:timeguru/screens/diary_screen.dart';
import 'package:timeguru/screens/setup_screen.dart';
import 'package:timeguru/services/file_service.dart';
import 'package:timeguru/services/calendar_service.dart';
import 'package:timeguru/services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ConfigService first (it needs to be ready for FileService)
  final configService = ConfigService();
  await configService.initialize();
  
  // Create other services
  final fileService = FileService(configService);
  final calendarService = CalendarService();
  
  // Start the app immediately - other services will initialize when needed
  runApp(TimeGuru(
    configService: configService,
    fileService: fileService, 
    calendarService: calendarService
  ));
}

class TimeGuru extends StatefulWidget {
  final ConfigService configService;
  final FileService fileService;
  final CalendarService calendarService;

  const TimeGuru({
    super.key,
    required this.configService,
    required this.fileService,
    required this.calendarService,
  });

  @override
  State<TimeGuru> createState() => _TimeGuruState();
}

class _TimeGuruState extends State<TimeGuru> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      if (widget.configService.isInitialized) {
        final themeMode = widget.configService.themeMode;
        setState(() {
          _themeMode = _parseThemeMode(themeMode);
        });
      }
    } catch (e) {
      // ConfigService not initialized yet, use default theme
      debugPrint('TimeGuru: ConfigService not ready yet: $e');
    }
  }

  ThemeMode _parseThemeMode(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    final themeModeString = _themeModeToString(themeMode);
    await widget.configService.setThemeMode(themeModeString);
    setState(() {
      _themeMode = themeMode;
    });
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConfigService>.value(value: widget.configService),
        Provider<Function(ThemeMode)>.value(value: _setThemeMode),
        ChangeNotifierProvider(
          create: (context) => AppProvider(
            configService: widget.configService,
            fileService: widget.fileService,
            calendarService: widget.calendarService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'TimeGuru',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _themeMode,
        home: TimeGuruApp(
          configService: widget.configService,
          fileService: widget.fileService,
          calendarService: widget.calendarService,
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Blue
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Blue
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}

class TimeGuruApp extends StatefulWidget {
  final ConfigService configService;
  final FileService fileService;
  final CalendarService calendarService;

  const TimeGuruApp({
    super.key,
    required this.configService,
    required this.fileService,
    required this.calendarService,
  });

  @override
  State<TimeGuruApp> createState() => _TimeGuruAppState();
}

class _TimeGuruAppState extends State<TimeGuruApp> {
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _showSetup = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const DiaryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // ConfigService is already initialized in main, just initialize other services
      await widget.fileService.initialize();
      await widget.calendarService.initialize();
      
      setState(() {
        _isInitialized = true;
        _showSetup = false;
      });
    } catch (e) {
      // If no data directory is configured, show setup screen
      debugPrint('TimeGuruApp: No data directory configured: $e');
      setState(() {
        _showSetup = true;
      });
    }
  }

  Future<void> _reinitializeServices() async {
    debugPrint('TimeGuruApp: _reinitializeServices called');
    setState(() {
      _isInitialized = false;
      _showSetup = false;
    });
    
    await _initializeServices();
  }

  @override
  Widget build(BuildContext context) {
    // Show setup screen if services failed to initialize
    if (_showSetup) {
      return SetupScreen(
        onSetupComplete: _reinitializeServices,
        configService: widget.configService,
      );
    }
    
    // Show loading screen while initializing
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


