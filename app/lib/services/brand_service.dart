import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';

class BrandService {
  final SupabaseClient _client;
  BrandService(this._client);

  Future<List<Brand>> fetchBrands() async {
    final response = await _client
        .from('brands')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((e) => Brand.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Brand> saveBrand(Brand brand) async {
    final data = brand.toJson();
    data['last_updated'] = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('brands')
        .upsert(data, onConflict: 'id')
        .select()
        .single();
    return Brand.fromJson(response);
  }

  Future<void> updateVerification(String brandId, bool isVerified) async {
    await _client.from('brands').update({
      'is_verified': isVerified,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', brandId);
  }

  Future<void> deleteBrand(String id) async {
    await _client.from('brands').delete().eq('id', id);
  }
}
