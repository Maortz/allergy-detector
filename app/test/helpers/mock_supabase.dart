import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends SupabaseClient {
  final MockPostgrestBuilder _from = MockPostgrestBuilder();

  @override
  PostgrestBuilder table(String tableName) {
    return _from;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPostgrestBuilder extends PostgrestBuilder {
  MockPostgrestBuilder() : super(_MockSupabase(), '', null, null, null);

  String? _selectColumns;
  String? _tableName;
  Map<String, dynamic>? _eqFilter;
  String? _likeFilter;
  bool? _eqArchived;
  List<dynamic>? _inFilter;
  int? _rangeStart;
  int? _rangeEnd;
  String? _orderColumn;
  bool _orderAscending = true;
  String? _filterColumn;
  dynamic _filterValue;

  MockPostgrestBuilder select([String? columns]) {
    _selectColumns = columns ?? '*';
    return this;
  }

  MockPostgrestBuilder eq(String column, dynamic value) {
    if (column == 'is_archived') {
      _eqArchived = value as bool;
    } else {
      _eqFilter = {column: value};
    }
    return this;
  }

  MockPostgrestBuilder like(String column, String value) {
    _likeFilter = value;
    return this;
  }

  MockPostgrestBuilder filter(String column, String operator, dynamic value) {
    _filterColumn = column;
    _filterValue = value;
    return this;
  }

  MockPostgrestBuilder range(int start, int end) {
    _rangeStart = start;
    _rangeEnd = end;
    return this;
  }

  MockPostgrestBuilder order(String column, {bool ascending = true}) {
    _orderColumn = column;
    _orderAscending = ascending;
    return this;
  }

  @override
  Future<T> execute<T>({String? identity, Schema? schema}) async {
    return [] as T;
  }
}

class _MockSupabase extends SupabaseClient {
  _MockSupabase() : super('', '');

  @override
  dynamic noSuchMethod(Invocation invocation) => MockPostgrestBuilder();
}

class MockSupabase {
  static MockSupabaseClient create() => MockSupabaseClient();
}