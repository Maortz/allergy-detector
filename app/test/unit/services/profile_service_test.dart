import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/services/profile_service.dart';

void main() {
  group('ProfileService.fetchIsAdmin', () {
    test(
      'defaults closed (false) with no session — short-circuits before any read',
      () async {
        // A freshly-constructed client has no signed-in user, so
        // auth.currentUser?.id == null. fetchIsAdmin must return false via the
        // early return without ever hitting the network (the httpClient here
        // would otherwise refuse the connection). Pins the default-closed
        // contract on the null-session code path.
        final client = SupabaseClient(
          'http://localhost',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        addTearDown(() => client.dispose());

        expect(client.auth.currentUser, isNull);
        expect(await ProfileService(client).fetchIsAdmin(), isFalse);
      },
    );
  });

  group('ProfileService.parseIsAdmin', () {
    test('returns true when the row carries is_admin == true', () {
      expect(ProfileService.parseIsAdmin({'is_admin': true}), isTrue);
    });

    test('returns false when the row carries is_admin == false', () {
      expect(ProfileService.parseIsAdmin({'is_admin': false}), isFalse);
    });

    test('defaults to false for a null row (no profile / read failed)', () {
      expect(ProfileService.parseIsAdmin(null), isFalse);
    });

    test('defaults to false when the is_admin key is absent', () {
      expect(ProfileService.parseIsAdmin(<String, dynamic>{}), isFalse);
    });

    test('defaults to false for a non-bool is_admin value', () {
      expect(ProfileService.parseIsAdmin({'is_admin': 'true'}), isFalse);
    });
  });
}
