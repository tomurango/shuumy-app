# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

- **Run the app**: `flutter run`
- **Hot reload**: `r` (while app is running)
- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`
- **Build for release**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Get dependencies**: `flutter pub get`
- **Clean build cache**: `flutter clean`

## Architecture Overview

This is a Flutter app called "shuumy" - a hobby tracking application with image-based hobby icons displayed in a grid layout.

### State Management
- Uses **Riverpod** (`flutter_riverpod`) for state management
- Main provider: `hobbyListProvider` in `lib/src/providers/hobby_list_provider.dart`

### Data Flow
1. **Models**: `Hobby` class in `lib/src/models/hobby.dart` represents hobby items with title, memo, and image filename
2. **Storage**: `HobbyJsonService` in `lib/src/services/hobby_json_service.dart` handles JSON persistence to device storage
3. **State**: `HobbyListNotifier` manages the list of hobbies and persists changes
4. **UI**: Grid-based layout showing hobby icons with background image

### File Structure
- `lib/main.dart` - App entry point with MaterialApp and ProviderScope
- `lib/src/models/` - Data models
- `lib/src/providers/` - Riverpod state providers
- `lib/src/screens/` - UI screens (HomeScreen, AddHobbyScreen)
- `lib/src/services/` - Data services for JSON storage
- `assets/` - Contains background image

### Key Dependencies
- `flutter_riverpod` - State management
- `image_picker` - Image selection functionality
- `path_provider` - File system access
- `uuid` - Unique identifier generation
- `path` - Path manipulation utilities

### Data Storage
- Hobbies stored as JSON in device's application documents directory
- Images stored in `{documents}/images/` directory
- File naming uses UUID for image files

## Development Guidelines

### UI/UX Design Principles
- **Home screen aesthetic**: iOS-style grid layout with background image overlay
- **Consistent visual theme**: White semi-transparent elements over background
- **Grid layout**: 4 columns, fixed aspect ratio for hobby icons
- **Dock-style navigation**: Bottom floating bar with rounded corners
- **Circle avatars**: All hobby icons displayed as circular images (radius: 32)

### Code Conventions
- **File organization**: Follow existing `lib/src/` structure (models, providers, screens, services)
- **State management**: Use Riverpod exclusively, avoid other state management solutions
- **Naming**: Use descriptive Japanese text for UI labels, English for code identifiers
- **Error handling**: Always provide user-friendly Japanese error messages via SnackBar

### Data Management Rules
- **Image storage**: Always use UUID for image filenames to avoid conflicts
- **JSON persistence**: Maintain backward compatibility when modifying Hobby model
- **File operations**: Use path_provider for cross-platform directory access
- **State updates**: Always persist changes to JSON when modifying hobby list

### Feature Development Approach
- **Incremental**: Add features without breaking existing functionality
- **Simple UI**: Maintain clean, minimal interface focused on visual hobby icons
- **Local-first**: Prioritize offline functionality, avoid cloud dependencies
- **Performance**: Consider grid rendering performance for large hobby collections