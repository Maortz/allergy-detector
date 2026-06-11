import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/services/auth_service.dart';

/// Minimal session stub — `authSessionStateFor` only inspects whether the
/// `AuthState.session` is null, so the session's contents are irrelevant here.
Session _session() => Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: const User(
        id: 'user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
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

    test('an anonymous-sign-in session still counts as authenticated', () {
      // Anonymous sessions are the MVP default — they must not read as signedOut.
      final state = AuthState(AuthChangeEvent.initialSession, _session());
      expect(
        AuthService.authSessionStateFor(state),
        AuthSessionState.authenticated,
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
