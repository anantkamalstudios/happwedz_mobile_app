// AUDIT NOTE:
// This file used to contain the unmodified `flutter create` counter template
// ("Counter increments smoke test"). HappyWedz has no counter, so the only test
// in the project failed on every run — `flutter test` reported
// "Found 0 widgets with text "0"" and the suite was red.
//
// It has been replaced with tests for the rule that matters most in this app:
// NOTHING IS USABLE WITHOUT LOGIN. They exercise `AuthSession` (the single
// source of truth for "is somebody signed in") and `AuthGate` (the root widget
// that decides between the dashboard and the login screen).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/authservice.dart';
import 'package:happy_wedz/main.dart';

/// A session that would be accepted: token + positive user id + fresh stamp.
Map<String, Object> validSession({DateTime? issuedAt}) => {
      UserPrefs.tokenKey: 'test-jwt-token',
      UserPrefs.userIdKey: 42,
      UserPrefs.isLoggedInKey: true,
      UserPrefs.userNameKey: 'Test User',
      UserPrefs.tokenSavedAtKey:
          (issuedAt ?? DateTime.now()).toIso8601String(),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSession — a session is only valid when it is complete', () {
    test('no stored session is not authenticated', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await AuthSession.instance.refresh(), isFalse);
      expect(AuthSession.instance.isAuthenticated, isFalse);
      expect(AuthSession.instance.isReady, isTrue);
    });

    test('a token with no user id is rejected and wiped', () async {
      // A half-written session must never count as signed in.
      SharedPreferences.setMockInitialValues({
        UserPrefs.tokenKey: 'test-jwt-token',
        UserPrefs.isLoggedInKey: true,
      });

      expect(await AuthSession.instance.refresh(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UserPrefs.tokenKey), isNull,
          reason: 'an invalid session must not be left in storage');
    });

    test('a user id with no token is rejected', () async {
      SharedPreferences.setMockInitialValues({
        UserPrefs.userIdKey: 42,
        UserPrefs.isLoggedInKey: true,
      });

      expect(await AuthSession.instance.refresh(), isFalse);
    });

    test('the isLoggedIn flag alone does not authenticate', () async {
      // Guards against a screen writing only the legacy boolean and thereby
      // unlocking the app without a token.
      SharedPreferences.setMockInitialValues({
        UserPrefs.isLoggedInKey: true,
        UserPrefs.legacyIsLoggedInKey: true,
      });

      expect(await AuthSession.instance.refresh(), isFalse);
    });

    test('a complete, fresh session is authenticated', () async {
      SharedPreferences.setMockInitialValues(validSession());

      expect(await AuthSession.instance.refresh(), isTrue);
      expect(AuthSession.instance.isAuthenticated, isTrue);
    });

    test('a token older than the expiry window is rejected and wiped',
        () async {
      SharedPreferences.setMockInitialValues(
        validSession(
          issuedAt: DateTime.now().subtract(
            const Duration(days: AuthSession.tokenExpiryDays + 1),
          ),
        ),
      );

      expect(await AuthSession.instance.refresh(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UserPrefs.tokenKey), isNull);
      expect(prefs.getInt(UserPrefs.userIdKey), isNull);
    });

    test('a session saved before expiry stamping existed is adopted, not '
        'thrown away', () async {
      final session = validSession()..remove(UserPrefs.tokenSavedAtKey);
      SharedPreferences.setMockInitialValues(session);

      expect(await AuthSession.instance.refresh(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UserPrefs.tokenSavedAtKey), isNotNull,
          reason: 'the expiry clock should start now rather than never');
    });
  });

  group('AuthSession — signing out', () {
    test('clears every session key and publishes not-authenticated', () async {
      SharedPreferences.setMockInitialValues({
        ...validSession(),
        UserPrefs.userEmailKey: 'test@example.com',
        UserPrefs.weddingVenueKey: 'Pune',
        UserPrefs.weddingDateKey: '2026-12-01',
        // App-level preference that must survive a logout.
        'selected_city': 'Mumbai',
      });
      expect(await AuthSession.instance.refresh(), isTrue);

      await AuthSession.instance.signOut();

      expect(AuthSession.instance.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      for (final key in UserPrefs.sessionKeys) {
        expect(prefs.get(key), isNull, reason: '$key survived logout');
      }
      expect(prefs.getString('selected_city'), 'Mumbai',
          reason: 'logout must not wipe non-session preferences');
    });

    test('a signed-out session cannot be revived by refreshing', () async {
      SharedPreferences.setMockInitialValues(validSession());
      await AuthSession.instance.refresh();
      await AuthSession.instance.signOut();

      expect(await AuthSession.instance.refresh(), isFalse);
    });
  });

  group('AuthGate — the root of the app', () {
    testWidgets('shows the login screen when there is no session',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AuthSession.instance.refresh();

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows the login screen when the stored token has expired',
        (tester) async {
      SharedPreferences.setMockInitialValues(
        validSession(
          issuedAt: DateTime.now().subtract(
            const Duration(days: AuthSession.tokenExpiryDays + 1),
          ),
        ),
      );
      await AuthSession.instance.refresh();

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });
}