// Layout tests for the Matrimonial module's two most complex screens: the
// 4-step registration wizard and the dashboard shell.
//
// Same requirement `test/honeymoon_booking_layout_test.dart` and
// `test/wedding_website_layout_test.dart` encode: the screen has to render
// at typical phone widths — 320, 360, 375, 390, 414 — at the app's 1.2x
// text-scale clamp, without a RenderFlex overflow or horizontal scroll.
//
// This module has no backend (see MIGRATION_NOTES.md's Matrimonial
// section), so there is no API-shape test file to go with this one — every
// screen is pure UI plus local form state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/matrimonial/ui/dashboard/matrimonial_dashboard_page.dart';
import 'package:happy_wedz/matrimonial/ui/matrimonial_landing_page.dart';
import 'package:happy_wedz/matrimonial/ui/matrimonial_registration_page.dart';

const List<double> phoneWidths = [320, 360, 375, 390, 414];
const double maxTextScale = 1.2;

extension _Pump on WidgetTester {
  Future<void> pumpPhone(
    Widget child, {
    required double width,
    double height = 900,
    double textScale = 1.0,
    double bottomInset = 0,
  }) async {
    view.devicePixelRatio = 1.0;
    view.physicalSize = Size(width, height);
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: bottomInset),
          ),
          child: child,
        ),
      ),
    );
    await pump(const Duration(milliseconds: 400));
  }
}

void expectNoOverflow(WidgetTester tester, String context) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $context: $error');
}

/// Finds an [AppTextField] with the given label and returns its inner
/// [TextFormField], since the label itself is drawn with `RichText` (for the
/// optional required-asterisk) rather than a plain `Text`.
Finder _fieldByLabel(String label) {
  final field = find.byWidgetPredicate((w) => w is AppTextField && w.label == label);
  return find.descendant(of: field, matching: find.byType(TextFormField));
}

Future<void> _openDropdownAndPick(WidgetTester tester, int dropdownIndex, String option) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).at(dropdownIndex);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  group('MatrimonialRegistrationPage', () {
    for (final width in phoneWidths) {
      testWidgets('step 1 renders at ${width}px with no overflow', (tester) async {
        await tester.pumpPhone(
          const MatrimonialRegistrationPage(),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'registration step 1 @ ${width}px');

        expect(find.text('Profile Details'), findsOneWidget);
        expect(find.text('Are you manglik?'), findsOneWidget);
      });
    }

    testWidgets('step 1 renders with the keyboard open at the narrowest width', (tester) async {
      await tester.pumpPhone(
        const MatrimonialRegistrationPage(),
        width: 320,
        textScale: maxTextScale,
        bottomInset: 300,
      );
      expectNoOverflow(tester, 'registration step 1, keyboard open, 320px');
    });

    testWidgets('empty step 1 shows validation errors instead of advancing', (tester) async {
      await tester.pumpPhone(const MatrimonialRegistrationPage(), width: 360, textScale: maxTextScale);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Profile for is required'), findsOneWidget);
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Date of birth is required'), findsOneWidget);
      // Still on step 1.
      expect(find.text('Brothers'), findsNothing);
    });

    testWidgets(
      'filling every step and reaching the gated submit renders all four steps with no overflow',
      (tester) async {
        await tester.pumpPhone(const MatrimonialRegistrationPage(), width: 360, textScale: maxTextScale);

        // --- Step 1: fill the required fields ---
        await _openDropdownAndPick(tester, 0, 'Self');
        await _openDropdownAndPick(tester, 1, 'Bride');
        await tester.enterText(find.byType(TextFormField).first, 'Test Person');
        // Date of birth: tap to open the picker and accept the pre-selected
        // initial date rather than picking a specific day (robust across
        // whichever month the picker opens on).
        await tester.tap(_fieldByLabel('Date of Birth'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expectNoOverflow(tester, 'registration step 2 @ 360px');
        expect(find.text('Brothers'), findsOneWidget);
        expect(find.text('Sisters'), findsOneWidget);

        // --- Step 2 -> Step 3 ---
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expectNoOverflow(tester, 'registration step 3 @ 360px');
        expect(
          find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Partner Expectations'),
          findsOneWidget,
        );

        // --- Step 3 -> Step 4 ---
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expectNoOverflow(tester, 'registration step 4 @ 360px');
        expect(
          find.byWidgetPredicate((w) => w is AppTextField && w.label == 'Mobile Number'),
          findsOneWidget,
        );

        // Sending an OTP is honestly gated, never faked as verified.
        await tester.enterText(_fieldByLabel('Mobile Number'), '9876543210');
        await tester.tap(find.text('Send OTP'));
        await tester.pump(); // let the SnackBar animate in
        expect(find.text("OTP verification isn't available yet."), findsOneWidget);

        // Completing registration is honestly gated too, never a fake success.
        await tester.tap(find.text('Complete Registration'));
        await tester.pump();
        expect(
          find.text("Registration isn't available yet — please check back soon."),
          findsOneWidget,
        );
      },
    );
  });

  group('MatrimonialDashboardPage', () {
    for (final width in phoneWidths) {
      testWidgets('renders at ${width}px with no overflow', (tester) async {
        await tester.pumpPhone(
          const MatrimonialDashboardPage(),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'dashboard @ ${width}px');

        // Default tab: Matches — a static "Coming soon" tile, never a
        // Math.random()-style fabricated number.
        expect(find.text('Coming soon'), findsOneWidget);
        expect(find.text('No matches available yet'), findsOneWidget);
      });
    }

    testWidgets('every tab renders an honest state with no overflow', (tester) async {
      await tester.pumpPhone(const MatrimonialDashboardPage(), width: 360, textScale: maxTextScale);

      Future<void> selectTab(String label) async {
        final tabStrip = find.byType(SingleChildScrollView).first;
        await tester.dragUntilVisible(find.text(label), tabStrip, const Offset(-250, 0));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await selectTab('Activity');
      expectNoOverflow(tester, 'dashboard Activity tab');
      expect(find.text('Activity not available'), findsOneWidget);

      await selectTab('Messages');
      expectNoOverflow(tester, 'dashboard Messages tab');
      expect(find.text('Messages not available'), findsOneWidget);

      await selectTab('Interests');
      expectNoOverflow(tester, 'dashboard Interests tab');
      expect(find.text('Interests not available'), findsOneWidget);

      await selectTab('Advanced Search');
      expectNoOverflow(tester, 'dashboard Advanced Search tab');
      expect(find.text('Basic Information'), findsOneWidget);

      await selectTab('Profile');
      expectNoOverflow(tester, 'dashboard Profile tab');
      expect(find.text("You haven't completed your profile yet"), findsOneWidget);
    });
  });

  group('MatrimonialLandingPage', () {
    // Tall viewport so every section (incl. the fixed-height Success Stories
    // and membership plan carousels) is built and laid out.
    for (final width in phoneWidths) {
      for (final scale in [1.0, maxTextScale]) {
        testWidgets('renders at ${width}px, text x$scale with no overflow',
            (tester) async {
          await tester.pumpPhone(
            const MatrimonialLandingPage(),
            width: width,
            height: 4000,
            textScale: scale,
          );
          expectNoOverflow(tester, 'landing page at ${width}px x$scale');
        });
      }
    }
  });
}
