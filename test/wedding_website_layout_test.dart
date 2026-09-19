// Layout test for the Wedding Website create/edit form.
//
// Same requirement `test/honeymoon_booking_layout_test.dart` encodes: the
// screen has to render at typical phone widths — 320, 360, 375, 390, 414 —
// with the keyboard open or shut and at the app's 1.2x text-scale clamp,
// without a RenderFlex overflow or horizontal scroll.
//
// The form is exercised in "create" mode (no `editId`), which never touches
// the network on first build — `WeddingWebsiteFormPage._load()` short-
// circuits to `_initializing = false` immediately when there is nothing to
// fetch, so this stays a pure widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/wedding_website/models/wedding_website_models.dart';
import 'package:happy_wedz/wedding_website/ui/wedding_website_form_page.dart';

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

void main() {
  for (final template in WeddingWebsiteTemplate.values) {
    for (final width in phoneWidths) {
      testWidgets(
        '${template.label} form renders at ${width}px with no overflow',
        (tester) async {
          await tester.pumpPhone(
            WeddingWebsiteFormPage(template: template),
            width: width,
            textScale: maxTextScale,
          );
          expectNoOverflow(tester, '${template.label} @ ${width}px');

          expect(find.text('Wedding date'), findsOneWidget);
          expect(find.text('Bride'), findsOneWidget);
          expect(find.text('Groom'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('form survives the keyboard open at the narrowest width', (tester) async {
    await tester.pumpPhone(
      const WeddingWebsiteFormPage(template: WeddingWebsiteTemplate.royal),
      width: 320,
      textScale: maxTextScale,
      bottomInset: 300,
    );
    expectNoOverflow(tester, 'royal form, keyboard open, 320px');
  });

  testWidgets('adding love-story / wedding-party / when-where entries does not overflow', (tester) async {
    await tester.pumpPhone(
      const WeddingWebsiteFormPage(template: WeddingWebsiteTemplate.modern),
      width: 360,
      textScale: maxTextScale,
    );

    // Each repeatable section's header carries its own key (the plain
    // ListView only builds visible children, so off-screen "Add" buttons
    // don't exist in the tree until scrolled into view).
    for (final headerKey in const [
      Key('wedding_website_form_love_story_header'),
      Key('wedding_website_form_wedding_party_header'),
      Key('wedding_website_form_when_where_header'),
    ]) {
      final addButton = find.descendant(
        of: find.byKey(headerKey),
        matching: find.text('Add'),
      );
      await tester.dragUntilVisible(addButton, find.byType(ListView), const Offset(0, -200));
      await tester.tap(addButton);
      await tester.pump(const Duration(milliseconds: 300));
    }

    expectNoOverflow(tester, 'modern form after adding one of each entry');
  });
}
