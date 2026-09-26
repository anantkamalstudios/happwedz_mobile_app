// Wedding Venue (City) picker on the profile screen.
//
// Reported as "wedding venue city is not search". Reproduced in a widget
// test before fixing: tapping the field opened the search route (back arrow
// and clear icon both present) but rendered **zero** list tiles, and typing
// matched nothing — because `LocationService.fetchCities` had failed and the
// error was swallowed into a `debugPrint`. Nothing on screen said the city
// list had not loaded.
//
// Every request fails in the test binding, so these tests exercise exactly
// that failure path for free. The list-populated cases drive the delegate
// directly, since there is no seam to inject cities through the screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 1234,
      'auth_token': 'test-token',
    });
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ProfileSettingsScreen()),
    );
    // Long enough for the eager city load in initState to fail.
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('the venue city can be typed when the city API is down', (
    tester,
  ) async {
    await pumpProfile(tester);

    // This is the part that actually matters. countriesnow.space returns 503
    // for long stretches — observed live: 200 once, then five consecutive
    // 503s twenty minutes later. The field used to be readOnly with the
    // picker as its only input path, so during an outage a wedding city
    // could not be set at all, which also blocked isProfileComplete()
    // everywhere. The website's own field is plain text with no list.
    final field = find.widgetWithText(TextFormField, 'Type a city, or tap search');
    expect(field, findsOneWidget);

    await tester.enterText(field, 'Kolhapur');
    await tester.pump();

    expect(find.text('Kolhapur'), findsOneWidget);
  });

  testWidgets('a failed city load never opens a blank search screen', (
    tester,
  ) async {
    await pumpProfile(tester);

    // Tap the search affordance, not the field — the field is now for typing.
    await tester.tap(find.byIcon(Icons.search_rounded), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Before the fix this opened the SearchDelegate route with an empty
    // ListView — the back arrow and clear action were on screen with nothing
    // under them. Now the picker declines to open and explains itself.
    expect(
      find.byIcon(Icons.clear),
      findsNothing,
      reason: 'the search route must not open against an empty city list',
    );
    expect(find.textContaining('you can type the city instead'), findsWidgets);
  });

  group('city search delegate', () {
    const cities = [
      'Pune',
      'Rajapunnagar',
      'Mumbai',
      'Nashik',
      'New Delhi',
    ];

    Future<void> openSearch(WidgetTester tester, List<String> list) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSearch<String>(
                context: context,
                delegate: CitySearchDelegate(list),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the full list before anything is typed', (tester) async {
      await openSearch(tester, cities);
      expect(find.byType(ListTile), findsWidgets);
      expect(find.text('Mumbai'), findsOneWidget);
    });

    testWidgets('filters as you type, case-insensitively', (tester) async {
      await openSearch(tester, cities);

      await tester.enterText(find.byType(TextField), 'mum');
      await tester.pumpAndSettle();

      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Nashik'), findsNothing);
    });

    testWidgets('ranks prefix matches above substring matches', (tester) async {
      await openSearch(tester, cities);

      await tester.enterText(find.byType(TextField), 'pun');
      await tester.pumpAndSettle();

      // Both contain "pun"; "Pune" starts with it and must come first.
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((tiles.first.title! as Text).data, 'Pune');
      expect(find.text('Rajapunnagar'), findsOneWidget);
    });

    testWidgets('says so when nothing matches, instead of going blank', (
      tester,
    ) async {
      await openSearch(tester, cities);

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(find.textContaining('No cities match'), findsOneWidget);
    });

    testWidgets('an empty list explains itself rather than rendering nothing', (
      tester,
    ) async {
      await openSearch(tester, const []);

      expect(find.byType(ListTile), findsNothing);
      expect(
        find.textContaining("couldn't load the list of cities"),
        findsOneWidget,
      );
    });
  });
}
