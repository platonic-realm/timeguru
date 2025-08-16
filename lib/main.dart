import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/config_service.dart';
import 'services/file_service.dart';
import 'services/calendar_service.dart';
import 'providers/app_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/monthly_screen.dart';
import 'screens/yearly_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const TimeGuru());
}

class TimeGuru extends StatefulWidget {
  const TimeGuru({super.key});

  @override
  State<TimeGuru> createState() => _TimeGuruState();
}

class _TimeGuruState extends State<TimeGuru> {
  late final ConfigService _configService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isConfigReady = false;

  @override
  void initState() {
    super.initState();
    _configService = ConfigService();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    try {
      await _configService.initialize();
      if (mounted) {
        setState(() {
          _themeMode = _configService.themeMode;
          _isConfigReady = true;
        });
      }
    } catch (e) {
      debugPrint('TimeGuru: Failed to initialize config: $e');
      // Still set ready to true so the app can show setup if needed
      if (mounted) {
        setState(() {
          _isConfigReady = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConfigReady) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _configService,
      child: MaterialApp(
        title: 'TimeGuru',
        themeMode: _themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: TimeGuruApp(configService: _configService),
      ),
    );
  }
}

class TimeGuruApp extends StatefulWidget {
  final ConfigService configService;

  const TimeGuruApp({
    super.key,
    required this.configService,
  });

  @override
  State<TimeGuruApp> createState() => _TimeGuruAppState();
}

class _TimeGuruAppState extends State<TimeGuruApp> {
  late final FileService _fileService;
  late final CalendarService _calendarService;
  late final AppProvider _appProvider;
  bool _isInitialized = false;
  bool _showSetup = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      // Check if data directory is set
      if (widget.configService.dataDirectory != null) {
        // Initialize services
        _fileService = FileService(widget.configService);
        _calendarService = CalendarService();
        
        // Connect FileService to ConfigService for category management
        widget.configService.setFileService(_fileService);
        
        _appProvider = AppProvider(
          fileService: _fileService,
          configService: widget.configService,
          calendarService: _calendarService,
        );

        setState(() {
          _isInitialized = true;
          _showSetup = false;
        });
        
        // Load categories after the app is initialized (in background)
        _loadCategoriesInBackground();
      } else {
        setState(() {
          _showSetup = true;
        });
      }
    } catch (e) {
      debugPrint('TimeGuruApp: Error checking initialization: $e');
      setState(() {
        _showSetup = true;
      });
    }
  }

  Future<void> _loadCategoriesInBackground() async {
    try {
      // Wait a bit to ensure everything is stable
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted && widget.configService.isInitialized) {
        await widget.configService.loadCategoriesFromExcel(DateTime.now().year);
        debugPrint('TimeGuruApp: Categories loaded successfully in background');
      }
    } catch (e) {
      debugPrint('TimeGuruApp: Failed to load categories in background: $e');
    }
  }

  Future<void> _onSetupComplete() async {
    debugPrint('TimeGuruApp: Setup completed, reinitializing...');
    debugPrint('TimeGuruApp: Current data directory: ${widget.configService.dataDirectory}');
    debugPrint('TimeGuruApp: ConfigService initialized: ${widget.configService.isInitialized}');
    
    await _checkInitialization();
    
    debugPrint('TimeGuruApp: Reinitialization complete');
    debugPrint('TimeGuruApp: _showSetup: $_showSetup, _isInitialized: $_isInitialized');
  }

  @override
  Widget build(BuildContext context) {
    if (_showSetup) {
      return SetupScreen(
        configService: widget.configService,
        onSetupComplete: _onSetupComplete,
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider.value(value: widget.configService),
      ],
      child: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Start with Monthly view

  final List<Widget> _screens = [
    const DailyScreen(),
    const MonthlyScreen(),
    const YearlyScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Daily',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Monthly',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Yearly',
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
