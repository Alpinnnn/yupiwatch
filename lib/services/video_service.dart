// services/video_service.dart - Service untuk mengelola video dengan media_kit
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename;
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

    return VideoItem(
      name: name,
      path: file.path,
      duration: '00:00', // Default duration
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

  /// Memuat video dari folder yang dipilih
  Future<FolderContent> loadVideosFromFolder(String folderPath) async {
    final directory = Directory(folderPath);
    final List<VideoItem> videos = [];
    final List<VideoFolder> folders = [];

    try {
      if (!await directory.exists()) {
        throw Exception('Folder does not exist: $folderPath');
      }

      final entities = await directory.list().toList();

      for (var entity in entities) {
        try {
          if (entity is File) {
            if (SupportedFormats.isVideoFile(entity.path)) {
              final videoItem = await VideoItem.fromFile(entity);
              videos.add(videoItem);
            }
          } else if (entity is Directory) {
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

  /// Generate thumbnail - disabled untuk sementara
  Future<String?> generateThumbnail(String videoPath) async {
    return null;
  }

  /// Validasi video - simplified
  Future<bool> isVideoPlayable(String videoPath) async {
    try {
      final file = File(videoPath);
      return await file.exists() && SupportedFormats.isVideoFile(videoPath);
    } catch (e) {
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
}
