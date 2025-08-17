// screens/home_screen.dart - Halaman utama aplikasi dengan daftar video dan navigasi
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import '../services/video_service.dart';
import '../services/discord_presence_service.dart';
import '../widgets/video_list_widget.dart';
import '../widgets/folder_list_widget.dart';
import '../utils/constants.dart';
import 'video_player_screen.dart';

/// Halaman utama aplikasi yang menampilkan daftar video dan folder
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // State variables
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Video service instance
  final VideoService _videoService = VideoService.instance;
  
  // Discord presence service instance
  final DiscordPresenceService _discordService = DiscordPresenceService.instance;

  // Current folder and video state
  FolderContent? _currentFolderContent;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSampleData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inisialisasi animasi untuk transisi halus
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  /// Load sample data saat pertama kali aplikasi dibuka
  void _loadSampleData() {
    final sampleVideos = [
      VideoItem(
        name: 'Sample Video 1.mp4',
        path: '',
        duration: '03:45',
        size: '24.5 MB',
        lastModified: DateTime.now(),
        format: 'MP4',
      ),
      VideoItem(
        name: 'Movie Trailer.mp4',
        path: '',
        duration: '02:30',
        size: '18.2 MB',
        lastModified: DateTime.now(),
        format: 'MP4',
      ),
      VideoItem(
        name: 'Documentary.mp4',
        path: '',
        duration: '45:12',
        size: '1.2 GB',
        lastModified: DateTime.now(),
        format: 'MP4',
      ),
    ];

    setState(() {
      _currentFolderContent = FolderContent(
        videos: sampleVideos,
        folders: [],
        folderName: 'Sample Videos',
        folderPath: '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildLiquidGlassAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildLiquidGlassBottomNav(),
    );
  }

  /// Membangun AppBar dengan efek liquid glass
  PreferredSizeWidget _buildLiquidGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Container(
                height: 60,
                child: Center(
                  child: Text(
                    AppConstants.appName,
                    style: AppTextStyles.appBarTitle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun body utama aplikasi
  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.only(top: 120, bottom: 90),
      child: _buildCurrentPage(),
    );
  }

  /// Membangun halaman berdasarkan navigation index
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildLibraryPage();
      case 2:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  /// Membangun halaman utama dengan daftar video
  Widget _buildHomePage() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentFolderContent == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan nama folder dan tombol browse
        _buildFolderHeader(),

        // Daftar folder jika ada
        if (_currentFolderContent!.folders.isNotEmpty) ...[
          const SizedBox(height: AppConstants.paddingMedium),
          FolderListWidget(
            folders: _currentFolderContent!.folders,
            onFolderTap: _onFolderTap,
          ),
        ],

        const SizedBox(height: AppConstants.paddingMedium),

        // Daftar video
        Expanded(
          child: VideoListWidget(
            videos: _currentFolderContent!.videos,
            onVideoTap: _onVideoTap,
          ),
        ),
      ],
    );
  }

  /// Membangun header folder dengan nama dan tombol browse
  Widget _buildFolderHeader() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              _currentFolderContent?.folderName ?? 'No Folder Selected',
              style: AppTextStyles.h3,
            ),
          ),
          IconButton(
            onPressed: _showFolderSelectionBottomSheet,
            icon: Icon(
              Icons.folder_open_outlined,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Browse Folder',
          ),
        ],
      ),
    );
  }

  /// Membangun state loading
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            InfoMessages.loadingVideos,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Membangun state error
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Error',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton(
              onPressed: _retryLoadVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun state kosong
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
          ),
        ],
      ),
    );
  }

  /// Membangun halaman library (placeholder)
  Widget _buildLibraryPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Library',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Your video library will appear here',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Membangun halaman settings (placeholder)
  Widget _buildSettingsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Settings',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'App settings and preferences',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Membangun Floating Action Button dengan efek glass
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.fab,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FloatingActionButton(
            onPressed: _showFolderSelectionBottomSheet,
            backgroundColor: AppColors.fabBackground,
            elevation: 0,
            child: const Icon(
              Icons.folder_open_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun Bottom Navigation Bar dengan efek liquid glass
  Widget _buildLiquidGlassBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTap,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.textPrimary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.video_library_outlined),
                activeIcon: Icon(Icons.video_library_rounded),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan bottom sheet untuk memilih sumber video
  void _showFolderSelectionBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadius + 8),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadius + 8),
              ),
            ),
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXLarge),

                // Title
                Text(
                  'Select Video Source',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppConstants.paddingXLarge),

                // Options
                _buildBottomSheetOption(
                  icon: Icons.folder_outlined,
                  title: 'Select Folder',
                  subtitle: 'Browse videos from folder',
                  onTap: () {
                    Navigator.pop(context);
                    _selectFolder();
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.video_file_outlined,
                  title: 'Select Video Files',
                  subtitle: 'Pick individual video files',
                  onTap: () {
                    Navigator.pop(context);
                    _selectVideoFiles();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun opsi dalam bottom sheet
  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Handle tap pada bottom navigation
  void _onBottomNavTap(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      // Update Discord presence based on navigation
      if (index == 0) {
        _discordService.setMainMenuStatus();
      }

      // Reset dan jalankan animasi
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// Handle tap pada folder
  void _onFolderTap(VideoFolder folder) async {
    await _loadVideosFromFolder(folder.path);
  }

  /// Handle tap pada video
  void _onVideoTap(VideoItem video) {
    if (video.path.isNotEmpty) {
      debugPrint('HomeScreen - _currentFolderContent?.folderName: ${_currentFolderContent?.folderName}');
      debugPrint('HomeScreen - _currentFolderContent == null: ${_currentFolderContent == null}');
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => VideoPlayerScreen(
            video: video,
            folderName: _currentFolderContent?.folderName,
            isManuallyPicked: _currentFolderContent == null,
          ),
        ),
      );
    } else {
      _showMessage(
          'This is a sample video. Select a real folder to play videos.');
    }
  }

  /// Memilih folder dari device
  Future<void> _selectFolder() async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        await _loadVideosFromFolder(selectedDirectory);
      }
    } catch (e) {
      _handleError(ErrorMessages.folderSelectionFailed, e);
    }
  }

  /// Memilih file video individual
  Future<void> _selectVideoFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: SupportedFormats.filePickerExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<String> filePaths = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();

        await _loadVideosFromFiles(filePaths);
      }
    } catch (e) {
      _handleError(ErrorMessages.fileSelectionFailed, e);
    }
  }

  /// Load video dari folder
  Future<void> _loadVideosFromFolder(String folderPath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final folderContent =
          await _videoService.loadVideosFromFolder(folderPath);

      setState(() {
        _currentFolderContent = folderContent;
        _isLoading = false;
      });

      // Update Discord presence to show folder view
      debugPrint('HomeScreen - loadVideosFromFolder folderContent.folderName: ${folderContent.folderName}');
      if (folderContent.folderName.isNotEmpty) {
        await _discordService.setFolderViewStatus(folderContent.folderName);
      }
    } catch (e) {
      _handleError(ErrorMessages.videoLoadFailed, e);
    }
  }

  /// Load video dari list file
  Future<void> _loadVideosFromFiles(List<String> filePaths) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final folderContent = await _videoService.loadVideosFromFiles(filePaths);

      setState(() {
        _currentFolderContent = folderContent;
        _isLoading = false;
      });

      // Update Discord presence to show folder view
      if (folderContent.folderName.isNotEmpty) {
        await _discordService.setFolderViewStatus(folderContent.folderName);
      }
    } catch (e) {
      _handleError(ErrorMessages.fileSelectionFailed, e);
    }
  }

  /// Retry load videos setelah error
  void _retryLoadVideos() {
    if (_currentFolderContent?.folderPath.isNotEmpty == true) {
      _loadVideosFromFolder(_currentFolderContent!.folderPath);
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// Handle error dengan menampilkan pesan yang sesuai
  void _handleError(String message, dynamic error) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

    debugPrint('Error: $message - $error');
    _showMessage(message);
  }

  /// Menampilkan pesan menggunakan SnackBar
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      );
    }
  }
}
