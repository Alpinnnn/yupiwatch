// screens/video_player_screen.dart - Video player dengan media_kit
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:io';
import '../services/video_service.dart';
import '../utils/constants.dart';

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
  late final Player player;
  late final VideoController controller;

  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

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

      // Play video
      await player.open(Media(widget.video.path));

      // Wait a bit untuk player ready
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startControlsTimer();
      }
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Cannot play this video: ${e.toString()}';
        });
      }
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
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
      body: Stack(
        children: [
          // Video content
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
              if (_showControls) _startControlsTimer();
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

          // Top controls overlay
          if (_showControls)
            Positioned(
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
                        onPressed: () => Navigator.pop(context),
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
                      IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
}
