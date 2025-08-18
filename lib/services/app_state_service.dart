import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service untuk menyimpan dan memuat state aplikasi
/// Menggunakan SharedPreferences untuk persistensi data
class AppStateService {
  static const String _lastFolderPathKey = 'last_folder_path';
  static const String _lastVideoPathKey = 'last_video_path';
  static const String _lastVideoNameKey = 'last_video_name';
  static const String _lastFolderNameKey = 'last_folder_name';
  static const String _isManuallyPickedKey = 'is_manually_picked';
  static const String _hasLastStateKey = 'has_last_state';
  static const String _lastStateTypeKey = 'last_state_type'; // 'folder' or 'video'

  static AppStateService? _instance;
  static AppStateService get instance => _instance ??= AppStateService._();
  
  AppStateService._();

  SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Simpan state folder terakhir yang dibuka
  Future<void> saveLastFolderState({
    required String folderPath,
    required String folderName,
  }) async {
    await initialize();
    await _prefs!.setString(_lastFolderPathKey, folderPath);
    await _prefs!.setString(_lastFolderNameKey, folderName);
    await _prefs!.setString(_lastStateTypeKey, 'folder');
    await _prefs!.setBool(_hasLastStateKey, true);
    await _prefs!.setBool(_isManuallyPickedKey, false);
    
    // Clear video state when saving folder state
    await _prefs!.remove(_lastVideoPathKey);
    await _prefs!.remove(_lastVideoNameKey);
  }

  /// Simpan state screen terakhir (tidak menyimpan video individual)
  /// Hanya menyimpan context folder jika user sedang browsing folder
  Future<void> saveLastScreenState({
    String? folderPath,
    String? folderName,
    bool isManuallyPicked = false,
  }) async {
    await initialize();
    
    debugPrint('AppStateService: Saving screen state - folder: $folderName, path: $folderPath');
    
    if (folderPath != null && folderName != null) {
      // User is in folder view - save folder state
      await _prefs!.setString(_lastFolderPathKey, folderPath);
      await _prefs!.setString(_lastFolderNameKey, folderName);
      await _prefs!.setString(_lastStateTypeKey, 'folder');
      await _prefs!.setBool(_isManuallyPickedKey, isManuallyPicked);
      debugPrint('AppStateService: Saved folder state successfully');
    } else {
      // User is on main menu - clear folder state
      await _prefs!.setString(_lastStateTypeKey, 'main');
      await _prefs!.remove(_lastFolderPathKey);
      await _prefs!.remove(_lastFolderNameKey);
      debugPrint('AppStateService: Cleared folder state (main menu)');
    }
    
    await _prefs!.setBool(_hasLastStateKey, true);
    // Always clear video state - we don't restore videos
    await _prefs!.remove(_lastVideoPathKey);
    await _prefs!.remove(_lastVideoNameKey);
  }

  /// Dapatkan state screen terakhir yang disimpan
  Future<AppState?> getLastState() async {
    await initialize();
    
    debugPrint('AppStateService: Checking for saved state...');
    
    if (!(_prefs!.getBool(_hasLastStateKey) ?? false)) {
      debugPrint('AppStateService: No saved state found');
      return null;
    }

    final stateType = _prefs!.getString(_lastStateTypeKey);
    debugPrint('AppStateService: Found state type: $stateType');
    
    if (stateType == 'folder') {
      final folderPath = _prefs!.getString(_lastFolderPathKey);
      final folderName = _prefs!.getString(_lastFolderNameKey);
      
      debugPrint('AppStateService: Folder path: $folderPath, name: $folderName');
      
      if (folderPath != null && folderName != null) {
        return AppState.folder(
          folderPath: folderPath,
          folderName: folderName,
        );
      }
    }
    // Note: We no longer restore video states - only folder/main states
    
    debugPrint('AppStateService: No valid state to restore');
    return null;
  }

  /// Hapus semua state yang disimpan
  Future<void> clearState() async {
    await initialize();
    await _prefs!.remove(_lastFolderPathKey);
    await _prefs!.remove(_lastVideoPathKey);
    await _prefs!.remove(_lastVideoNameKey);
    await _prefs!.remove(_lastFolderNameKey);
    await _prefs!.remove(_isManuallyPickedKey);
    await _prefs!.remove(_hasLastStateKey);
    await _prefs!.remove(_lastStateTypeKey);
  }

  /// Cek apakah ada state yang tersimpan
  Future<bool> hasLastState() async {
    await initialize();
    return _prefs!.getBool(_hasLastStateKey) ?? false;
  }
}

/// Model untuk menyimpan state aplikasi
class AppState {
  final AppStateType type;
  final String? folderPath;
  final String? folderName;
  AppState._({
    required this.type,
    this.folderPath,
    this.folderName,
  });

  /// Constructor untuk state folder
  factory AppState.folder({
    required String folderPath,
    required String folderName,
  }) {
    return AppState._(
      type: AppStateType.folder,
      folderPath: folderPath,
      folderName: folderName,
    );
  }

  /// Constructor untuk state main menu
  factory AppState.main() {
    return AppState._(
      type: AppStateType.main,
    );
  }

  @override
  String toString() {
    return 'AppState(type: $type, folderName: $folderName)';
  }
}

/// Enum untuk tipe state aplikasi
enum AppStateType {
  folder,
  main,
}
