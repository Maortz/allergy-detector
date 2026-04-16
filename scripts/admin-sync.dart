import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> args) async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln(
        'Error: .env file not found. Copy .env.example to .env and fill in values.');
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

  final client = HttpClient();
  final baseUrl = '$supabaseUrl/rest/v1';

  Future<Map<String, dynamic>> supabaseGet(String table) async {
    final request = await client.getUrl(Uri.parse('$baseUrl/$table'));
    request.headers.set('apikey', supabaseKey!);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  stdout.writeln('Fetching products from Supabase...');
  stdout.writeln('Admin sync script ready. Use --help for available commands.');
  stdout.writeln('Commands:');
  stdout.writeln('  list-products   List all non-archived products');
  stdout.writeln('  list-reports    List unresolved feedback reports');
  stdout.writeln('  archive <id>    Archive a product by ID');

  client.close();
}
