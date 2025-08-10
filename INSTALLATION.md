# 📋 Installation Guide

This guide will help you set up the Video Player App on your development environment and resolve common issues.

## 🔧 System Requirements

### Flutter SDK
- **Version**: 3.7.0 or higher
- **Channel**: Stable (recommended)
- **Dart**: 2.19.0 or higher

### Development Environment
- **Android Studio**: 2022.1+ or **VS Code** with Flutter extension
- **Xcode**: 14.0+ (for iOS development on macOS)
- **Git**: Latest version

### Target Platforms
- **Android**: API Level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Windows**: Windows 10+
- **macOS**: macOS 10.14+
- **Linux**: Ubuntu 18.04+

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-username/video-player-app.git
cd video-player-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

## ⚙️ Detailed Setup

### Flutter SDK Installation

#### Windows
1. Download Flutter SDK from [flutter.dev](https://flutter.dev)
2. Extract to `C:\development\flutter`
3. Add to PATH: `C:\development\flutter\bin`
4. Run `flutter doctor` to verify installation

#### macOS
```bash
# Using Homebrew
brew install flutter

# Or download manually
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.tar.xz | tar -xJ
export PATH="$PATH:`pwd`/flutter/bin"
```

#### Linux
```bash
# Download and extract
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

### Android Setup

#### Android Studio Installation
1. Install **Android Studio** from [developer.android.com](https://developer.android.com/studio)
2. Install Android SDK Platform-Tools
3. Install Android SDK Build-Tools
4. Create Android Virtual Device (AVD)

#### SDK Requirements
- **Compile SDK Version**: 34
- **Min SDK Version**: 21
- **Target SDK Version**: 34
- **Build Tools**: 34.0.0

#### Dependencies Installation
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Verify Android setup
flutter doctor -v
```

### iOS Setup (macOS only)

#### Xcode Installation
1. Install **Xcode** from Mac App Store
2. Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Accept Xcode license: `sudo xcodebuild -license`

#### CocoaPods Installation
```bash
# Install CocoaPods
sudo gem install cocoapods

# Setup CocoaPods
cd ios
pod install
cd ..
```

## 🔍 Dependencies Explanation

### Core Dependencies

#### Video Playback
```yaml
video_player: ^2.8.1        # Core video playback functionality
video_thumbnail: ^0.5.3     # Generate video thumbnails
chewie: ^1.7.1              # Advanced video player controls (optional)
```

#### File System
```yaml
file_picker: ^6.1.1         # Pick files and folders
path_provider: ^2.1.1       # Access device directories
path: ^1.8.3                # Path manipulation utilities
```

#### UI Enhancements
```yaml
flutter_staggered_animations: ^1.1.1  # Smooth list animations
intl: ^0.18.1                          # Date formatting
```

## 📱 Platform-Specific Configuration

### Android Configuration

#### 1. Update `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

#### 2. Add Permissions
The app requires several permissions that are already configured in `AndroidManifest.xml`:
- Storage access for reading video files
- Network access for potential streaming
- Wake lock for continuous playback

#### 3. File Provider Configuration
Create `android/app/src/main/res/xml/file_paths.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="external_files" path="." />
    <external-cache-path name="external_cache" path="." />
    <external-path name="external_storage" path="." />
</paths>
```

### iOS Configuration

#### 1. Update `ios/Runner.xcodeproj/project.pbxproj`
- Set **iOS Deployment Target**: 11.0
- Enable **Bitcode**: NO (for video_player compatibility)

#### 2. Add Capabilities
In Xcode project settings, add:
- **Background Modes**: Audio
- **File Sharing**: Enabled

#### 3. Info.plist Configuration
All required permissions are already configured in the provided `Info.plist` file.

## 🐛 Troubleshooting

### Common Issues

#### 1. "Flutter command not found"
**Solution**: Add Flutter to PATH
```bash
export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"
```

#### 2. "Android license status unknown"
**Solution**: Accept Android licenses
```bash
flutter doctor --android-licenses
```

#### 3. "CocoaPods not installed" (iOS)
**Solution**: Install CocoaPods
```bash
sudo gem install cocoapods
cd ios && pod install
```

#### 4. "Gradle build failed"
**Solution**: Clean and rebuild
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### 5. "Video not playing"
**Causes & Solutions**:
- **Unsupported format**: Convert to MP4/MOV
- **Corrupted file**: Try different video file
- **Permissions**: Grant storage permissions
- **Platform issue**: Test on different device/emulator

#### 6. "Thumbnail generation failed"
**Solutions**:
- Ensure video file is accessible
- Check available storage space
- Verify video file isn't corrupted
- Try smaller video files for testing

### Performance Issues

#### 1. Slow thumbnail generation
**Solutions**:
- Reduce thumbnail quality in `ThumbnailConfig`
- Implement lazy loading
- Add thumbnail caching
- Use smaller video files for testing

#### 2. Memory issues
**Solutions**:
- Dispose video controllers properly
- Clear thumbnail cache periodically
- Optimize image loading
- Profile memory usage with Flutter Inspector

### Build Issues

#### Android Build Fails
```bash
# Clean everything
flutter clean
cd android && ./gradlew clean && cd ..

# Get dependencies
flutter pub get

# Try building again
flutter build apk --debug
```

#### iOS Build Fails
```bash
# Clean iOS build
rm -rf ios/Pods ios/.symlinks ios/Podfile.lock
cd ios && pod install && cd ..

# Clean Flutter
flutter clean
flutter pub get

# Try building again
flutter build ios --debug --no-codesign
```

## 📊 Performance Optimization

### 1. Video Loading
- Use `VideoPlayerController.file()` for local files
- Implement proper error handling
- Add loading indicators
- Cache video metadata

### 2. Thumbnail Generation
- Generate thumbnails asynchronously
- Cache thumbnail paths
- Use appropriate thumbnail size
- Implement lazy loading for large lists

### 3. UI Performance
- Use `ListView.builder()` for large lists
- Implement proper dispose methods
- Avoid rebuilding expensive widgets
- Use `const` constructors where possible

## 🔐 Security Considerations

### File Access
- Validate file paths before accessing
- Handle permission denials gracefully
- Sanitize user input
- Use scoped storage on Android 10+

### Error Handling
- Don't expose sensitive file paths in errors
- Log errors securely
- Provide user-friendly error messages
- Handle edge cases gracefully

## 📈 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Device Testing
```bash
# Test on multiple devices
flutter devices
flutter run -d <device-id>

# Test different orientations
# Test different screen sizes
# Test with various video formats
```

## 🚢 Deployment

### Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS IPA
```bash
# Debug build
flutter build ios --debug --no-codesign

# Release build (requires valid certificates)
flutter build ios --release
```

## 📞 Support

If you encounter issues not covered in this guide:

1. **Check Flutter Doctor**: `flutter doctor -v`
2. **Review Error Logs**: Check console output
3. **Search Issues**: Look for similar problems on GitHub
4. **Create Issue**: Provide detailed information and logs

---

**Happy Coding! 🎉**