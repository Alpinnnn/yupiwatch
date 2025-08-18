// screens/video_player_screen.dart - Video player dengan media_kit
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pip_view/pip_view.dart';
import 'dart:io';
import 'dart:async';
import '../services/video_service.dart';
import '../services/discord_presence_service.dart';
import '../utils/constants.dart';
import '../widgets/video_list_widget.dart';
import 'home_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  final String? folderName;
  final bool isManuallyPicked;

  const VideoPlayerScreen({
    Key? key,
    required this.video,
    this.folderName,
    this.isManuallyPicked = false,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;

  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFullscreen = false;
  bool _isPlayerMaximized = true;
  bool _isPipMode = false;
  
  // Timer for auto-hiding controls
  Timer? _controlsTimer;
  
  // Discord presence service instance
  final DiscordPresenceService _discordService = DiscordPresenceService.instance;
  
  // Video service for getting playlist
  final VideoService _videoService = VideoService.instance;
  List<VideoItem> _playlistVideos = [];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadPlaylistVideos();
    
    // Update Discord presence to show video player status
    debugPrint('VideoPlayerScreen - folderName: ${widget.folderName}, isManuallyPicked: ${widget.isManuallyPicked}');
    _discordService.setVideoPlayerStatus(
      widget.video.name,
      folderName: widget.folderName,
      isManuallyPicked: widget.isManuallyPicked,
    );
  }

  @override
  void dispose() {
    // Cancel controls timer
    _controlsTimer?.cancel();
    // Don't reset Discord presence automatically - let navigation handle it
    // _discordService.setMainMenuStatus();
    player.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Validasi file
      final videoFile = File(widget.video.path);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found');
      }

      // Debug: pastikan MediaKit sudah initialized
      debugPrint('Initializing MediaKit player for: ${widget.video.path}');

      // Initialize MediaKit player
      player = Player();
      controller = VideoController(player);

      // Add listener untuk error handling
      player.stream.error.listen((error) {
        debugPrint('Player error: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Playback error: ${error.toString()}';
            _isLoading = false;
          });
        }
      });

      // Add listener untuk progress tracking untuk Discord Rich Presence
      player.stream.position.listen((position) {
        if (mounted) {
          _discordService.updateVideoProgress(position, player.state.duration);
        }
      });

      // Play video
      await player.open(Media(widget.video.path));

      // Wait a bit untuk player ready
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _startControlsTimer();
      }
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize player: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _startControlsTimer() {
    // Cancel any existing timer
    _controlsTimer?.cancel();
    
    // Start new timer to hide controls after 3 seconds
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  void _cancelControlsTimer() {
    _controlsTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PIPView(
      builder: (context, isFloating) {
        return _buildMainContent(isFloating);
      },
    );
  }

  Widget _buildMainContent(bool isFloating) {
    if (isFloating) {
      // PiP mode - show only video player without any overlays
      return Material(
        color: Colors.black,
        child: _buildContent(),
      );
    }

    // Normal mode - show full interface
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isPlayerMaximized ? _buildMaximizedPlayer() : _buildMinimizedPlayer(),
    );
  }

  Widget _buildMaximizedPlayer() {
    return Stack(
      children: [
        // Video content with hover detection
        MouseRegion(
          onEnter: (_) {
            setState(() {
              _showControls = true;
            });
            _startControlsTimer();
          },
          onExit: (_) {
            // Don't hide immediately on exit, let timer handle it
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls) {
                _startControlsTimer();
              } else {
                _cancelControlsTimer();
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: _buildContent(),
              ),
            ),
          ),
        ),

        // Top controls overlay with hover detection
        if (_showControls)
          MouseRegion(
            onEnter: (_) {
              // Keep controls visible when hovering over them
              _cancelControlsTimer();
            },
            onExit: (_) {
              // Restart timer when leaving controls area
              _startControlsTimer();
            },
            child: _buildTopControls(),
          ),
      ],
    );
  }

  Widget _buildMinimizedPlayer() {
    return Column(
      children: [
        // Minimized video player
        Container(
          height: 200,
          color: Colors.black,
          child: Stack(
            children: [
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _showControls = true;
                  });
                  _startControlsTimer();
                },
                onExit: (_) {
                  // Don't hide immediately on exit, let timer handle it
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                    if (_showControls) {
                      _startControlsTimer();
                    } else {
                      _cancelControlsTimer();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
              if (_showControls)
                MouseRegion(
                  onEnter: (_) {
                    // Keep controls visible when hovering over them
                    _cancelControlsTimer();
                  },
                  onExit: (_) {
                    // Restart timer when leaving controls area
                    _startControlsTimer();
                  },
                  child: _buildTopControls(),
                ),
            ],
          ),
        ),
        
        // Playlist/content area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _buildPlaylistContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: kToolbarHeight + MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Update Discord presence based on navigation context
                  if (widget.folderName != null && !widget.isManuallyPicked) {
                    _discordService.setFolderViewStatus(widget.folderName!);
                  } else {
                    _discordService.setMainMenuStatus();
                  }
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Text(
                  widget.video.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // PiP button
              IconButton(
                icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
                onPressed: _togglePipMode,
                tooltip: 'Picture in Picture',
              ),
              // Fullscreen/Player Size button (combined functionality)
              IconButton(
                icon: Icon(
                  _isFullscreen
                      ? Icons.fullscreen_exit
                      : (_isPlayerMaximized ? Icons.minimize : Icons.fullscreen),
                  color: Colors.white,
                ),
                onPressed: _toggleFullscreenOrPlayerSize,
                tooltip: _isFullscreen 
                    ? 'Exit Fullscreen' 
                    : (_isPlayerMaximized ? 'Minimize Player' : 'Maximize Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Row(
            children: [
              Icon(
                Icons.playlist_play,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                'Now Playing',
                style: AppTextStyles.h3,
              ),
            ],
          ),
        ),
        
        // Current video info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.name,
                        style: AppTextStyles.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.video.duration} • ${widget.video.size}',
                        style: AppTextStyles.videoMetadata,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingLarge),
        
        // Playlist section
        if (_playlistVideos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
            child: Text(
              'Playlist (${_playlistVideos.length} videos)',
              style: AppTextStyles.labelLarge,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Expanded(
            child: VideoListWidget(
              videos: _playlistVideos,
              onVideoTap: _onPlaylistVideoTap,
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_remove,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'No playlist available',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Hapus method _buildAppBar karena sudah tidak digunakan

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading video...',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      );
    }

    return Video(controller: controller);
  }

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

  void _togglePipMode() {
    try {
      setState(() {
        _isPipMode = !_isPipMode;
      });
      
      if (_isPipMode) {
        PIPView.of(context)?.presentBelow(const HomeScreen());
      }
    } catch (e) {
      debugPrint('PiP error: $e');
      // Reset PiP state if error occurs
      setState(() {
        _isPipMode = false;
      });
    }
  }

  void _togglePlayerSize() {
    setState(() {
      _isPlayerMaximized = !_isPlayerMaximized;
    });
  }

  void _toggleFullscreenOrPlayerSize() {
    if (_isFullscreen) {
      // Exit fullscreen
      _toggleFullscreen();
    } else {
      // Toggle player size or enter fullscreen
      if (_isPlayerMaximized) {
        // If maximized, minimize the player
        _togglePlayerSize();
      } else {
        // If minimized, maximize the player
        _togglePlayerSize();
      }
    }
  }

  void _onPlaylistVideoTap(VideoItem video) {
    // Handle playlist video selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          video: video,
          folderName: widget.folderName,
          isManuallyPicked: widget.isManuallyPicked,
        ),
      ),
    );
  }

  Future<void> _loadPlaylistVideos() async {
    if (widget.folderName != null && !widget.isManuallyPicked) {
      try {
        // Try to get videos from the same folder
        final videoFile = File(widget.video.path);
        final folderPath = videoFile.parent.path;
        final folderContent = await _videoService.loadVideosFromFolder(folderPath);
        
        setState(() {
          _playlistVideos = folderContent.videos
              .where((v) => v.path != widget.video.path)
              .toList();
        });
      } catch (e) {
        debugPrint('Error loading playlist videos: $e');
      }
    }
  }
}
