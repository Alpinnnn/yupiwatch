# Discord Rich Presence Setup Guide

## ⚠️ PENTING: Langkah Wajib untuk Menampilkan Rich Presence

### Langkah 1: Membuat Discord Application

1. Buka [Discord Developer Portal](https://discord.com/developers/applications)
2. Klik "New Application" dan beri nama "Yupiwatch"
3. Salin **Application ID** dari halaman General Information
4. **WAJIB**: Ganti `_applicationId` di file `lib/services/discord_presence_service.dart` dengan Application ID yang sebenarnya

**Contoh:**
```dart
static const String _applicationId = '1316334066404077568'; // ← Ganti dengan ID asli
```

## Langkah 2: Upload Assets (Opsional)

Untuk menampilkan gambar di Discord Rich Presence:

1. Di Discord Developer Portal, buka tab "Rich Presence" → "Art Assets"
2. Upload gambar-gambar berikut:
   - `yupiwatch_logo` - Logo utama aplikasi (512x512 px)
   - `home_icon` - Icon untuk main menu (256x256 px)
   - `folder_icon` - Icon untuk folder view (256x256 px)
   - `play_icon` - Icon untuk video player (256x256 px)

## Langkah 3: Konfigurasi Application ID

Buka file `lib/services/discord_presence_service.dart` dan ganti:

```dart
static const String _applicationId = '1316334066404077568';
```

Dengan Application ID yang sebenarnya dari Discord Developer Portal.

## Status Discord Rich Presence

Aplikasi akan menampilkan status berikut:

### Main Menu
- **Details**: "Watching Yupiwatch"
- **State**: "Ready To Watch!"
- **Small Image**: Home icon

### Folder View
- **Details**: "Watching Yupiwatch"
- **State**: "Ready To Watch [Nama Folder]"
- **Small Image**: Folder icon

### Video Player
- **Details**: "Watching Yupiwatch"
- **State**: "Watching [Nama Video]!"
- **Small Image**: Play icon

## Troubleshooting

1. **Discord tidak menampilkan status**: 
   - Pastikan Discord desktop client berjalan
   - Pastikan Application ID sudah benar
   - Restart aplikasi Yupiwatch

2. **Gambar tidak muncul**:
   - Pastikan assets sudah diupload ke Discord Developer Portal
   - Nama asset harus sama persis dengan yang ada di kode

3. **Status tidak update**:
   - Check console log untuk error messages
   - Pastikan Discord RPC service berjalan dengan baik

## Implementasi

Discord Rich Presence sudah terintegrasi dengan:
- ✅ Main screen navigation
- ✅ Folder selection dan browsing
- ✅ Video player screen
- ✅ Automatic status updates
- ✅ Real-time presence changes

Status akan otomatis berubah saat user:
- Membuka aplikasi (Main Menu)
- Memilih dan browse folder (Folder View)
- Memutar video (Video Player)
- Kembali ke menu utama
