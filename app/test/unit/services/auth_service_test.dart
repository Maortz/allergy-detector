import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/services/auth_service.dart';

/// Minimal session stub. `authSessionStateFor` inspects whether
/// `AuthState.session` is null and the user's `isAnonymous` flag, so those are
/// the only fields that matter here.
Session _session({bool isAnonymous = false}) => Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: isAnonymous,
      ),
    );

void main() {
  group('AuthService.authSessionStateFor', () {
    test('maps a state carrying a session to authenticated', () {
      final state = AuthState(AuthChangeEvent.signedIn, _session());
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.authenticated,
      );
    });

    test('maps a non-anonymous session to authenticated', () {
      final state = AuthState(AuthChangeEvent.signedIn, _session());
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.authenticated,
      );
    });

    test('maps an anonymous session to anonymous', () {
      final state = AuthState(
        AuthChangeEvent.initialSession,
        _session(isAnonymous: true),
      );
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.anonymous,
      );
    });

    test('maps a session-less state to signedOut', () {
      final state = AuthState(AuthChangeEvent.signedOut, null);
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.signedOut,
      );
    });

    test('a null session on initialSession (no restored session) is signedOut',
        () {
      final state = AuthState(AuthChangeEvent.initialSession, null);
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.signedOut,
      );
    });
  });
}
