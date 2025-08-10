// widgets/video_list_widget.dart - Widget untuk menampilkan daftar video dengan thumbnail
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/video_service.dart';
import '../utils/constants.dart';

/// Widget untuk menampilkan daftar video dalam bentuk list
class VideoListWidget extends StatelessWidget {
  final List<VideoItem> videos;
  final Function(VideoItem) onVideoTap;

  const VideoListWidget({
    Key? key,
    required this.videos,
    required this.onVideoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          onTap: () => onVideoTap(videos[index]),
        );
      },
    );
  }

  /// Build state ketika tidak ada video
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_file_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            ErrorMessages.noVideosFound,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            InfoMessages.selectFolderHint,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget card untuk menampilkan informasi video individual
class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                // Thumbnail video
                VideoThumbnailWidget(video: video),

                const SizedBox(width: AppConstants.paddingMedium),

                // Informasi video
                Expanded(
                  child: _buildVideoInfo(),
                ),

                // Play icon
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.textTertiary,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build informasi video (nama, durasi, ukuran)
  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama video
        Text(
          video.name,
          style: AppTextStyles.videoTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Metadata video
        Row(
          children: [
            // Durasi
            Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              video.duration,
              style: AppTextStyles.videoMetadata,
            ),

            const SizedBox(width: AppConstants.paddingMedium),

            // Ukuran file
            Icon(
              Icons.storage_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              video.size,
              style: AppTextStyles.videoMetadata,
            ),

            const SizedBox(width: AppConstants.paddingMedium),

            // Format file
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryVariant.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.format,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan thumbnail video dengan loading state
class VideoThumbnailWidget extends StatefulWidget {
  final VideoItem video;

  const VideoThumbnailWidget({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.video.path.isNotEmpty) {
      _generateThumbnail();
    }
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate thumbnail jika video berubah
    if (oldWidget.video.path != widget.video.path) {
      _thumbnailPath = null;
      _hasError = false;
      if (widget.video.path.isNotEmpty) {
        _generateThumbnail();
      }
    }
  }

  /// Generate thumbnail dari video dengan error handling
  Future<void> _generateThumbnail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Skip thumbnail generation dan langsung show error state
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _thumbnailPath = null;
        _isLoading = false;
        _hasError = true; // Always show play icon instead
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.thumbnailWidth,
      height: AppConstants.thumbnailHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryVariant.withOpacity(0.3),
            AppColors.primary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildThumbnailContent(),
      ),
    );
  }

  /// Build konten thumbnail berdasarkan state
  Widget _buildThumbnailContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _thumbnailPath == null) {
      return _buildErrorState();
    }

    return _buildThumbnailImage();
  }

  /// Build loading state untuk thumbnail
  Widget _buildLoadingState() {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Build error state ketika thumbnail gagal dibuat
  Widget _buildErrorState() {
    return Center(
      child: Icon(
        Icons.play_circle_fill_rounded,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  /// Build thumbnail image
  Widget _buildThumbnailImage() {
    return Image.file(
      File(_thumbnailPath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading thumbnail image: $error');
        return _buildErrorState();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return Stack(
            children: [
              child,
              // Overlay play icon
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Show loading while image is loading
        return _buildLoadingState();
      },
    );
  }
}
