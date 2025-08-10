// services/video_service.dart - Service untuk mengelola video, folder, dan thumbnail
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

/// Model data untuk item video
class VideoItem {
  final String name;
  final String path;
  final String duration;
  final String size;
  final DateTime lastModified;
  final String format;

  VideoItem({
    required this.name,
    required this.path,
    required this.duration,
    required this.size,
    required this.lastModified,
    required this.format,
  });

  /// Factory constructor untuk membuat VideoItem dari File
  static Future<VideoItem> fromFile(File file) async {
    final stat = await file.stat();
    final name = basename(file.path);
    final size = VideoService._formatFileSize(stat.size);
    final format = SupportedFormats.getFileFormat(file.path);

    // Dapatkan durasi video dengan error handling yang lebih baik
    String duration = '00:00';
    try {
      duration = await VideoService._getVideoDuration(file.path);
    } catch (e) {
      debugPrint('Error getting video duration for ${file.path}: $e');
    }

    return VideoItem(
      name: name,
      path: file.path,
      duration: duration,
      size: size,
      lastModified: stat.modified,
      format: format,
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

  /// Cache untuk menyimpan thumbnail yang sudah dibuat
  final Map<String, String> _thumbnailCache = {};

  /// Memuat video dari folder yang dipilih
  /// Returns [FolderContent] berisi daftar video dan subfolder
  Future<FolderContent> loadVideosFromFolder(String folderPath) async {
    final directory = Directory(folderPath);
    final List<VideoItem> videos = [];
    final List<VideoFolder> folders = [];

    try {
      // Validasi folder exists
      if (!await directory.exists()) {
        throw Exception('Folder does not exist: $folderPath');
      }

      final entities = await directory.list().toList();

      // Proses semua entities di folder
      for (var entity in entities) {
        try {
          if (entity is File) {
            // Cek apakah file adalah video yang didukung
            if (SupportedFormats.isVideoFile(entity.path)) {
              final videoItem = await VideoItem.fromFile(entity);
              videos.add(videoItem);
            }
          } else if (entity is Directory) {
            // Cek subfolder yang berisi video
            final subVideoCount = await _getVideoCountInFolder(entity.path);
            if (subVideoCount > 0) {
              final stat = await entity.stat();
              folders.add(VideoFolder(
                name: basename(entity.path),
                path: entity.path,
                videoCount: subVideoCount,
                lastModified: stat.modified,
              ));
            }
          }
        } catch (e) {
          debugPrint('Error processing entity ${entity.path}: $e');
        }
      }

      // Sort video berdasarkan nama
      videos
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      folders
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      debugPrint('Error loading videos from folder $folderPath: $e');
      rethrow;
    }

    return FolderContent(
      videos: videos,
      folders: folders,
      folderName: basename(folderPath),
      folderPath: folderPath,
    );
  }

  /// Memuat video dari list file yang dipilih
  Future<FolderContent> loadVideosFromFiles(List<String> filePaths) async {
    final List<VideoItem> videos = [];

    for (String filePath in filePaths) {
      try {
        final file = File(filePath);
        if (await file.exists() && SupportedFormats.isVideoFile(filePath)) {
          final videoItem = await VideoItem.fromFile(file);
          videos.add(videoItem);
        }
      } catch (e) {
        debugPrint('Error loading video file $filePath: $e');
      }
    }

    videos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return FolderContent(
      videos: videos,
      folders: [],
      folderName: 'Selected Videos',
      folderPath: '',
    );
  }

  /// Generate thumbnail untuk video
  /// Returns path ke file thumbnail atau null jika gagal
  Future<String?> generateThumbnail(String videoPath) async {
    // Cek cache terlebih dahulu
    if (_thumbnailCache.containsKey(videoPath)) {
      final cachedPath = _thumbnailCache[videoPath]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      } else {
        // Remove dari cache jika file sudah tidak ada
        _thumbnailCache.remove(videoPath);
      }
    }

    try {
      // Validasi file video exists
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        debugPrint('Video file does not exist: $videoPath');
        return null;
      }

      // Generate thumbnail
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: ThumbnailConfig.maxWidth,
        maxHeight: ThumbnailConfig.maxHeight,
        quality: ThumbnailConfig.quality,
      );

      if (thumbnailPath != null) {
        // Cache thumbnail path
        _thumbnailCache[videoPath] = thumbnailPath;
        return thumbnailPath;
      }
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
    }

    return null;
  }

  /// Validasi apakah video dapat diputar
  Future<bool> isVideoPlayable(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return false;

      // Test initialize video controller
      final controller = VideoPlayerController.file(file);
      await controller.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout initializing video'),
          );

      final isValid = controller.value.isInitialized &&
          controller.value.duration.inMilliseconds > 0;

      await controller.dispose();
      return isValid;
    } catch (e) {
      debugPrint('Video not playable $videoPath: $e');
      return false;
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

  /// Mendapatkan durasi video dengan error handling yang robust
  static Future<String> _getVideoDuration(String videoPath) async {
    VideoPlayerController? controller;

    try {
      final file = File(videoPath);
      controller = VideoPlayerController.file(file);

      // Timeout untuk prevent hanging
      await controller.initialize().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout getting video duration'),
          );

      final duration = controller.value.duration;
      return _formatDuration(duration);
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return '00:00';
    } finally {
      // Pastikan controller di-dispose
      try {
        await controller?.dispose();
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
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

  /// Format durasi video menjadi string yang readable
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// Clear thumbnail cache
  void clearThumbnailCache() {
    _thumbnailCache.clear();
  }

  /// Get cache size info
  int getThumbnailCacheSize() {
    return _thumbnailCache.length;
  }
}
