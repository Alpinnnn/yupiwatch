// services/video_service.dart - Service untuk mengelola video dengan media_kit
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename, join;
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import '../utils/constants.dart';

/// Model data untuk item video
class VideoItem {
  final String name;
  final String path;
  final String duration;
  final String size;
  final DateTime lastModified;
  final String format;
  final String? thumbnailPath;

  VideoItem({
    required this.name,
    required this.path,
    required this.duration,
    required this.size,
    required this.lastModified,
    required this.format,
    this.thumbnailPath,
  });

  /// Factory constructor untuk membuat VideoItem dari File
  static Future<VideoItem> fromFile(File file) async {
    final stat = await file.stat();
    final name = basename(file.path);
    final size = VideoService._formatFileSize(stat.size);
    final format = name.split('.').last.toUpperCase();
    
    // Get video duration
    final duration = await VideoService.instance.getVideoDuration(file.path);
    
    return VideoItem(
      name: name,
      path: file.path,
      duration: duration,
      size: size,
      lastModified: stat.modified,
      format: format,
      thumbnailPath: null, // Thumbnails disabled for Windows compatibility
    );
  }
  
  /// Factory constructor with duration (for when duration is already known)
  static VideoItem fromFileWithDuration(File file, FileStat stat, String duration) {
    final name = basename(file.path);
    final size = VideoService._formatFileSize(stat.size);
    final format = name.split('.').last.toUpperCase();
    
    return VideoItem(
      name: name,
      path: file.path,
      duration: duration,
      size: size,
      lastModified: stat.modified,
      format: format,
      thumbnailPath: null,
    );
  }
}

/// Model data untuk folder video
class VideoFolder {
  final String name;
  final String path;
  final int videoCount;
  final DateTime lastModified;

  VideoFolder({
    required this.name,
    required this.path,
    required this.videoCount,
    required this.lastModified,
  });
}

/// Model untuk hasil konten folder
class FolderContent {
  final List<VideoItem> videos;
  final List<VideoFolder> folders;
  final String folderName;
  final String folderPath;

  FolderContent({
    required this.videos,
    required this.folders,
    required this.folderName,
    required this.folderPath,
  });
}

/// Service utama untuk mengelola operasi video
class VideoService {
  static VideoService? _instance;
  static VideoService get instance => _instance ??= VideoService._();
  VideoService._();

  /// Load video dari folder dengan validasi dan optimasi loading
  Future<FolderContent> loadVideosFromFolder(String folderPath) async {
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      throw Exception('Folder not found: $folderPath');
    }

    final List<VideoItem> videos = [];
    final List<VideoFolder> subfolders = [];
    final List<Future<void>> videoProcessingFutures = [];
    final List<Future<void>> folderProcessingFutures = [];

    // Process files and folders in parallel for faster loading
    await for (final entity in folder.list()) {
      if (entity is File && SupportedFormats.isVideoFile(entity.path)) {
        videoProcessingFutures.add(_processVideoFile(entity, videos));
      } else if (entity is Directory) {
        folderProcessingFutures.add(_processFolder(entity, subfolders));
      }
    }

    // Wait for all processing to complete
    await Future.wait([...videoProcessingFutures, ...folderProcessingFutures]);

    // Sort videos by name
    videos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    subfolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return FolderContent(
      videos: videos,
      folders: subfolders,
      folderName: basename(folderPath),
      folderPath: folderPath,
    );
  }
  
  /// Process individual video file asynchronously
  Future<void> _processVideoFile(File file, List<VideoItem> videos) async {
    try {
      final videoItem = await VideoItem.fromFile(file);
      videos.add(videoItem);
    } catch (e) {
      debugPrint('Error processing video file ${file.path}: $e');
    }
  }
  
  /// Process individual folder asynchronously
  Future<void> _processFolder(Directory dir, List<VideoFolder> subfolders) async {
    try {
      final videoCount = await _getVideoCountInFolder(dir.path);
      if (videoCount > 0) {
        final stat = await dir.stat();
        final folderItem = VideoFolder(
          name: basename(dir.path),
          path: dir.path,
          videoCount: videoCount,
          lastModified: stat.modified,
        );
        subfolders.add(folderItem);
      }
    } catch (e) {
      debugPrint('Error processing folder ${dir.path}: $e');
    }
  }

  /// Load video dari list file dengan parallel processing
  Future<FolderContent> loadVideosFromFiles(List<String> filePaths) async {
    final List<VideoItem> videos = [];
    final List<Future<void>> processingFutures = [];

    // Process files in parallel for faster loading
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (await file.exists() && SupportedFormats.isVideoFile(filePath)) {
        processingFutures.add(_processVideoFile(file, videos));
      }
    }
    
    // Wait for all files to be processed
    await Future.wait(processingFutures);

    // Sort videos by name
    videos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return FolderContent(
      videos: videos,
      folders: [],
      folderName: 'Selected Videos',
      folderPath: '',
    );
  }

  /// Generate thumbnail - disabled for Windows compatibility
  Future<String?> generateThumbnail(String videoPath) async {
    // Return null to use placeholder thumbnails
    // This avoids the MissingPluginException on Windows
    debugPrint('Thumbnail generation disabled - using placeholder for: $videoPath');
    return null;
  }

  /// Get video duration with proper async handling
  Future<String> getVideoDuration(String videoPath) async {
    Player? player;
    try {
      // Use media_kit to get video duration
      player = Player();
      await player.open(Media(videoPath));
      
      // Wait for duration to be available with stream listener
      final completer = Completer<Duration>();
      late StreamSubscription subscription;
      
      subscription = player.stream.duration.listen((duration) {
        if (duration != Duration.zero && !completer.isCompleted) {
          completer.complete(duration);
          subscription.cancel();
        }
      });
      
      // Timeout after 3 seconds if no duration is found
      final duration = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => Duration.zero,
      );
      
      if (duration != Duration.zero) {
        return _formatDuration(duration);
      }
      
      return '00:00';
    } catch (e) {
      debugPrint('Error getting duration for $videoPath: $e');
      return '00:00';
    } finally {
      await player?.dispose();
    }
  }

  /// Format duration to readable string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Validasi video dan cek apakah bisa diputar
  Future<bool> isVideoPlayable(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists() || !SupportedFormats.isVideoFile(videoPath)) {
        return false;
      }
      
      // Quick validation using media_kit
      final player = Player();
      try {
        await player.open(Media(videoPath));
        await Future.delayed(const Duration(milliseconds: 200));
        final isPlayable = player.state.duration != Duration.zero;
        await player.dispose();
        return isPlayable;
      } catch (e) {
        await player.dispose();
        return false;
      }
    } catch (e) {
      debugPrint('Error validating video $videoPath: $e');
      return false;
    }
  }

  /// Clear thumbnail cache
  Future<void> clearThumbnailCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory(join(appDir.path, 'yupiwatch', 'thumbnails'));
      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  /// Menghitung jumlah video dalam folder
  Future<int> _getVideoCountInFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) return 0;

      final entities = await directory.list().toList();
      int count = 0;

      for (var entity in entities) {
        if (entity is File && SupportedFormats.isVideoFile(entity.path)) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Error counting videos in folder $folderPath: $e');
      return 0;
    }
  }

  /// Format ukuran file menjadi human-readable
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get thumbnail cache size
  Future<String> getThumbnailCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory(join(appDir.path, 'yupiwatch', 'thumbnails'));
      if (!await thumbnailDir.exists()) {
        return '0 B';
      }
      
      int totalSize = 0;
      await for (final entity in thumbnailDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return _formatFileSize(totalSize);
    } catch (e) {
      debugPrint('Error getting thumbnail cache size: $e');
      return '0 B';
    }
  }
}
