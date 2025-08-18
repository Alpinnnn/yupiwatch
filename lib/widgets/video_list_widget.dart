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
class VideoThumbnailWidget extends StatelessWidget {
  final VideoItem video;

  const VideoThumbnailWidget({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: video.thumbnailPath != null && File(video.thumbnailPath!).existsSync()
            ? Stack(
                children: [
                  Image.file(
                    File(video.thumbnailPath!),
                    width: 120,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildThumbnailPlaceholder();
                    },
                  ),
                  // Play button overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : _buildThumbnailPlaceholder(),
      ),
    );
  }

  /// Build thumbnail placeholder
  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 120,
      height: 68,
      color: AppColors.surface.withOpacity(0.3),
      child: const Icon(
        Icons.play_circle_outline,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }
}
