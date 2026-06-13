/// Uploads a captured product photo to remote storage and returns its URL.
///
/// The add-product wizard (spec §7.3) defers the *real* Supabase Storage upload
/// to the final step-4 submit, so the default implementation here is an
/// intentional no-op that echoes the local path back — it exists purely so the
/// step-2 tile can model an upload lifecycle (idle → uploading → error/done)
/// and surface a retry affordance on failure (spec §5). Tests inject a stub
/// that fails on demand to exercise the error → retry → success path.
class PhotoUploadService {
  const PhotoUploadService();

  /// Uploads the image at [localPath] and resolves with its remote URL.
  ///
  /// The base implementation succeeds immediately, echoing [localPath] back —
  /// no network call is made (real storage wiring is out of scope per §7.3).
  Future<String> upload(String localPath) async => localPath;
}
