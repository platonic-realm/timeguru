import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/config_service.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Data Directory Section
              _buildSectionHeader('Data Storage'),
              _buildDataDirectoryCard(context, provider),
              const SizedBox(height: 24),
              
              // Calendar Integration Section
                                        _buildSectionHeader('Appearance'),
                          _buildAppearanceCard(context),
                          const SizedBox(height: 24),
                          
                          _buildSectionHeader('Calendar Integration'),
                          _buildCalendarSettingsCard(context, provider),
                          const SizedBox(height: 24),
              
              // Export Section
              _buildSectionHeader('Data Management'),
              _buildExportCard(context, provider),
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader('About'),
              _buildAboutCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataDirectoryCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data Directory',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.dataDirectoryPath,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDataDirectory(context, provider),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Change Directory'),
                  ),
                ),
                const SizedBox(width: 12),
                
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'This directory stores all your TimeGuru data including time entries, tasks, and diary entries. '
              'You can change this to sync with your Obsidian vault or other cloud storage.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSettingsCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Calendar Integration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Auto-sync to Calendar'),
              subtitle: const Text('Automatically add time entries and tasks to your device calendar'),
              value: provider.configService.autoSyncCalendar,
              onChanged: (value) async {
                await provider.configService.setAutoSyncCalendar(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calendar sync setting updated')),
                );
              },
            ),
            
            SwitchListTile(
              title: const Text('Create iCal Files'),
              subtitle: const Text('Generate .ics files for external calendar apps'),
              value: provider.configService.createICalFiles,
              onChanged: (value) async {
                await provider.configService.setCreateICalFiles(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('iCal generation setting updated')),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'TimeGuru can automatically sync your activities with your device calendar '
              'and create iCal files that can be imported into other calendar applications.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data Export',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () => _exportData(context, provider),
              icon: const Icon(Icons.download),
              label: const Text('Export All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Export your data to a backup location. This includes all time entries, tasks, '
              'diary entries, and calendar files in both JSON and Markdown formats.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'About TimeGuru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
            
            const ListTile(
              leading: Icon(Icons.description),
              title: Text('Description'),
              subtitle: Text('Personal time tracking, task management, and diary app'),
            ),
            
            const ListTile(
              leading: Icon(Icons.storage),
              title: Text('Storage'),
              subtitle: Text('File-based with Markdown support'),
            ),
            
            const ListTile(
              leading: Icon(Icons.sync),
              title: Text('Sync'),
              subtitle: Text('Calendar integration and iCal export'),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'TimeGuru is designed to work seamlessly with your existing file-based workflow. '
              'All data is stored in human-readable formats that can be easily synced across devices '
              'and integrated with tools like Obsidian.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _selectDataDirectory(BuildContext context, AppProvider provider) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Data Directory',
      );
      
      if (selectedDirectory != null) {
        await provider.setDataDirectory(selectedDirectory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data directory changed to: $selectedDirectory'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change data directory: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }



  Future<void> _exportData(BuildContext context, AppProvider provider) async {
    try {
      String? exportDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Export Directory',
      );
      
      if (exportDirectory != null) {
        await provider.exportData(exportDirectory);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data exported successfully to: $exportDirectory'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildAppearanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer<ConfigService>(
              builder: (context, configService, child) {
                final currentThemeMode = _parseThemeMode(configService.themeMode);
                
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.light_mode),
                      title: const Text('Light Theme'),
                      subtitle: const Text('Use light color scheme'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: currentThemeMode,
                        onChanged: (value) async {
                          if (value != null) {
                            await configService.setThemeMode('light');
                            // Notify parent to update theme
                            final themeSetter = context.read<Function(ThemeMode)>();
                            themeSetter(ThemeMode.light);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            
            Consumer<ConfigService>(
              builder: (context, configService, child) {
                final currentThemeMode = _parseThemeMode(configService.themeMode);
                
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Theme'),
                      subtitle: const Text('Use dark color scheme'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: currentThemeMode,
                        onChanged: (value) async {
                          if (value != null) {
                            await configService.setThemeMode('dark');
                            // Notify parent to update theme
                            final themeSetter = context.read<Function(ThemeMode)>();
                            themeSetter(ThemeMode.dark);
                          }
                        },
                      ),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.settings_system_daydream),
                      title: const Text('System Theme'),
                      subtitle: const Text('Follow system appearance'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.system,
                        groupValue: currentThemeMode,
                        onChanged: (value) async {
                          if (value != null) {
                            await configService.setThemeMode('system');
                            // Notify parent to update theme
                            final themeSetter = context.read<Function(ThemeMode)>();
                            themeSetter(ThemeMode.system);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Choose your preferred theme. System theme will automatically switch between light and dark based on your device settings.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
}
