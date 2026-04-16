import 'dart:io';
import 'dart:convert';

const _offApiBase = 'https://world.openfoodfacts.org/api/v0';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run import-openfoodfacts.dart <barcode> [--dry-run]');
    stderr.writeln(
        '       dart run import-openfoodfacts.dart --batch <file.csv>');
    exit(1);
  }

  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('Error: .env file not found.');
    exit(1);
  }

  final envLines = await envFile.readAsLines();
  final env = <String, String>{};
  for (final line in envLines) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length == 2) {
      env[parts[0].trim()] = parts[1].trim();
    }
  }

  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_PUBLIC_API_KEY'];
  if (supabaseUrl == null || supabaseKey == null) {
    stderr.writeln(
        'Error: SUPABASE_URL and SUPABASE_PUBLIC_API_KEY must be set in .env');
    exit(1);
  }

  final isDryRun = args.contains('--dry-run');
  final client = HttpClient();
  final baseUrl = '$supabaseUrl/rest/v1';

  Future<void> supabaseInsert(String table, Map<String, dynamic> data) async {
    if (isDryRun) {
      stdout.writeln('[DRY RUN] Would insert into $table: $data');
      return;
    }
    final request = await client.postUrl(Uri.parse('$baseUrl/$table'));
    request.headers.set('apikey', supabaseKey!);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=minimal');
    request.write(jsonEncode(data));
    final response = await request.close();
    if (response.statusCode != 201) {
      final body = await response.transform(utf8.decoder).join();
      stderr
          .writeln('Error inserting into $table: ${response.statusCode} $body');
    }
  }

  Future<Map<String, dynamic>?> fetchOffProduct(String barcode) async {
    final request =
        await client.getUrl(Uri.parse('$_offApiBase/product/$barcode.json'));
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

    final productName =
        product['product_name_he'] ?? product['product_name'] ?? 'Unknown';
    final imageUrl = product['image_url'] as String?;
    final allergensTags =
        (product['allergens_tags'] as List?)?.cast<String>() ?? [];
    final tracesTags = (product['traces_tags'] as List?)?.cast<String>() ?? [];

    stdout.writeln('Found: $productName');
    stdout.writeln('  Allergens: $allergensTags');
    stdout.writeln('  Traces: $tracesTags');
    stdout.writeln('  Image: $imageUrl');

    await supabaseInsert('products', {
      'name_he': productName,
      'barcode': barcode,
      'image_url': imageUrl,
      'external_source_id': 'off_$barcode',
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
    });

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
      if (barcode.isNotEmpty) {
        await importProduct(barcode);
      }
    }
  } else {
    await importProduct(args[0]);
  }

  client.close();
  stdout.writeln('Done.');
}
