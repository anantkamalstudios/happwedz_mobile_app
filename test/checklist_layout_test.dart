// Layout + load-failure tests for the Wedding Checklist screen.
//
// Same requirement the other layout suites encode: the screen has to render
// at typical phone widths — 320, 360, 375, 390, 414 — at the app's 1.2x
// text-scale clamp, without a RenderFlex overflow or horizontal scroll.
//
// The riskiest piece is the live countdown added alongside this test: four
// DD:HH:MM:SS boxes plus three ":" separators on one row. At 320px with
// 1.2x text that row has roughly 60px per box, so it is exactly the kind of
// layout that overflows silently on a small device.
//
// No HTTP client is injected, so every request this screen makes fails in
// the test environment. That is deliberate and doubles as a regression test
// for the audit fix: a failed load must surface an error panel with a retry,
// not silently render the "no tasks yet" empty state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/WedChecklist/ChecklistScreen.dart';
import 'package:happy_wedz/core/core.dart';

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
    // Let the staggered card animations and the first frame settle. Not
    // pumpAndSettle: the countdown ticker never stops, so nothing ever settles.
    await pump(const Duration(milliseconds: 900));
  }
}

void expectNoOverflow(WidgetTester tester, String context) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $context: $error');
}

void main() {
  setUp(() {
    // A wedding date far enough out that the countdown renders its full
    // four-box DD:HH:MM:SS row — the widest state the layout ever reaches.
    final wedding = DateTime.now().add(const Duration(days: 300));
    SharedPreferences.setMockInitialValues({
      'user_id': 1234,
      'auth_token': 'test-token',
      'wedding_date':
          '${wedding.year.toString().padLeft(4, '0')}-'
          '${wedding.month.toString().padLeft(2, '0')}-'
          '${wedding.day.toString().padLeft(2, '0')}',
      'checklist_start_date': '2026-01-01',
    });
  });

  for (final width in phoneWidths) {
    testWidgets('checklist renders at ${width}px with no overflow', (
      tester,
    ) async {
      await tester.pumpPhone(
        const WeddingTimelinePage(),
        width: width,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'checklist @ ${width}px');

      // Title appears in the app bar and again as a card heading.
      expect(find.text('Wedding Checklist'), findsWidgets);
    });
  }

  testWidgets('live countdown shows all four units without overflowing at 320px', (
    tester,
  ) async {
    await tester.pumpPhone(
      const WeddingTimelinePage(),
      width: 320,
      textScale: maxTextScale,
    );
    expectNoOverflow(tester, 'countdown @ 320px');

    expect(find.text('Countdown to The Big Day'), findsOneWidget);
    expect(find.text('DAYS'), findsOneWidget);
    expect(find.text('HOURS'), findsOneWidget);
    expect(find.text('MINS'), findsOneWidget);
    expect(find.text('SECS'), findsOneWidget);
  });

  // Note: the ticker itself is not asserted here. The countdown reads
  // `DateTime.now()`, which the test binding's fake clock does not advance —
  // pumping a simulated second leaves the rendered value identical, so any
  // "it ticked" assertion would be testing the wall clock, not the widget.
  // What is worth pinning down is that the four units render and that the
  // timer is released on dispose; both are covered below.

  testWidgets('leaving the screen cancels the countdown ticker', (
    tester,
  ) async {
    await tester.pumpPhone(const WeddingTimelinePage(), width: 390);
    expect(find.text('SECS'), findsOneWidget);

    // Replacing the tree disposes the state. A surviving Timer.periodic would
    // make the test binding fail with a pending-timer error at teardown.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('SECS'), findsNothing);
  });

  testWidgets('a failed load shows an error panel with retry, not the empty state', (
    tester,
  ) async {
    await tester.pumpPhone(const WeddingTimelinePage(), width: 390);

    // Every request returns 400 in the test binding, so the screen must say
    // the load failed rather than implying the checklist is simply empty.
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Pull down to refresh'), findsOneWidget);
    expect(find.textContaining("Could not load"), findsOneWidget);
  });

  testWidgets('a signed-out user is told to sign in rather than shown an empty list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpPhone(const WeddingTimelinePage(), width: 390);

    // The category fetch also fails here and reports first, but an auth
    // failure has to win — otherwise the user is handed a Retry button that
    // can only fail again instead of the sign-in that would actually fix it.
    expect(find.textContaining('Sign in to view'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('pull-to-refresh re-runs the load and re-reports a still-failing fetch', (
    tester,
  ) async {
    await tester.pumpPhone(const WeddingTimelinePage(), width: 390);

    // Both fetches fail here, and the categories message reports first.
    expect(find.textContaining('Could not load'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(
      find.byType(RefreshIndicator),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Still failing, so the panel is still up — and exactly once, not
    // duplicated by the refresh.
    expect(find.textContaining('Could not load'), findsOneWidget);
    expectNoOverflow(tester, 'checklist after pull-to-refresh');
  });

  // Not covered by a test: clearing the panel when a retry *succeeds*. The
  // test binding fails every request with a 400 and no HTTP client is
  // injected here, so a success path cannot be produced without a fake
  // client. `_clearLoadError` is keyed by fetch source so that a checklist
  // reload after adding a task does not wipe a live category error.

  group('normalizeChecklistStatus', () {
    test('maps every shape the backend has returned onto three values', () {
      for (final done in ['completed', 'done', 'Done', 'COMPLETE', ' complete ']) {
        expect(normalizeChecklistStatus(done), 'completed', reason: done);
      }
      for (final wip in ['in_progress', 'in progress', 'In-Progress', 'inprogress']) {
        expect(normalizeChecklistStatus(wip), 'in_progress', reason: wip);
      }
      for (final pending in ['pending', 'Pending', '', null, 'something-else']) {
        expect(normalizeChecklistStatus(pending), 'pending', reason: '$pending');
      }
    });
  });
}
