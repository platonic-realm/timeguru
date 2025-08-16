import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  final ConfigService configService;

  const SetupScreen({
    super.key,
    required this.onSetupComplete,
    required this.configService,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _selectedPath;
  bool _isConfiguring = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon and Title
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'Welcome to TimeGuru',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Your personal time tracking, task management, and diary app',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Setup Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'Choose Data Directory',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              'Select a folder where TimeGuru will store your data. This can be any folder on your system.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Directory Selection
                            if (_selectedPath != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Directory:',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedPath!,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isConfiguring ? null : _selectDirectory,
                                    icon: Icon(_selectedPath == null ? Icons.folder_open : Icons.edit),
                                    label: Text(_selectedPath == null ? 'Choose Directory' : 'Change Directory'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                
                                if (_selectedPath != null) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isConfiguring ? null : _completeSetup,
                                      icon: _isConfiguring 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.check),
                                      label: Text(_isConfiguring ? 'Setting Up...' : 'Start Using TimeGuru'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Data Directory',
      );
      
      if (selectedDirectory != null) {
        setState(() {
          _selectedPath = selectedDirectory;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select directory: $e';
      });
    }
  }

  Future<void> _completeSetup() async {
    if (_selectedPath == null) {
      debugPrint('SetupScreen: No path selected');
      return;
    }

    setState(() {
      _isConfiguring = true;
      _errorMessage = null;
    });

    try {
      debugPrint('SetupScreen: Starting setup with path: $_selectedPath');
      debugPrint('SetupScreen: ConfigService initialized: ${widget.configService.isInitialized}');
      
      // Save the selected directory to the main app's ConfigService
      await widget.configService.setDataDirectory(_selectedPath!);
      
      debugPrint('SetupScreen: Data directory saved successfully: $_selectedPath');
      debugPrint('SetupScreen: Current data directory: ${widget.configService.dataDirectory}');
      
      // Notify the parent that setup is complete
      if (mounted) {
        debugPrint('SetupScreen: Calling onSetupComplete callback');
        widget.onSetupComplete();
      }
    } catch (e) {
      debugPrint('SetupScreen: Error completing setup: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving directory: $e';
          _isConfiguring = false;
        });
      }
    }
  }
}
