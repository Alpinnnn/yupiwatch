# 🎥 Video Player App

A modern, feature-rich video player application built with Flutter, featuring a sleek liquid glass design and comprehensive local video support.

## ✨ Features

### 🎬 Video Playback
- **Multi-format support**: MP4, AVI, MKV, MOV, WMV, FLV, 3GP, WEBM, M4V, MPG, MPEG, TS, MTS, M2TS
- **Full-screen playback** with orientation support
- **Video controls**: Play/pause, seek, progress bar, time display
- **Auto-generated thumbnails** for all videos
- **Robust error handling** with user-friendly messages

### 📁 File Management
- **Folder browsing**: Select and browse entire video folders
- **Individual file selection**: Pick specific video files
- **Subfolder detection**: Automatically detect and display video subfolders as playlists
- **Real-time metadata**: Display video duration, file size, and format
- **Smart caching**: Thumbnail caching for improved performance

### 🎨 Modern UI/UX
- **Liquid glass design**: Frosted glass effects with blur backgrounds
- **Monochrome theme**: Clean black, white, and gray color scheme
- **Smooth animations**: Fade transitions and micro-interactions
- **Responsive layout**: Adapts to different screen sizes
- **Loading states**: Beautiful loading indicators throughout the app

### 🏗️ Architecture
- **Clean code structure**: Separated into logical modules
- **Service layer**: Centralized video management logic
- **Reusable widgets**: Modular UI components
- **Error handling**: Comprehensive error management
- **Performance optimized**: Efficient thumbnail generation and caching

## 📱 Screenshots

*Screenshots will be added soon*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.7.0)
- Dart SDK (>=2.19.0)
- Android Studio / VS Code
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/video-player-app.git
   cd video-player-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
The app requires storage permissions to access video files. Permissions are automatically handled in `AndroidManifest.xml`:

- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `READ_MEDIA_VIDEO` (Android 13+)
- `MANAGE_EXTERNAL_STORAGE`

#### iOS
Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to play videos</string>
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to record videos</string>
```

## 📂 Project Structure

```
lib/
├── main.dart                     # App entry point
├── screens/
│   ├── home_screen.dart         # Main screen with video list
│   └── video_player_screen.dart # Video playback screen
├── widgets/
│   ├── video_list_widget.dart   # Video list components
│   └── folder_list_widget.dart  # Folder playlist components
├── services/
│   └── video_service.dart       # Video management logic
└── utils/
    └── constants.dart           # App constants and themes
```

## 🏛️ Architecture Overview

### Service Layer
- **VideoService**: Manages video loading, thumbnail generation, and file operations
- **Singleton pattern**: Ensures consistent state management
- **Error handling**: Robust error management with user-friendly messages

### Widget Layer
- **Reusable components**: Modular widgets for different UI elements
- **State management**: Efficient state handling with StatefulWidget
- **Animation support**: Smooth transitions and micro-interactions

### Model Layer
- **VideoItem**: Represents individual video files with metadata
- **VideoFolder**: Represents folders containing videos
- **FolderContent**: Container for organized video content

## 🎨 Design System

### Color Scheme
- **Background**: Light gray (`#F5F5F5`)
- **Surface**: Pure white (`#FFFFFF`)
- **Text Primary**: Dark gray (`#1A1A1A`)
- **Text Secondary**: Medium gray (`#757575`)
- **Accent**: Black with transparency for glass effects

### Typography
- **Font Family**: SF Pro Display (system fallback)
- **Weights**: Regular (400), Medium (500), Semibold (600), Bold (700)
- **Sizes**: 10px - 24px with appropriate line heights

### Effects
- **Liquid Glass**: `BackdropFilter` with 10px blur
- **Shadows**: Layered shadows with different opacities
- **Animations**: 300ms duration with ease curves

## 🔧 Configuration

### Supported Video Formats
```dart
// Supported extensions
['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', 
 '.3gp', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts']
```

### Thumbnail Settings
```dart
// Thumbnail configuration
maxWidth: 160px
maxHeight: 120px
quality: 75%
format: JPEG
```

### Performance Settings
- **Caching**: Thumbnail paths cached in memory
- **Lazy loading**: Thumbnails generated on-demand
- **Timeout handling**: 10-15 second timeouts for operations

## 🐛 Troubleshooting

### Common Issues

#### Video won't play
- **Check file format**: Ensure the video format is supported
- **Verify file integrity**: Test the video file in other players
- **Check permissions**: Ensure storage permissions are granted

#### Thumbnails not generating
- **File access**: Verify the app can read the video file
- **Storage space**: Ensure sufficient storage for thumbnail cache
- **Video corruption**: Some corrupted videos can't generate thumbnails

#### App crashes on startup
- **Flutter version**: Ensure you're using Flutter 3.7.0+
- **Dependencies**: Run `flutter pub get` to install all dependencies
- **Platform setup**: Verify Android/iOS configuration is correct

### Error Messages

| Error | Cause | Solution |
|-------|--------|----------|
| "Video file not found" | File moved/deleted | Re-select the video folder |
| "Permission denied" | Storage access denied | Grant storage permissions |
| "Video format not supported" | Unsupported codec | Convert video to supported format |
| "Timeout initializing video" | Large/corrupted file | Try smaller video files |

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines

- **Code style**: Follow Dart/Flutter conventions
- **Documentation**: Add comments for complex logic
- **Testing**: Write tests for new features
- **Performance**: Optimize for smooth 60fps performance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **video_player plugin** for video playback capabilities  
- **video_thumbnail plugin** for thumbnail generation
- **file_picker plugin** for file selection functionality

## 📞 Support

If you encounter any issues or have questions:

- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Email**: contact@yourapp.com

---

## 🔄 Changelog

### v1.0.0 (Initial Release)
- ✅ Multi-format video support
- ✅ Liquid glass UI design
- ✅ Folder and file browsing
- ✅ Thumbnail generation
- ✅ Full-screen playback
- ✅ Error handling
- ✅ Performance optimization

### Upcoming Features
- 🔄 Playlist management
- 🔄 Video bookmarks
- 🔄 Subtitle support
- 🔄 Video editing tools
- 🔄 Cloud storage integration

---

**Made with ❤️ and Flutter**