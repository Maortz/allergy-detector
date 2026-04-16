import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  final SupabaseClient _client;

  FeedbackService(this._client);

  Future<void> submitFeedback({
    required String productId,
    required String type,
    required String message,
  }) async {
    await _client.from('feedback_reports').insert({
      'product_id': productId,
      'type': type,
      'message': message,
    });
  }
}
