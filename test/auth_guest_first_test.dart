// Guest-first authentication: the session model and the protected-action
// guard. Mirrors the regression checklist — fresh install is a guest, a
// protected action asks to sign in, cancelling keeps the guest, signing in
// continues the action, logout returns to guest and wipes the previous
// user's private data, an expired session drops to guest.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/Bottombars/morescreen.dart';
import 'package:happy_wedz/authservice.dart';
import 'package:happy_wedz/shaadi_ai/ui/shaadi_ai_screen.dart';
import 'package:happy_wedz/main.dart';
import 'package:happy_wedz/matrimonial/ui/dashboard/matrimonial_dashboard_page.dart';
import 'package:happy_wedz/matrimonial/ui/dashboard/matrimonial_edit_profile_page.dart';
import 'package:happy_wedz/matrimonial/ui/matrimonial_landing_page.dart';
import 'package:happy_wedz/matrimonial/ui/matrimonial_registration_page.dart';
import 'package:happy_wedz/matrimonial/ui/matrimonial_search_page.dart';

Map<String, Object> _validSession({DateTime? savedAt}) => {
      UserPrefs.isLoggedInKey: true,
      UserPrefs.userIdKey: 42,
      UserPrefs.userNameKey: 'Asha',
      UserPrefs.tokenKey: 'jwt-token',
      UserPrefs.tokenSavedAtKey:
          (savedAt ?? DateTime.now()).toIso8601String(),
    };

/// A host screen with a protected button, recording what the guard returned.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final List<bool> results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final ok = await requireAuthentication(
              context,
              reason: 'Sign in to book this stay.',
            );
            results.add(ok);
          },
          child: const Text('Book now'),
        ),
      ),
    );
  }
}

Future<_HostState> _pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(navigatorKey: rootNavigatorKey, home: const _Host()),
  );
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  // AuthSession is an app-wide singleton, so every test first settles it into
  // a known state through its public API.
  Future<void> startAsGuest() async {
    SharedPreferences.setMockInitialValues({});
    await AuthSession.instance.refresh();
  }

  Future<void> startSignedIn() async {
    SharedPreferences.setMockInitialValues(_validSession());
    await AuthSession.instance.refresh();
  }

  group('AuthSession state', () {
    test('fresh install resolves to GUEST, not a fake user', () async {
      await startAsGuest();
      expect(AuthSession.instance.status, AuthStatus.guest);
      expect(AuthSession.instance.isGuest, isTrue);
      expect(await UserPrefs.getUserId(), isNull);
      expect(await UserPrefs.getToken(), isNull);
    });

    test('a stored valid session restores LOGGED_IN on restart', () async {
      await startSignedIn();
      expect(AuthSession.instance.status, AuthStatus.authenticated);
    });

    test('an expired session is cleared and becomes GUEST', () async {
      await startSignedIn();
      final epoch = AuthSession.instance.sessionEpoch;
      SharedPreferences.setMockInitialValues(
        _validSession(savedAt: DateTime.now().subtract(const Duration(days: 3)))
          ..['favourite_vendors'] = <String>['7'],
      );
      await AuthSession.instance.refresh();

      final prefs = await SharedPreferences.getInstance();
      expect(AuthSession.instance.status, AuthStatus.guest);
      expect(AuthSession.instance.lastSignOutReason,
          SignOutReason.sessionExpired);
      expect(AuthSession.instance.sessionEpoch, epoch + 1);
      expect(prefs.getString(UserPrefs.tokenKey), isNull);
      expect(prefs.getStringList('favourite_vendors'), isNull);
    });

    test('logout clears the session and the previous user\'s private data, '
        'keeping public/app data', () async {
      SharedPreferences.setMockInitialValues({
        ..._validSession(),
        'favourite_venues': <String>['1'],
        'hw:cabBookingDraft': '{"firstName":"Asha"}',
        'draft_abc': '{}',
        'hw_flightRecentSearches': '[]', // not account data
        'selected_city': 'Pune', // app preference
      });
      await AuthSession.instance.refresh();
      expect(AuthSession.instance.isAuthenticated, isTrue);
      final epoch = AuthSession.instance.sessionEpoch;

      await AuthSession.instance.signOut(reason: SignOutReason.userLogout);

      final prefs = await SharedPreferences.getInstance();
      expect(AuthSession.instance.status, AuthStatus.guest);
      expect(AuthSession.instance.lastSignOutReason, SignOutReason.userLogout);
      expect(AuthSession.instance.sessionEpoch, epoch + 1);
      for (final key in UserPrefs.sessionKeys) {
        expect(prefs.containsKey(key), isFalse, reason: key);
      }
      expect(prefs.containsKey('favourite_venues'), isFalse);
      expect(prefs.containsKey('hw:cabBookingDraft'), isFalse);
      expect(prefs.containsKey('draft_abc'), isFalse);
      expect(prefs.getString('hw_flightRecentSearches'), '[]');
      expect(prefs.getString('selected_city'), 'Pune');

      // Restart after logout: still a guest, previous user not restored.
      await AuthSession.instance.refresh();
      expect(AuthSession.instance.status, AuthStatus.guest);
    });

    test('a guest\'s parked booking draft survives (it is resumed after '
        'sign-in)', () async {
      await startAsGuest();
      SharedPreferences.setMockInitialValues({
        'hw:bookingDraft': '{"hotel":"x"}',
      });
      await AuthSession.instance.refresh();
      await AuthSession.instance.signOut(); // e.g. a 401 while a guest
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('hw:bookingDraft'), '{"hotel":"x"}');
    });
  });

  group('requireAuthentication', () {
    testWidgets('signed in: continues without showing sign-in', (tester) async {
      await tester.runAsync(startSignedIn);
      final host = await _pumpHost(tester);

      await tester.tap(find.text('Book now'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsNothing);
      expect(host.results, [true]);
    });

    testWidgets('guest → sign-in opens with the reason → cancel keeps the '
        'guest on the same screen', (tester) async {
      await tester.runAsync(startAsGuest);
      final host = await _pumpHost(tester);

      await tester.tap(find.text('Book now'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Sign in to book this stay.'), findsOneWidget);

      await tester.tap(find.text('Continue browsing'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('Book now'), findsOneWidget); // same screen, no Home
      expect(host.results, [false]);
      expect(AuthSession.instance.isGuest, isTrue);
    });

    testWidgets('guest → sign-in succeeds → original action continues',
        (tester) async {
      await tester.runAsync(startAsGuest);
      final host = await _pumpHost(tester);

      await tester.tap(find.text('Book now'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);

      // What a successful Google/Apple sign-in does: persist the session,
      // publish it, pop the sign-in screen.
      await tester.runAsync(() async {
        await UserPrefs.saveUser(
          id: 42,
          name: 'Asha',
          email: 'asha@example.com',
          token: 'jwt-token',
        );
        await AuthSession.instance.refresh();
      });
      rootNavigatorKey.currentState!.pop(true);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('Book now'), findsOneWidget);
      expect(host.results, [true]);
      expect(AuthSession.instance.isAuthenticated, isTrue);
    });

    testWidgets('concurrent protected actions share one sign-in screen',
        (tester) async {
      await tester.runAsync(startAsGuest);
      final host = await _pumpHost(tester);

      await tester.tap(find.text('Book now'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.tap(find.text('Book now'), warnIfMissed: false);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsNothing);
      expect(host.results.every((r) => r == false), isTrue);
    });
  });

  group('Shaadi AI', () {
    testWidgets('guest: the More tab asks to sign in before opening it',
        (tester) async {
      await startAsGuest();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const MoreOptionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shaadi AI'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(
        find.text(
          'Sign in to chat with Shaadi AI, your wedding planning assistant.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ShaadiAiScreen), findsNothing);

      await tester.tap(find.text('Continue browsing'));
      await tester.pumpAndSettle();
      expect(find.byType(ShaadiAiScreen), findsNothing);
      expect(find.byType(MoreOptionsScreen), findsOneWidget);
    });
  });

  group('Matrimonial account pages', () {
    Future<void> pumpLanding(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const MatrimonialLandingPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    // No `runAsync` here: letting real I/O run would surface the test
    // binding's failed Google Fonts download inside these tests. The mocked
    // session store is in-memory, so fake-async pumping is enough.
    Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
      await tester.tap(target);
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('guest: My dashboard asks to sign in; cancel stays on the '
        'landing page', (tester) async {
      await startAsGuest();
      await pumpLanding(tester);

      await tapAndSettle(tester, find.byTooltip('My dashboard'));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Sign in to see your matches, interests and messages.'),
          findsOneWidget);

      await tapAndSettle(tester, find.text('Continue browsing'));
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(MatrimonialDashboardPage), findsNothing);
      expect(find.byType(MatrimonialLandingPage), findsOneWidget);
    });

    testWidgets('guest: Edit profile and Register Free ask to sign in',
        (tester) async {
      await startAsGuest();
      await pumpLanding(tester);

      await tapAndSettle(tester, find.byTooltip('Edit profile'));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(MatrimonialEditProfilePage), findsNothing);
      await tapAndSettle(tester, find.byTooltip('Close'));

      await tester.ensureVisible(find.text('Register Free'));
      await tapAndSettle(tester, find.text('Register Free'));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(MatrimonialRegistrationPage), findsNothing);
    });

    testWidgets('signed in: My dashboard opens directly', (tester) async {
      await startSignedIn();
      await pumpLanding(tester);

      await tapAndSettle(tester, find.byTooltip('My dashboard'));
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(MatrimonialDashboardPage), findsOneWidget);
    });

    testWidgets('guest: Search Profiles stays public', (tester) async {
      await startAsGuest();
      await pumpLanding(tester);

      await tester.ensureVisible(find.text('Search Profiles'));
      await tapAndSettle(tester, find.text('Search Profiles'));
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(MatrimonialSearchPage), findsOneWidget);
    });
  });
}
