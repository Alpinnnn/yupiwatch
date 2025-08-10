// utils/constants.dart - Konstanta aplikasi untuk tema, warna, dan konfigurasi
import 'package:flutter/material.dart';

/// Konstanta umum aplikasi
class AppConstants {
  static const String appName = 'Video Player';
  static const String fontFamily = 'SF Pro Display';

  // Durasi animasi
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // Ukuran komponen UI
  static const double borderRadius = 16.0;
  static const double thumbnailWidth = 80.0;
  static const double thumbnailHeight = 60.0;
  static const double folderCardWidth = 200.0;
  static const double folderCardHeight = 120.0;

  // Padding standar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXLarge = 24.0;
}

/// Skema warna aplikasi dengan tema monochrome dan liquid glass
class AppColors {
  // Warna dasar
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8F8F8);

  // Warna teks
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Warna aksen
  static const Color primary = Color(0xFF2C2C2C);
  static const Color primaryVariant = Color(0xFF424242);

  // Glass effect colors
  static Color glassBackground = Colors.white.withOpacity(0.2);
  static Color glassBorder = Colors.white.withOpacity(0.3);

  // Shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.04);
  static Color shadowMedium = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.12);

  // FAB dan button colors
  static Color fabBackground = Colors.black.withOpacity(0.8);
  static Color buttonHover = Colors.grey.withOpacity(0.1);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

/// Style teks yang konsisten di seluruh aplikasi
class AppTextStyles {
  // Heading styles
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.2,
  );

  // Specialized styles
  static const TextStyle videoTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle videoMetadata = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle folderTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}

/// Shadow presets untuk konsistensi
class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get strong => [
        BoxShadow(
          color: AppColors.shadowDark,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Format file video yang didukung
class SupportedFormats {
  static const List<String> videoExtensions = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.3gp',
    '.webm',
    '.m4v',
    '.mpg',
    '.mpeg',
    '.ts',
    '.mts',
    '.m2ts'
  ];

  static const List<String> filePickerExtensions = [
    'mp4',
    'avi',
    'mkv',
    'mov',
    'wmv',
    'flv',
    '3gp',
    'webm',
    'm4v',
    'mpg',
    'mpeg',
    'ts',
    'mts',
    'm2ts'
  ];

  /// Mengecek apakah file adalah video yang didukung
  static bool isVideoFile(String filePath) {
    final extension = filePath.toLowerCase();
    return videoExtensions.any((ext) => extension.endsWith(ext));
  }

  /// Mendapatkan format file dari path
  static String getFileFormat(String filePath) {
    final parts = filePath.split('.');
    return parts.isNotEmpty ? parts.last.toUpperCase() : 'Unknown';
  }
}

/// Konfigurasi thumbnail video
class ThumbnailConfig {
  static const int maxWidth = 160;
  static const int maxHeight = 120;
  static const int quality = 75;
  static const Duration timeoutDuration = Duration(seconds: 10);
}

/// Pesan error yang user-friendly
class ErrorMessages {
  static const String folderSelectionFailed =
      'Failed to select folder. Please try again.';
  static const String fileSelectionFailed =
      'Failed to select video files. Please try again.';
  static const String videoLoadFailed =
      'Failed to load videos from the selected folder.';
  static const String videoPlayFailed =
      'Unable to play this video. The file may be corrupted.';
  static const String thumbnailGenerationFailed =
      'Failed to generate video thumbnail.';
  static const String permissionDenied =
      'Storage permission is required to access videos.';
  static const String noVideosFound = 'No videos found in the selected folder.';
  static const String invalidVideoFormat =
      'This video format is not supported.';
}

/// Pesan informasi untuk user
class InfoMessages {
  static const String selectFolderHint = 'Select a folder to browse videos';
  static const String loadingVideos = 'Loading videos...';
  static const String generatingThumbnail = 'Generating thumbnail...';
  static const String videoCountSingle = '1 video';
  static String videoCountMultiple(int count) => '$count videos';
}
