import 'package:supabase_flutter/supabase_flutter.dart';

class MockBuilder {
  List<Map<String, dynamic>> mockData;
  
  MockBuilder({List<Map<String, dynamic>>? data}) : mockData = data ?? [];
  
  MockBuilder select([String? columns]) => this;
  
  MockBuilder eq(String column, dynamic value) => this;
  
  MockBuilder like(String column, String value) => this;
  
  MockBuilder filter(String column, String operator, dynamic value) => this;
  
  MockBuilder range(int start, int end) => this;
  
  MockBuilder order(String column, {bool ascending = true}) => this;
  
  MockBuilder limit(int count) => this;
  
  Future<List<Map<String, dynamic>>> execute() async {
    return mockData;
  }
}

class MockPost {
  static MockBuilder from(String table) {
    return MockBuilder();
  }
}