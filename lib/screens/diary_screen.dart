import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/diary_entry.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/add_diary_entry_dialog.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = '';
  String _selectedTag = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Icons.today)),
            Tab(text: 'Monthly', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Memos', icon: Icon(Icons.note)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyEntries(),
          _buildMonthlyMemos(),
          _buildMemos(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDiaryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildDailyEntries() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final entries = provider.diaryEntries
            .where((e) => e.type == DiaryEntryType.daily)
            .toList();
        
        // Apply filtering and sorting
        final filteredEntries = _filterEntries(entries);
        filteredEntries.sort((a, b) => b.date.compareTo(a.date));

        if (filteredEntries.isEmpty) {
          return _buildEmptyState(context, 'daily');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEntries.length,
          itemBuilder: (context, index) {
            final entry = filteredEntries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DiaryEntryCard(
                entry: entry,
                onEdit: () => _showEditDiaryDialog(context, entry),
                onDelete: () => _showDeleteConfirmation(context, entry),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthlyMemos() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final entries = provider.diaryEntries
            .where((e) => e.type == DiaryEntryType.monthly)
            .toList();
        
        entries.sort((a, b) => b.date.compareTo(a.date));

        if (entries.isEmpty) {
          return _buildEmptyState(context, 'monthly');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DiaryEntryCard(
                entry: entry,
                onEdit: () => _showEditDiaryDialog(context, entry),
                onDelete: () => _showDeleteConfirmation(context, entry),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemos() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final entries = provider.diaryEntries
            .where((e) => e.type == DiaryEntryType.memo)
            .toList();
        
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (entries.isEmpty) {
          return _buildEmptyState(context, 'memo');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DiaryEntryCard(
                entry: entry,
                onEdit: () => _showEditDiaryDialog(context, entry),
                onDelete: () => _showDeleteConfirmation(context, entry),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    String title, subtitle, icon;
    
    switch (type) {
      case 'daily':
        title = 'No daily entries yet';
        subtitle = 'Start writing your daily reflections and thoughts';
        icon = '📝';
        break;
      case 'monthly':
        title = 'No monthly memos yet';
        subtitle = 'Create monthly summaries and insights';
        icon = '📅';
        break;
      case 'memo':
        title = 'No memos yet';
        subtitle = 'Write down important notes and ideas';
        icon = '📌';
        break;
      default:
        title = 'No entries yet';
        subtitle = 'Start writing your thoughts';
        icon = '✍️';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDiaryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Write First Entry'),
          ),
        ],
      ),
    );
  }

  void _showAddDiaryDialog(BuildContext context) {
    final type = _getCurrentType();
    showDialog(
      context: context,
      builder: (context) => AddDiaryEntryDialog(type: type),
    );
  }

  void _showEditDiaryDialog(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AddDiaryEntryDialog(entry: entry),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteDiaryEntry(entry.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted successfully')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  DiaryEntryType _getCurrentType() {
    switch (_tabController.index) {
      case 0:
        return DiaryEntryType.daily;
      case 1:
        return DiaryEntryType.monthly;
      case 2:
        return DiaryEntryType.memo;
      default:
        return DiaryEntryType.daily;
    }
  }

  List<DiaryEntry> _filterEntries(List<DiaryEntry> entries) {
    return entries.where((entry) {
      bool matchesSearch = _searchQuery.isEmpty ||
          entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesTag = _selectedTag == 'all' ||
          entry.tags.contains(_selectedTag);
      
      return matchesSearch && matchesTag;
    }).toList();
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Entries'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Search query',
            hintText: 'Enter title or content to search...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Get all unique tags from diary entries
          final allTags = context.read<AppProvider>().diaryEntries
              .expand((entry) => entry.tags)
              .toSet()
              .toList()
            ..sort();

          return AlertDialog(
            title: const Text('Filter by Tags'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTag,
                  decoration: const InputDecoration(
                    labelText: 'Tag',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Tags')),
                    ...allTags.map((tag) => DropdownMenuItem(
                          value: tag,
                          child: Text(tag),
                        )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedTag = value ?? 'all';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedTag = 'all';
                  });
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
