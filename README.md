# TimeGuru

A comprehensive personal time tracking, task management, and diary application built with Flutter. TimeGuru is designed to work seamlessly with your existing file-based workflow and integrates with Obsidian and calendar applications.

## Features

### 🕒 Time Tracking
- **Daily Activity Logging**: Track your daily activities with start/end times
- **Category Management**: Organize activities into categories (Idle, Study, Work, Quotidian, Family, Unknown)
- **Duration Calculation**: Automatic calculation of time spent on each activity
- **Daily Summaries**: View daily breakdowns and progress towards 24-hour goals

### 📋 Task Management
- **Project Tasks**: Create and manage project-based tasks
- **Priority Levels**: Set priority levels (Low, Medium, High, Urgent)
- **Due Dates**: Track deadlines and overdue tasks
- **Status Tracking**: Monitor task progress (Pending, In Progress, Completed, Cancelled)

### 📖 Diary & Reflection
- **Daily Entries**: Write daily reflections and notes
- **Monthly Memos**: Create monthly summaries and insights
- **Markdown Support**: All entries are saved in Markdown format for Obsidian compatibility
- **Tagging System**: Organize entries with custom tags

### 📅 Calendar Integration
- **Device Calendar Sync**: Automatically sync activities and tasks with your device calendar
- **iCal Export**: Generate standard iCal files for external calendar applications
- **Event Management**: Create calendar events for time entries and task deadlines

### 💾 File-Based Storage
- **Human-Readable Format**: All data stored in JSON and Markdown formats
- **Configurable Location**: Set custom data directory for syncing with cloud storage
- **Obsidian Integration**: Works seamlessly with Obsidian vaults
- **Cross-Platform Sync**: Easy to sync data across devices

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or Linux desktop

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd timeguru
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For Linux desktop
   flutter run -d linux
   ```

### First Run Setup

1. **Data Directory**: The app will create a default data directory in your documents folder
2. **Calendar Permissions**: Grant calendar permissions when prompted for calendar integration
3. **Settings**: Configure your preferred data directory in Settings → Data Storage

## Usage Guide

### Adding Time Entries

1. Tap the **"Add Entry"** button on the home screen
2. Fill in the activity details:
   - **Activity Type**: e.g., "PhD", "Sleep", "Shopping"
   - **Description**: Brief description of what you did
   - **Category**: Select from predefined categories
   - **Start/End Time**: Set the time range for the activity
3. Tap **"Add Entry"** to save

### Managing Tasks

1. Navigate to the **Tasks** tab
2. Tap **"Add Task"** to create new tasks
3. Set title, description, due date, and priority
4. Mark tasks as complete when finished

### Writing Diary Entries

1. Go to the **Diary** tab
2. Choose between daily entries or monthly memos
3. Write your reflections in Markdown format
4. Add relevant tags for organization

### Calendar Integration

- **Auto-sync**: Enable automatic calendar sync in Settings
- **iCal Export**: Export calendar data as iCal files
- **Manual Sync**: Manually sync specific entries or tasks

### Data Management

- **Export**: Backup all data to a custom location
- **Directory Change**: Point the app to your Obsidian vault or cloud sync folder
- **Backup**: Regular exports ensure data safety

## Data Structure

The app creates the following directory structure in your data folder:

```
TimeGuru/
├── time_entries/          # Individual time tracking entries
├── daily_summaries/       # Daily time summaries
├── tasks/                 # Task definitions and status
├── diary/                 # Daily diary entries
├── monthly/               # Monthly memos
└── memos/                 # General memos and notes
```

### File Formats

- **JSON Files**: App data storage (time entries, tasks, summaries)
- **Markdown Files**: Diary entries and memos with Obsidian-compatible frontmatter
- **iCal Files**: Calendar exports for external applications

## Configuration

### Data Directory
- **Default**: `~/Documents/TimeGuru/`
- **Custom**: Set any directory path in Settings
- **Obsidian**: Point to your Obsidian vault for seamless integration

### Calendar Settings
- **Auto-sync**: Automatically add entries to device calendar
- **iCal Generation**: Create standard calendar files
- **Calendar Selection**: Choose which calendar to sync with

### Export Options
- **Full Export**: All data in JSON and Markdown formats
- **Calendar Export**: iCal files for external calendar apps
- **Backup Location**: Custom export directory selection

## Integration with Obsidian

TimeGuru is designed to work seamlessly with Obsidian:

1. **Set Data Directory**: Point TimeGuru to your Obsidian vault
2. **Markdown Files**: All diary entries are saved as Markdown with frontmatter
3. **Tags**: Use Obsidian's tagging system for organization
4. **Linking**: Create links between entries and other Obsidian notes
5. **Sync**: Changes sync automatically between TimeGuru and Obsidian

## Troubleshooting

### Common Issues

**Calendar permissions denied**
- Go to device settings and grant calendar permissions to TimeGuru
- Restart the app after granting permissions

**Data directory not accessible**
- Ensure the directory exists and has proper permissions
- Try using a different directory path

**App crashes on startup**
- Clear app data and restart
- Check Flutter version compatibility

**Calendar sync not working**
- Verify calendar permissions
- Check if the selected calendar exists
- Restart the calendar service

### Performance Tips

- **Large datasets**: Export and archive old data periodically
- **Calendar sync**: Limit auto-sync for better performance
- **File size**: Keep diary entries concise for faster loading

## Development

### Project Structure

```
lib/
├── models/           # Data models and serialization
├── providers/        # State management with Provider
├── screens/          # Main app screens
├── services/         # File and calendar services
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

### Key Dependencies

- **Provider**: State management
- **Path Provider**: File system access
- **Device Calendar**: Calendar integration
- **File Picker**: Directory selection
- **Intl**: Date/time formatting
- **JSON Serializable**: Data serialization

### Building for Production

```bash
# Android APK
flutter build apk --release

# Linux AppImage
flutter build linux --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the documentation

---

**TimeGuru** - Your personal time management companion with file-based flexibility and powerful integrations.
