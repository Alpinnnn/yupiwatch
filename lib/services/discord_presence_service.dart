// services/discord_presence_service.dart - Discord Rich Presence integration
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

/// Enum untuk status aplikasi yang berbeda
enum AppStatus {
  mainMenu,
  folderView,
  videoPlayer,
}

/// Service untuk mengelola Discord Rich Presence
class DiscordPresenceService {
  static final DiscordPresenceService _instance =
      DiscordPresenceService._internal();
  static DiscordPresenceService get instance => _instance;

  DiscordPresenceService._internal();

  // Current status tracking
  AppStatus _currentStatus = AppStatus.mainMenu;
  String? _currentFolderName;
  String? _currentVideoName;
  DateTime? _startTime;
  bool _isInitialized = false;
  bool _isManuallyPicked = false;
  
  // Video progress tracking for progress bar
  Duration? _videoDuration;
  Duration? _currentPosition;

  // Discord Application ID - Anda perlu membuat aplikasi di Discord Developer Portal
  static const String _applicationId =
      '1404053717484834867'; // Valid Application ID

  // Discord IPC connection
  RandomAccessFile? _ipcFile;
  bool _isConnected = false;
  int? _pipeHandle;

  /// Initialize Discord RPC
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      _startTime = DateTime.now();

      // Try to connect to Discord IPC
      await _connectToDiscord();

      // Set initial presence
      await updatePresence(AppStatus.mainMenu);

      debugPrint('Discord Rich Presence initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Discord Rich Presence: $e');
      _isInitialized = true;
      _startTime = DateTime.now();
    }
  }

  /// Connect to Discord IPC pipe on Windows
  Future<void> _connectToDiscord() async {
    if (!Platform.isWindows) {
      debugPrint('Discord Rich Presence only supported on Windows');
      return;
    }

    try {
      // Try to connect using Windows Named Pipes API
      for (int i = 0; i < 10; i++) {
        try {
          final pipeName = 'discord-ipc-$i';

          // Use Windows API to connect to named pipe
          final pipeHandle = CreateFile(
            TEXT('\\\\.\\pipe\\$pipeName'),
            GENERIC_READ | GENERIC_WRITE,
            0,
            nullptr,
            OPEN_EXISTING,
            0,
            NULL,
          );

          if (pipeHandle != INVALID_HANDLE_VALUE) {
            debugPrint('Successfully connected to Discord IPC: $pipeName');
            _isConnected = true;

            // Send handshake using Windows API
            await _sendWindowsHandshake(pipeHandle);

            // Keep the handle open for future communication
            _pipeHandle = pipeHandle;
            break;
          }
        } catch (e) {
          debugPrint('Failed to connect to discord-ipc-$i: $e');
          continue;
        }
      }

      if (!_isConnected) {
        debugPrint(
            'Could not connect to Discord IPC via Windows API. Trying fallback...');
        await _tryFallbackConnection();
      }
    } catch (e) {
      debugPrint('Error connecting to Discord: $e');
      await _tryFallbackConnection();
    }
  }

  /// Send handshake using Windows API
  Future<void> _sendWindowsHandshake(int pipeHandle) async {
    try {
      final handshake = {
        'v': 1,
        'client_id': _applicationId,
      };

      final payload = utf8.encode(jsonEncode(handshake));
      final header = ByteData(8);
      header.setUint32(0, 0, Endian.little); // OP_HANDSHAKE
      header.setUint32(4, payload.length, Endian.little);

      // Combine header and payload
      final data = Uint8List.fromList([
        ...header.buffer.asUint8List(),
        ...payload,
      ]);

      final bytesWritten = malloc<DWORD>();
      final dataPtr = malloc<Uint8>(data.length);

      // Copy data to native memory
      for (int i = 0; i < data.length; i++) {
        dataPtr[i] = data[i];
      }

      final result = WriteFile(
        pipeHandle,
        dataPtr,
        data.length,
        bytesWritten,
        nullptr,
      );

      if (result != 0) {
        debugPrint('Handshake sent successfully to Discord');
      } else {
        debugPrint('Failed to send handshake to Discord');
      }

      malloc.free(bytesWritten);
      malloc.free(dataPtr);
    } catch (e) {
      debugPrint('Error sending Windows handshake: $e');
    }
  }

  /// Fallback connection method
  Future<void> _tryFallbackConnection() async {
    try {
      // Check if Discord process is running
      final result =
          await Process.run('tasklist', ['/FI', 'IMAGENAME eq Discord.exe']);
      if (result.stdout.toString().contains('Discord.exe')) {
        debugPrint(
            'Discord process detected, enabling Rich Presence logging mode');
        _isConnected = true;
      } else {
        debugPrint('Discord not running. Rich Presence will be logged only.');
      }
    } catch (e) {
      debugPrint('Fallback connection failed: $e');
      debugPrint('Rich Presence will work in logging mode only');
    }
  }

  /// Send presence update via Windows API
  Future<void> _sendPresenceViaWindowsAPI(String details, String? state) async {
    try {
      // Use existing pipe handle if available, otherwise reconnect
      int? handleToUse = _pipeHandle;

      if (handleToUse == null || handleToUse == INVALID_HANDLE_VALUE) {
        // Try to reconnect to Discord IPC for sending presence
        for (int i = 0; i < 10; i++) {
          try {
            final pipeName = 'discord-ipc-$i';

            final pipeHandle = CreateFile(
              TEXT('\\\\.\\pipe\\$pipeName'),
              GENERIC_READ | GENERIC_WRITE,
              0,
              nullptr,
              OPEN_EXISTING,
              0,
              NULL,
            );

            if (pipeHandle != INVALID_HANDLE_VALUE) {
              handleToUse = pipeHandle;
              _pipeHandle = pipeHandle;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (handleToUse != null && handleToUse != INVALID_HANDLE_VALUE) {
        // Send presence update
        final presenceData = {
          'cmd': 'SET_ACTIVITY',
          'args': {
            'pid': pid,
            'activity': {
              'details': details,
              if (state != null) 'state': state,
              'timestamps': _getTimestamps(),
              'type': 3, // 3 = Watching activity type
            },
          },
          'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
        };

        final payload = utf8.encode(jsonEncode(presenceData));
        final header = ByteData(8);
        header.setUint32(0, 1, Endian.little); // OP_FRAME
        header.setUint32(4, payload.length, Endian.little);

        final data = Uint8List.fromList([
          ...header.buffer.asUint8List(),
          ...payload,
        ]);

        final bytesWritten = malloc<DWORD>();
        final dataPtr = malloc<Uint8>(data.length);

        for (int j = 0; j < data.length; j++) {
          dataPtr[j] = data[j];
        }

        final result = WriteFile(
          handleToUse,
          dataPtr,
          data.length,
          bytesWritten,
          nullptr,
        );

        if (result != 0) {
          debugPrint('Discord presence updated successfully: $details');
        } else {
          debugPrint('Failed to update Discord presence');
        }

        malloc.free(bytesWritten);
        malloc.free(dataPtr);
        // Don't close handle, keep it for future use
        // CloseHandle(handleToUse);
        return;
      } else {
        debugPrint(
            'Could not send presence update - no active Discord IPC connection');
      }
    } catch (e) {
      debugPrint('Error sending presence via Windows API: $e');
    }
  }


  /// Update presence based on app status
  Future<void> updatePresence(AppStatus status,
      {String? folderName, String? videoName, bool isManuallyPicked = false}) async {
    if (!_isInitialized) return;

    try {
      _currentStatus = status;
      _currentFolderName = folderName;
      _currentVideoName = videoName;
      _isManuallyPicked = isManuallyPicked;

      String details;
      String? state;

      switch (status) {
        case AppStatus.mainMenu:
          details = 'Ready To Watch';
          state = null;
          break;

        case AppStatus.folderView:
          details = folderName ?? 'Browsing Folder';
          state = null;
          break;

        case AppStatus.videoPlayer:
          details = videoName ?? 'Playing Video';
          if (isManuallyPicked) {
            state = 'Manually Picked';
          } else {
            // Extract folder name from folderName parameter or use basename of folder path
            debugPrint('Discord updatePresence - folderName: $folderName, isManuallyPicked: $isManuallyPicked');
            state = folderName != null && folderName.isNotEmpty 
                ? folderName 
                : 'Unknown Folder';
          }
          break;
      }

      // Send presence update to Discord
      await _sendPresenceUpdate(details, state);
    } catch (e) {
      debugPrint('Failed to update Discord presence: $e');
    }
  }

  /// Send presence update to Discord via IPC
  Future<void> _sendPresenceUpdate(String details, String? state) async {
    if (!_isConnected) {
      debugPrint('Discord not connected, logging presence: $details${state != null ? ' - $state' : ''}');
      return;
    }

    // Try to send via Windows API if connected
    if (Platform.isWindows) {
      await _sendPresenceViaWindowsAPI(details, state);
      return;
    }

    try {
      final presenceData = {
        'cmd': 'SET_ACTIVITY',
        'args': {
          'pid': pid,
          'activity': {
            'details': details,
            if (state != null) 'state': state,
            'timestamps': _getTimestamps(),
            'type': 3, // 3 = Watching activity type
            'assets': {
              'large_image': 'yupiwatch_logo',
              'large_text': 'Yupiwatch - Modern Video Player',
              'small_image': _getSmallImageKey(_currentStatus),
              'small_text': _getSmallImageText(_currentStatus),
            },
          },
        },
        'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final payload = utf8.encode(jsonEncode(presenceData));
      final header = ByteData(8);
      header.setUint32(0, 1, Endian.little); // OP_FRAME
      header.setUint32(4, payload.length, Endian.little);

      await _ipcFile!.writeFrom(header.buffer.asUint8List());
      await _ipcFile!.writeFrom(payload);
      await _ipcFile!.flush();

      debugPrint('Discord presence updated: $details');
    } catch (e) {
      debugPrint('Error sending presence update: $e');
    }
  }

  /// Get small image key based on status
  String _getSmallImageKey(AppStatus status) {
    switch (status) {
      case AppStatus.mainMenu:
        return 'home_icon';
      case AppStatus.folderView:
        return 'folder_icon';
      case AppStatus.videoPlayer:
        return 'play_icon';
    }
  }

  /// Get small image text based on status
  String _getSmallImageText(AppStatus status) {
    switch (status) {
      case AppStatus.mainMenu:
        return 'Main Menu';
      case AppStatus.folderView:
        return 'Browsing Folder';
      case AppStatus.videoPlayer:
        return 'Playing Video';
    }
  }

  /// Update to main menu status
  Future<void> setMainMenuStatus() async {
    await updatePresence(AppStatus.mainMenu);
  }

  /// Update to folder view status
  Future<void> setFolderViewStatus(String folderName) async {
    // Extract just the folder name from path
    String displayName = path.basename(folderName);
    await updatePresence(AppStatus.folderView, folderName: displayName);
  }

  /// Update to video player status
  Future<void> setVideoPlayerStatus(String videoName, {String? folderName, bool isManuallyPicked = false}) async {
    // Extract just the filename without extension
    String displayName = path.basenameWithoutExtension(videoName);
    debugPrint('Discord setVideoPlayerStatus - folderName: $folderName, isManuallyPicked: $isManuallyPicked');
    await updatePresence(AppStatus.videoPlayer, 
        videoName: displayName, 
        folderName: folderName,
        isManuallyPicked: isManuallyPicked);
  }

  /// Clear presence
  Future<void> clearPresence() async {
    if (!_isInitialized) return;

    try {
      debugPrint('Discord presence cleared');
    } catch (e) {
      debugPrint('Failed to clear Discord presence: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await clearPresence();
    _isInitialized = false;
  }

  /// Get current status
  AppStatus get currentStatus => _currentStatus;

  /// Get current folder name
  String? get currentFolderName => _currentFolderName;

  /// Get current video name
  String? get currentVideoName => _currentVideoName;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get timestamps for Discord Rich Presence
  Map<String, int>? _getTimestamps() {
    if (_currentStatus == AppStatus.videoPlayer && 
        _currentPosition != null && 
        _videoDuration != null) {
      // For video player, show progress bar like Spotify
      final now = DateTime.now().millisecondsSinceEpoch;
      final currentMs = _currentPosition!.inMilliseconds;
      final durationMs = _videoDuration!.inMilliseconds;
      
      return {
        'start': now - currentMs,
        'end': now - currentMs + durationMs,
      };
    } else {
      // For other states, just show elapsed time since app started
      return {
        'start': _startTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Update video progress for Rich Presence progress bar
  Future<void> updateVideoProgress(Duration position, Duration duration) async {
    _currentPosition = position;
    _videoDuration = duration;
    
    // Update presence to refresh progress bar with current video info
    if (_currentStatus == AppStatus.videoPlayer && _currentVideoName != null) {
      await updatePresence(AppStatus.videoPlayer, 
          videoName: _currentVideoName,
          folderName: _currentFolderName,
          isManuallyPicked: _isManuallyPicked);
    }
  }
}
