// Version-comparison and update-wall tests.
//
// The bug these exist to prevent is a string compare: read as text, "2.0.10"
// sorts *before* "2.0.9", so a user on 2.0.9 would never be offered 2.0.10 —
// and a user on 2.0.10 would be told forever that 2.0.9 is newer. Every
// ordering case below is therefore numeric, segment by segment.
//
// The widget tests pin the other half of the requirement: the wall offers
// exactly one control, and neither the barrier nor the back button can get
// past it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/core/services/app_version.dart';
import 'package:happy_wedz/core/services/update_service.dart';
import 'package:happy_wedz/core/widgets/mandatory_update_gate.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('parses plain and build-suffixed versions', () {
      expect(AppVersion.tryParse('2.0.7')!.segments, [2, 0, 7]);
      expect(AppVersion.tryParse('2.0.7')!.build, isNull);

      final withBuild = AppVersion.tryParse('1.0.20+20')!;
      expect(withBuild.segments, [1, 0, 20]);
      expect(withBuild.build, 20);
    });

    test('tolerates what stores and build systems actually emit', () {
      expect(AppVersion.tryParse(' v2.1.0 ')!.segments, [2, 1, 0]);
      expect(AppVersion.tryParse('2.1.0-beta.2')!.segments, [2, 1, 0]);
      expect(AppVersion.tryParse('3')!.segments, [3]);
    });

    test('returns null for values that are not versions', () {
      // Play shows this instead of a number for staged/multi-APK releases.
      expect(AppVersion.tryParse('Varies with device'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });
  });

  group('numeric ordering', () {
    void expectNewer(String store, String installed) {
      expect(
        isUpdateRequired(installed: installed, store: store),
        isTrue,
        reason: '$store should be newer than $installed',
      );
      expect(
        isUpdateRequired(installed: store, store: installed),
        isFalse,
        reason: '$installed must not be treated as newer than $store',
      );
    }

    test('2.0.10 is newer than 2.0.9 (the string-compare trap)', () {
      expectNewer('2.0.10', '2.0.9');
    });

    test('2.1.0 is newer than 2.0.10', () => expectNewer('2.1.0', '2.0.10'));
    test('3.0.0 is newer than 2.9.9', () => expectNewer('3.0.0', '2.9.9'));
    test('2.0.7 is newer than 2.0.6', () => expectNewer('2.0.7', '2.0.6'));
    test('1.1.0 is newer than 1.0.20', () => expectNewer('1.1.0', '1.0.20'));

    test('equal versions require no update', () {
      expect(isUpdateRequired(installed: '2.0.7', store: '2.0.7'), isFalse);
    });

    test('missing segments count as zero', () {
      expect(isUpdateRequired(installed: '2.1', store: '2.1.0'), isFalse);
      expect(isUpdateRequired(installed: '2.1', store: '2.1.1'), isTrue);
    });

    test('build number breaks a tie only when both sides have one', () {
      expect(isUpdateRequired(installed: '2.0.7+10', store: '2.0.7+11'), isTrue);
      // The store never publishes a build number. Without this rule every
      // installed build would read as newer and nobody would be prompted.
      expect(isUpdateRequired(installed: '2.0.7+10', store: '2.0.7'), isFalse);
    });
  });

  group('fail-open', () {
    test('an unreadable version on either side never blocks', () {
      expect(
        isUpdateRequired(installed: '2.0.6', store: 'Varies with device'),
        isFalse,
      );
      expect(isUpdateRequired(installed: null, store: '9.9.9'), isFalse);
      expect(isUpdateRequired(installed: '2.0.6', store: ''), isFalse);
    });

    test('Play markup that yields no version returns null, not a guess', () {
      expect(UpdateService.parsePlayStoreVersion('<html>nothing</html>'),
          isNull);
      // A bare number in the page must not be mistaken for a version.
      expect(UpdateService.parsePlayStoreVersion('<div>500000+</div>'), isNull);
    });

    test('Play markup containing a version is parsed', () {
      expect(
        UpdateService.parsePlayStoreVersion('junk [[["1.0.21"]]] junk'),
        '1.0.21',
      );
      expect(
        UpdateService.parsePlayStoreVersion('"softwareVersion":"2.3.4"'),
        '2.3.4',
      );
    });
  });

  group('store urls', () {
    test('Play url is built from the running application id', () {
      expect(
        UpdateService.playStoreUrl('com.happy.happy_wedz'),
        'https://play.google.com/store/apps/details?id=com.happy.happy_wedz',
      );
    });

    test('App Store url falls back to a bundle-id search with no numeric id',
        () {
      expect(UpdateService.appStoreUrl('com.happy.happyWedz'),
          contains('apps.apple.com'));
    });
  });

  group('MandatoryUpdateDialog', () {
    const status = UpdateStatus.required(
      installed: '2.0.6',
      store: '2.0.7',
      url: 'https://play.google.com/store/apps/details?id=com.happy.happy_wedz',
    );

    testWidgets('shows both versions and exactly one action', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MandatoryUpdateDialog(status: status),
      ));

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('2.0.6'), findsOneWidget);
      expect(find.text('2.0.7'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
    });

    testWidgets('offers no Later, Cancel, Skip or close affordance',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MandatoryUpdateDialog(status: status),
      ));

      for (final escape in const [
        'Later',
        'Maybe later',
        'Cancel',
        'Skip',
        'Close',
        'Not now',
        'Dismiss',
      ]) {
        expect(find.text(escape), findsNothing, reason: '"$escape" must not exist');
      }
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byType(CloseButton), findsNothing);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('a store that will not open keeps the wall up', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MandatoryUpdateDialog(
          status: status,
          onLaunch: (_) async => false, // store refuses to open
        ),
      ));

      await tester.tap(find.text('UPDATE NOW'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not open the store'), findsOneWidget);
      // Still blocking, still one way out.
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
    });

    testWidgets('a launch failure does not crash the wall', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MandatoryUpdateDialog(
          status: status,
          onLaunch: (_) async => throw Exception('no browser'),
        ),
      ));

      await tester.tap(find.text('UPDATE NOW'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Could not open the store'), findsOneWidget);
    });

    testWidgets('declares canPop false so back cannot dismiss it',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MandatoryUpdateDialog(status: status),
      ));

      final popScope = tester.widget<PopScope>(
        find.byType(PopScope).first,
      );
      expect(popScope.canPop, isFalse);
    });

    testWidgets('lays out without overflow on a small phone and a tablet',
        (tester) async {
      for (final size in const [Size(320, 560), Size(1024, 1366)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(
          home: MandatoryUpdateDialog(status: status),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'overflow at $size');
        expect(find.text('UPDATE NOW'), findsOneWidget);
      }
    });
  });

  group('barrier', () {
    testWidgets('tapping outside the card does not dismiss the route',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('app behind')),
      ));

      // Pushed exactly as MandatoryUpdateGate pushes it.
      showGeneralDialog<void>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        barrierLabel: 'Update required',
        barrierColor: Colors.black.withValues(alpha: 0.82),
        pageBuilder: (_, __, ___) => const MandatoryUpdateDialog(
          status: UpdateStatus.required(
            installed: '2.0.6',
            store: '2.0.7',
            url: 'https://example.test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Update Available'), findsOneWidget);

      // Top-left corner: scrim, well clear of the centred card.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
    });
  });
}
