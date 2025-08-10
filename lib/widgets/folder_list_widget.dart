// widgets/folder_list_widget.dart - Widget untuk menampilkan daftar folder dalam bentuk horizontal playlist
import 'package:flutter/material.dart';
import '../services/video_service.dart';
import '../utils/constants.dart';

/// Widget untuk menampilkan daftar folder yang berisi video dalam bentuk horizontal scroll
class FolderListWidget extends StatelessWidget {
  final List<VideoFolder> folders;
  final Function(VideoFolder) onFolderTap;

  const FolderListWidget({
    Key? key,
    required this.folders,
    required this.onFolderTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header untuk section folder
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
          child: Row(
            children: [
              Icon(
                Icons.folder_special_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                'Folders',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${folders.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Horizontal list folder
        SizedBox(
          height: AppConstants.folderCardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return FolderCard(
                folder: folders[index],
                onTap: () => onFolderTap(folders[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget card untuk menampilkan informasi folder individual
class FolderCard extends StatefulWidget {
  final VideoFolder folder;
  final VoidCallback onTap;

  const FolderCard({
    Key? key,
    required this.folder,
    required this.onTap,
  }) : super(key: key);

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inisialisasi animasi untuk tap effect
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppConstants.shortAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.folderCardWidth,
      margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildCardContent(),
          );
        },
      ),
    );
  }

  /// Build konten card folder
  Widget _buildCardContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: _isPressed ? AppShadows.soft : AppShadows.medium,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: _buildFolderInfo(),
          ),
        ),
      ),
    );
  }

  /// Build informasi folder
  Widget _buildFolderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon folder dengan background gradient
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primaryVariant.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Nama folder
        Text(
          widget.folder.name,
          style: AppTextStyles.folderTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Jumlah video dalam folder
        Row(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _getVideoCountText(),
              style: AppTextStyles.videoMetadata,
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Tanggal modifikasi terakhir
        Text(
          _formatLastModified(),
          style: AppTextStyles.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Get text untuk jumlah video
  String _getVideoCountText() {
    final count = widget.folder.videoCount;
    if (count == 1) {
      return InfoMessages.videoCountSingle;
    }
    return InfoMessages.videoCountMultiple(count);
  }

  /// Format tanggal modifikasi terakhir
  String _formatLastModified() {
    final now = DateTime.now();
    final lastModified = widget.folder.lastModified;
    final difference = now.difference(lastModified);

    if (difference.inDays > 7) {
      return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Handle tap down untuk animasi
  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  /// Handle tap up untuk animasi
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  /// Handle tap cancel untuk animasi
  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }
}

/// Widget untuk menampilkan folder kosong atau loading
class FolderLoadingWidget extends StatelessWidget {
  const FolderLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.folderCardWidth,
      height: AppConstants.folderCardHeight,
      margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Loading...',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan placeholder folder
class FolderPlaceholderWidget extends StatelessWidget {
  final String message;

  const FolderPlaceholderWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.folderCardWidth,
      height: AppConstants.folderCardHeight,
      margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.3),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                color: AppColors.textTertiary,
                size: 32,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                message,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
