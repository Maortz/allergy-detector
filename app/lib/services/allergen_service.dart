import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';

class AllergenService {
  final SupabaseClient _client;

  AllergenService(this._client);

  Future<List<Allergen>> fetchAllergens() async {
    final response = await _client
        .from('allergens')
        .select()
        .timeout(const Duration(seconds: 10));
    return (response as List)
        .map((json) => Allergen.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}