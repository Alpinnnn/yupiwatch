// main.dart - Entry point aplikasi video player
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart'; // Tambahkan import ini
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'services/discord_presence_service.dart';
import 'services/app_state_service.dart';

/// Entry point utama aplikasi
/// Memastikan binding Flutter diinisialisasi dengan benar
/// untuk mendukung video player di semua platform
void main() async {
  // Pastikan Flutter binding diinisialisasi sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  // Initialize services
  await DiscordPresenceService.instance.initialize();
  await AppStateService.instance.initialize();

  // Set orientasi default ke portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Jalankan aplikasi
  runApp(VideoPlayerApp());
}

/// Widget utama aplikasi dengan tema dan konfigurasi
class VideoPlayerApp extends StatelessWidget {
  const VideoPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const HomeScreen(),
    );
  }

  /// Membangun tema aplikasi dengan liquid glass design
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.grey,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppConstants.fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // App Bar theme untuk liquid glass effect
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.fontFamily,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
        ),
      ),

      // Bottom Navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
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
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.fabBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
