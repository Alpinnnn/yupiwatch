// screens/video_player_screen.dart - Halaman pemutar video dengan kontrol lengkap
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../services/video_service.dart';
import '../utils/constants.dart';

/// Halaman pemutar video dengan kontrol penuh dan handling error yang robust
class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerScreen({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Video controller dan state
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;

  // UI state
  bool _isFullscreen = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  /// Inisialisasi video player dengan error handling yang robust
  Future<void> _initializeVideoPlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Validasi file video
      final videoFile = File(widget.video.path);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found: ${widget.video.path}');
      }

      // Cek apakah video dapat diputar
      final isPlayable =
          await VideoService.instance.isVideoPlayable(widget.video.path);
      if (!isPlayable) {
        throw Exception('Video format not supported or file is corrupted');
      }

      // Inisialisasi controller
      _controller = VideoPlayerController.file(videoFile);

      // Setup listener untuk update UI
      _controller!.addListener(_videoPlayerListener);

      // Initialize dengan timeout
      await _controller!.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Video initialization timeout'),
          );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _duration = _controller!.value.duration;
        });

        // Auto play video
        await _controller!.play();
        setState(() {
          _isPlaying = true;
        });

        // Hide controls after 3 seconds
        _startControlsTimer();
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  /// Listener untuk update state video player
  void _videoPlayerListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final bool isPlaying = _controller!.value.isPlaying;
      final Duration position = _controller!.value.position;

      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
          _position = position;
        });
      }

      // Handle video selesai
      if (_controller!.value.position >= _controller!.value.duration) {
        _onVideoEnded();
      }
    }
  }

  /// Handle ketika video selesai diputar
  void _onVideoEnded() {
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
    }
  }

  /// Dispose video controller dengan aman
  Future<void> _disposeController() async {
    try {
      if (_controller != null) {
        _controller!.removeListener(_videoPlayerListener);
        await _controller!.dispose();
      }
    } catch (e) {
      debugPrint('Error disposing video controller: $e');
    }
  }

  /// Get error message yang user-friendly
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'Video loading timeout. Please check your file and try again.';
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return ErrorMessages.invalidVideoFormat;
    } else if (errorStr.contains('not found') ||
        errorStr.contains('no such file')) {
      return 'Video file not found. The file may have been moved or deleted.';
    } else if (errorStr.contains('permission')) {
      return ErrorMessages.permissionDenied;
    } else {
      return ErrorMessages.videoPlayFailed;
    }
  }

  /// Start timer untuk hide controls otomatis
  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls ? _buildAppBar() : null,
      body: _buildBody(),
      bottomSheet:
          _showControls && _isInitialized ? _buildBottomControls() : null,
    );
  }

  /// Build app bar dengan informasi video
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black87.withOpacity(0.8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.video.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: _toggleFullscreen,
        ),
      ],
    );
  }

  /// Build body utama dengan video player
  Widget _buildBody() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: _buildVideoContent(),
        ),
      ),
    );
  }

  /// Build konten video berdasarkan state
  Widget _buildVideoContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isInitialized && _controller != null) {
      return _buildVideoPlayer();
    }

    return _buildLoadingState();
  }

  /// Build state loading
  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          'Loading video...',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          widget.video.name,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build state error
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Cannot Play Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              ElevatedButton(
                onPressed: _retryInitialization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build video player
  Widget _buildVideoPlayer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),

        // Play/Pause button overlay
        if (_showControls)
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
      ],
    );
  }

  /// Build bottom controls
  Widget _buildBottomControls() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black87.withOpacity(0.8),
      ),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.grey,
            ),
          ),

          // Controls row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Row(
              children: [
                // Time display
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                // Control buttons
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                  ),
                  onPressed: _seekBackward,
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                  ),
                  onPressed: _seekForward,
                ),

                const Spacer(),

                // Fullscreen button
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle play/pause
  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _startControlsTimer();
      }
    }
  }

  /// Toggle controls visibility
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls && _isPlaying) {
      _startControlsTimer();
    }
  }

  /// Toggle fullscreen mode
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// Seek backward 10 seconds
  void _seekBackward() {
    if (_controller != null && _isInitialized) {
      final newPosition = _position - const Duration(seconds: 10);
      _controller!
          .seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  /// Seek forward 10 seconds
  void _seekForward() {
    if (_controller != null && _isInitialized) {
      final newPosition = _position + const Duration(seconds: 10);
      _controller!.seekTo(newPosition > _duration ? _duration : newPosition);
    }
  }

  /// Retry initialization setelah error
  void _retryInitialization() {
    _disposeController();
    _initializeVideoPlayer();
  }

  /// Format durasi menjadi string MM:SS atau HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
