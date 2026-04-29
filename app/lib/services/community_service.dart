import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final SupabaseClient _client;
  CommunityService(this._client);

  Future<List<Map<String, dynamic>>> fetchPendingProducts() async {
    return await _client
        .from('products')
        .select('*, brands(name_he)')
        .eq('is_archived', false)
        .filter('last_reviewed_at', 'is', 'null')
        .limit(20);
  }

  Future<void> markProductReviewed(String productId) async {
    await _client.from('products').update({
      'last_reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }
}