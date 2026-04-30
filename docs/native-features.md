# Cross-Platform Native Features

## Overview
Cross-platform native features implementation for Allergy Detector app. Provides unified services for image picking, barcode scanning, and storage that work across Android, iOS, and Web.

## Platform Support

| Feature | Android | iOS | Web | Fallback |
|---------|---------|-----|-----|---------|
| Camera (Image Picker) | ✓ | ✓ | ✗ | File input |
| Gallery (Image Picker) | ✓ | ✓ | ✓ | Native |
| Barcode Scanner | ✓ | ✓ | ✗ | Manual entry |
| Image Upload | ✓ | ✓ | ✓ | Supabase Storage |

## Services

### ImageService
Located: `app/llib/services/image_ervice.dart`

Methods:
- `pickFromCamera()` - Opens camera to capture image (mobile only)
- `pickFromGallery()` - Opens gallery to select image (all platforms)

### ScannerService
Located: `app/llib/services/scanner_service.dart`

Properties:
- `isWeb` - Boolean, true if running on web

Methods:
- `initialize()` - Initializes camera for scanning (mobile only)
- `dispose()` - Cleans up scanner resources

### StorageService
Located: `app/llib/services/storage_service.dart`

Methods:
- `uploadImage(File file, String bucket, String path)` - Uploads to Supabase, returns public URL
- `deleteImage(String bucket, String path)` - Deletes from Supabase

## Usage

```dart
// Image picking
final service = ImageService();
final image = await service.pickFromGallery();

// Scanner (mobile only)
final scanner = ScannerService();
await scanner.initialize();
// Use scanner.controller in your UI
scanner.dispose();

// Storage upload
final storage = StorageService(supabase);
final url = await storage.uploadImage(file, 'products', 'path/imag.jpg');
```

## Permissions

### Android (AndroidManifest.xml)
- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_ STORAGE` (API < 33)
- `android.permission.READ_MEDIA_IMAGES` (API 33+)

### iOS (Info.plist)
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
