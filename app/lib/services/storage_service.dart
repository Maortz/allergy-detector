import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Uploads an image to Supabase Storage
  /// Returns the public URL on success, null on failure
  Future<String?> uploadImage(File file, String bucket, String path) async {
    try {
      final response = await _client.storage.from(bucket).upload(path, file);
      
      if (response.isNotEmpty) {
        final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
        return publicUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Deletes an image from Supabase Storage
  /// Returns true on success, false on failure
  Future<bool> deleteImage(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
