import 'dart:convert';
import 'dart:io';

const _offApiBase = 'https://world.openfoodfacts.org/api/v2';

final _allergenMappingEn = {
  'en:gluten': ('Gluten', 'גלוטן', '🌾'),
  'en:sesame-seeds': ('Sesame', 'שומשום', '🌻'),
  'en:sesame': ('Sesame', 'שומשום', '🌻'),
  'en:milk': ('Milk', 'חלב', '🥛'),
  'en:soybeans': ('Soy', 'סויה', '🫘'),
  'en:soy': ('Soy', 'סויה', '🫘'),
  'en:eggs': ('Eggs', 'ביצים', '🥚'),
  'en:egg': ('Eggs', 'ביצים', '🥚'),
  'en:nuts': ('Tree Nuts', 'אגוזים', null),
  'en:peanuts': ('Peanuts', 'בוטנים', '🥜'),
  'en:mustard': ('Mustard', 'חרדל', '🟡'),
  'en:celery': ('Celery', 'סלרי', '🥬'),
  'en:fish': ('Fish', 'דג', '🐟'),
  'en:lupin': ('Lupin', 'לופין', '🫘'),
  'en:molluscs': ('Molluscs', 'רכיכות', '🐚'),
  'en:crustaceans': ('Crustaceans', 'סרטנים', '🦐'),
  'en:sulphur-dioxide': ('Sulphur Dioxide', 'גפרית דו-חמצנית', '⚠️'),
  'en:oatmeal': ('Oats', 'שיבולת שועל', '🌾'),
  'en:oats': ('Oats', 'שיבולת שועל', '🌾'),
  'en:wheat': ('Wheat', 'חיטה', '🌾'),
  'en:barley': ('Barley', 'שעורה', null),
  'en:rye': ('Rye', 'שיפון', '🌾'),
  'en:shellfish': ('Shellfish', 'סרטנים', '🦐'),
  'en:mustard-seeds': ('Mustard', 'חרדל', '🟡'),
  'he:לוז': ('Hazelnuts', 'אגוזי לוז', '🌰'),
  'he:שיבולת-שועל': ('Oats', 'שיבולת שועל', '🌾'),
  'he:שעורה': ('Barley', 'שעורה', null),
  'he:חיטה': ('Wheat', 'חיטה', '🌾'),
  'he:גלוטן': ('Gluten', 'גלוטן', '🌾'),
  'he:חלב': ('Milk', 'חלב', '🥛'),
  'he:סויה': ('Soy', 'סויה', '🫘'),
  'he:ביצים': ('Eggs', 'ביצים', '🥚'),
  'he:אגוזים': ('Tree Nuts', 'אגוזים', null),
  'he:בוטנים': ('Peanuts', 'בוטנים', '🥜'),
  'he:חרדל': ('Mustard', 'חרדל', '🟡'),
  'he:סלרי': ('Celery', 'סלרי', '🥬'),
  'he:דג': ('Fish', 'דג', '🐟'),
  'he:שומשום': ('Sesame', 'שומשום', '🌻'),
};

final _brandNormalization = {
  'עלית': 'עלית',
  'elite': 'עלית',
  'אליט': 'עלית',
  'תנובה': 'תנובה',
  'טנובה': 'תנובה',
  'tnuva': 'תנובה',
  'tnuvago': 'תנובה',
  'tnuva go': 'תנובה',
  'שטראוס': 'שטראוס',
  'strauss': 'שטראוס',
  'יטבתה': 'יטבתה',
  'yotvata': 'יטבתה',
};

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run import-openfoodfacts.dart <barcode> [--dry-run]');
    stderr.writeln('       dart run import-openfoodfacts.dart --batch <file.csv>');
    exit(1);
  }

  final envFile = File('env.local.json');
  if (!envFile.existsSync()) {
    stderr.writeln('Error: env.local.json file not found.');
    exit(1);
  }

  final envData = jsonDecode(await envFile.readAsString());
  final supabaseUrl = envData['SUPABASE_URL'] as String?;
  final supabaseKey = envData['SUPABASE_KEY'] as String?;
  if (supabaseUrl == null || supabaseKey == null) {
    stderr.writeln('Error: SUPABASE_URL and SUPABASE_KEY must be set in env.local.json');
    exit(1);
  }

  final isDryRun = args.contains('--dry-run');
  final client = HttpClient();
  final baseUrl = '$supabaseUrl/rest/v1';

  Future<List<dynamic>> supabaseGet(String table, String filter) async {
    final request = await client.getUrl(Uri.parse('$baseUrl/$table?$filter'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded;
    }
    return [];
  }

  Future<String?> supabaseInsert(String table, Map<String, dynamic> data) async {
    if (isDryRun) {
      stdout.writeln('[DRY RUN] Would insert into $table: $data');
      return null;
    }
    final request = await client.postUrl(Uri.parse('$baseUrl/$table'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.headers.set('Prefer', 'return=representation');
    final jsonBody = jsonEncode(data);
    request.add(utf8.encode(jsonBody));
    final response = await request.close();
    if (response.statusCode != 201) {
      final body = await response.transform(utf8.decoder).join();
      stderr.writeln('Error inserting into $table: ${response.statusCode} $body');
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    final result = jsonDecode(body) as List;
    return result.isNotEmpty ? (result[0] as Map<String, dynamic>)['id'] as String? : null;
  }

  Future<bool> supabaseUpdate(String table, String id, Map<String, dynamic> data) async {
    if (isDryRun) {
      stdout.writeln('[DRY RUN] Would update $table/$id: $data');
      return true;
    }
    final request = await client.patchUrl(Uri.parse('$baseUrl/$table?id=eq.$id'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.headers.set('Prefer', 'return=representation');
    final jsonBody = jsonEncode(data);
    request.add(utf8.encode(jsonBody));
    final response = await request.close();
    if (response.statusCode != 200) {
      final body = await response.transform(utf8.decoder).join();
      stderr.writeln('Error updating $table/$id: ${response.statusCode} $body');
      return false;
    }
    return true;
  }

  Future<bool> supabaseDelete(String table, String filter) async {
    if (isDryRun) {
      stdout.writeln('[DRY RUN] Would delete from $table where $filter');
      return true;
    }
    final request = await client.deleteUrl(Uri.parse('$baseUrl/$table?$filter'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    final response = await request.close();
    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = await response.transform(utf8.decoder).join();
      stderr.writeln('Error deleting from $table: ${response.statusCode} $body');
      return false;
    }
    return true;
  }

  String _normalizeBrand(String brand) {
    final lower = brand.toLowerCase().trim();
    if (_brandNormalization.containsKey(lower)) {
      return _brandNormalization[lower]!;
    }
    if (brand.contains(',')) {
      return brand.split(',').first.trim();
    }
    return brand.trim();
  }

  Future<String?> getOrCreateBrand(String brandNameInput, String? brandNameEn) async {
    if (brandNameInput.isEmpty && (brandNameEn == null || brandNameEn.isEmpty)) return null;
    
    final normalizedHe = _normalizeBrand(brandNameInput);
    
    final encoded = Uri.encodeComponent(normalizedHe);
    final existing = await supabaseGet('brands', 'name_he=eq.$encoded');
    if (existing.isNotEmpty) {
      final existingId = existing[0]['id'] as String;
      if (brandNameEn != null && (existing[0]['name_en'] as String?) == null) {
        await supabaseUpdate('brands', existingId, {'name_en': brandNameEn});
      }
      return existingId;
    }
    
    return supabaseInsert('brands', {
      'name_he': normalizedHe,
      'name_en': normalizedHe != brandNameInput ? brandNameInput : null,
      'trust_score': 0.5,
    });
  }

  Future<String?> getOrCreateAllergen(String allergenTag) async {
    String heName;
    String enName;
    String? emoji;
    
    if (allergenTag.startsWith('en:')) {
      final mapping = _allergenMappingEn[allergenTag];
      if (mapping != null) {
        enName = mapping.$1;
        heName = mapping.$2;
        emoji = mapping.$3;
      } else {
        enName = allergenTag.substring(3);
        heName = enName;
      }
    } else if (allergenTag.startsWith('he:')) {
      final mapping = _allergenMappingEn[allergenTag];
      if (mapping != null) {
        enName = mapping.$1;
        heName = mapping.$2;
        emoji = mapping.$3;
      } else {
        heName = allergenTag.substring(3);
        enName = heName;
      }
    } else {
      final mapping = _allergenMappingEn['en:$allergenTag'];
      if (mapping != null) {
        enName = mapping.$1;
        heName = mapping.$2;
        emoji = mapping.$3;
      } else {
        enName = allergenTag;
        heName = allergenTag;
      }
    }
    
    if (heName.isEmpty || heName.startsWith('he:')) {
      return null;
    }
    
    final encoded = Uri.encodeComponent(heName);
    final existing = await supabaseGet('allergens', 'name_he=eq.$encoded');
    if (existing.isNotEmpty) {
      return existing[0]['id'] as String;
    }
    return supabaseInsert('allergens', {'name_he': heName, 'name_en': enName, 'emoji': emoji});
  }

  Future<Map<String, dynamic>?> fetchOffProduct(String barcode) async {
    final request = await client.getUrl(Uri.parse('$_offApiBase/product/$barcode.json'));
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;
    return json['product'] as Map<String, dynamic>?;
  }

  Future<void> importProduct(String barcode) async {
    stdout.writeln('Fetching barcode $barcode from Open Food Facts...');
    final product = await fetchOffProduct(barcode);
    if (product == null) {
      stderr.writeln('Product not found in OFF: $barcode');
      return;
    }

    final productName = product['product_name_en'] ?? product['product_name'] ?? 'Unknown';
    final brandName = product['brands'] ?? '';
    final brandTagsRaw = product['brands_tags'];
    List<String> brandTags = [];
    if (brandTagsRaw is List) {
      brandTags = brandTagsRaw.cast<String>();
    }
    final imageUrl = product['image_front_url'] as String?;
    final allergensTags = (product['allergens_tags'] as List?)?.cast<String>() ?? [];
    final tracesTags = (product['traces_tags'] as List?)?.cast<String>() ?? [];
    final ingredientsText = product['ingredients_text'] as String?;
    final productCode = product['code'] as String?;
    final productUrl = product['url'] as String?;

    stdout.writeln('Found: $productName');
    stdout.writeln('  Brand: $brandName');
    stdout.writeln('  Brand tags: $brandTags');
    stdout.writeln('  Allergens: $allergensTags');
    stdout.writeln('  Traces (may contain): $tracesTags');

    String? brandNameEn;
    for (final tag in brandTags) {
      if (tag.contains(':') && !tag.startsWith('he:')) {
        final parts = tag.split(':');
        if (parts.length == 2 && parts[0] == 'en') {
          brandNameEn = parts[1].replaceAll('-', ' ');
          break;
        }
      }
    }

    final existing = await supabaseGet('products', 'barcode=eq.$barcode');
    if (existing.isNotEmpty) {
      stdout.writeln('  Product already exists, updating...');
      final existingId = existing[0]['id'];
      String? brandId;
      if (brandName.isNotEmpty) {
        brandId = await getOrCreateBrand(brandName, brandNameEn);
      }
      await supabaseUpdate('products', existingId, {
        'name_he': productName,
        'brand_id': brandId,
        'ingredients': ingredientsText,
        'image_url': imageUrl,
        'external_source_id': productUrl,
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      });
      
      await supabaseDelete('product_allergens', 'product_id=eq.$existingId');
      
      for (final tag in allergensTags) {
        final allergenId = await getOrCreateAllergen(tag);
        if (allergenId != null) {
          await supabaseInsert('product_allergens', {
            'product_id': existingId,
            'allergen_id': allergenId,
            'severity': 'contains',
          });
        }
      }
      for (final tag in tracesTags) {
        final allergenId = await getOrCreateAllergen(tag);
        if (allergenId != null) {
          await supabaseInsert('product_allergens', {
            'product_id': existingId,
            'allergen_id': allergenId,
            'severity': 'may_contain',
          });
        }
      }
      stdout.writeln('Update complete for barcode $barcode');
      return;
    }

    String? brandId;
    if (brandName.isNotEmpty) {
      brandId = await getOrCreateBrand(brandName, brandNameEn);
    }

    final productId = await supabaseInsert('products', {
      'name_he': productName,
      'barcode': barcode,
      'brand_id': brandId,
      'ingredients': ingredientsText,
      'image_url': imageUrl,
      'external_source_id': productUrl,
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (productId != null && allergensTags.isNotEmpty) {
      for (final tag in allergensTags) {
        final allergenId = await getOrCreateAllergen(tag);
        if (allergenId != null) {
          await supabaseInsert('product_allergens', {
            'product_id': productId,
            'allergen_id': allergenId,
            'severity': 'contains',
          });
        }
      }
    }

    if (productId != null && tracesTags.isNotEmpty) {
      for (final tag in tracesTags) {
        final allergenId = await getOrCreateAllergen(tag);
        if (allergenId != null) {
          await supabaseInsert('product_allergens', {
            'product_id': productId,
            'allergen_id': allergenId,
            'severity': 'may_contain',
          });
        }
      }
    }

    stdout.writeln('Import complete for barcode $barcode');
  }

  if (args[0] == '--batch') {
    if (args.length < 2) {
      stderr.writeln('Usage: --batch <file.csv>');
      exit(1);
    }
    final csvFile = File(args[1]);
    if (!csvFile.existsSync()) {
      stderr.writeln('CSV file not found: ${args[1]}');
      exit(1);
    }
    final lines = await csvFile.readAsLines();
    stdout.writeln('Processing ${lines.length} barcodes...');
    for (final line in lines) {
      final barcode = line.trim();
      if (barcode.isNotEmpty && !barcode.startsWith('#')) {
        await importProduct(barcode);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  } else {
    await importProduct(args[0]);
  }

  client.close();
  stdout.writeln('Done.');
}