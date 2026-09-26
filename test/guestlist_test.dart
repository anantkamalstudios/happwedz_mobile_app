// Guest List — layout, parsing and enum tests.
//
// Layout: the dashboard and the add/edit form must render at typical phone
// widths (320–414) at the app's 1.2x text-scale clamp with no RenderFlex
// overflow, including with the keyboard open on the form.
//
// Parsing: `Guest.fromJson` used to assign `json['companions']`,
// `json['name']` and friends straight into non-nullable typed fields with no
// coercion, so an API that returned `companions: "2"` threw inside the
// `.map()` in `fetchGuests` and the whole list became a generic error. And
// `status`/`type`/`menu` went into DropdownButtons unchecked, which asserts
// on any value outside the three/two/six literals — a guest created on the
// website with a "Jain" menu was enough.
//
// No HTTP client is injected, so every request fails in the test binding.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/guestlist/guestlist.dart';

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
    await pump(const Duration(milliseconds: 500));
  }
}

void expectNoOverflow(WidgetTester tester, String context) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $context: $error');
}

Guest _guest({
  int? id = 1,
  String name = 'Asha Menon',
  String status = 'Pending',
  String type = 'Adult',
  String menu = 'Veg',
  int companions = 0,
}) =>
    Guest(
      id: id,
      name: name,
      group: 'Family',
      status: status,
      companions: companions,
      type: type,
      menu: menu,
      phoneNumber: '9876543210',
      email: 'asha@example.com',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 1234,
      'auth_token': 'test-token',
    });
  });

  group('layout', () {
    for (final width in phoneWidths) {
      testWidgets('dashboard renders at ${width}px with no overflow', (
        tester,
      ) async {
        await tester.pumpPhone(
          const GuestListDashboard(),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'guest dashboard @ ${width}px');
        expect(find.text('Guest List'), findsOneWidget);
      });

      testWidgets('add form renders at ${width}px with no overflow', (
        tester,
      ) async {
        await tester.pumpPhone(
          const GuestFormScreen(),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'add guest form @ ${width}px');
        expect(find.text('Add Guest'), findsOneWidget);
      });
    }

    // The tests above render an EMPTY dashboard — every request fails in the
    // test binding, so `_buildGuestCard` was never built and a 12px overflow
    // in the card's action row shipped and crashed on device. These seed the
    // list so the card is actually laid out.
    for (final width in phoneWidths) {
      testWidgets('guest card renders at ${width}px with no overflow', (
        tester,
      ) async {
        await tester.pumpPhone(
          GuestListDashboard(
            debugInitialGuests: [
              _guest(id: 1, name: 'Asha Menon'),
              _guest(id: 2, name: 'Rohit Deshpande', status: 'Attending'),
              _guest(
                id: 3,
                name: 'A guest with a considerably longer name than usual',
                status: 'Not Attending',
                type: 'Child',
                menu: 'Eggetarian',
                companions: 4,
              ),
            ],
          ),
          width: width,
          textScale: maxTextScale,
        );

        expectNoOverflow(tester, 'guest card @ ${width}px');
        expect(find.text('Asha Menon'), findsOneWidget);
        // The row has to fit every action. Not an exact count: the list is a
        // ListView.builder, so off-screen cards are not built.
        expect(find.byTooltip('Edit'), findsWidgets);
        expect(find.byTooltip('Delete'), findsWidgets);
        expect(find.byTooltip('Email'), findsWidgets);
        expect(find.byTooltip('WhatsApp'), findsWidgets);
      });
    }

    testWidgets('the longest status still fits the card action row at 320px', (
      tester,
    ) async {
      await tester.pumpPhone(
        GuestListDashboard(
          debugInitialGuests: [
            // "Not Attending" is the widest of the three status strings.
            _guest(id: 1, name: 'X', status: 'Not Attending'),
          ],
        ),
        width: 320,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'widest status @ 320px');
    });

    testWidgets('form survives the keyboard open at the narrowest width', (
      tester,
    ) async {
      await tester.pumpPhone(
        const GuestFormScreen(),
        width: 320,
        textScale: maxTextScale,
        bottomInset: 300,
      );
      expectNoOverflow(tester, 'add form, keyboard open, 320px');
    });

    testWidgets('edit mode prefills and exposes an RSVP control', (
      tester,
    ) async {
      await tester.pumpPhone(
        GuestFormScreen(existing: _guest(status: 'Attending')),
        width: 390,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'edit guest form @ 390px');

      // The add form deliberately has no status control — the website always
      // creates "Pending" — so this is what distinguishes edit mode.
      expect(find.text('Edit Guest'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('RSVP Status'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Asha Menon'), findsOneWidget);
    });
  });

  group('Guest.fromJson', () {
    test('coerces numeric fields sent as strings instead of throwing', () {
      final g = Guest.fromJson({
        'id': '42',
        'name': 'Ravi',
        'companions': '3',
        'phone_number': 9876543210,
        'seat_number': 12,
      });

      expect(g.id, 42);
      expect(g.companions, 3);
      expect(g.phoneNumber, '9876543210');
      expect(g.seatNumber, '12');
    });

    test('survives a row with nothing in it', () {
      final g = Guest.fromJson({});
      expect(g.id, isNull);
      expect(g.name, '');
      expect(g.companions, 0);
      expect(g.status, 'Pending');
      expect(g.type, 'Adult');
      expect(g.menu, 'Veg');
    });

    test('normalizes every enum so no DropdownButton can assert', () {
      expect(Guest.fromJson({'status': 'attending'}).status, 'Attending');
      expect(Guest.fromJson({'status': 'NOT ATTENDING'}).status, 'Not Attending');
      expect(Guest.fromJson({'status': 'Declined'}).status, 'Pending');
      expect(Guest.fromJson({'status': null}).status, 'Pending');
      expect(Guest.fromJson({'type': 'child'}).type, 'Child');
      expect(Guest.fromJson({'type': 'Infant'}).type, 'Adult');
      // The menu list used to be Veg/NonVeg/All only, so a website-created
      // "Jain" guest had no matching dropdown item.
      expect(Guest.fromJson({'menu': 'Jain'}).menu, 'Jain');
      expect(Guest.fromJson({'menu': 'eggetarian'}).menu, 'Eggetarian');
      expect(Guest.fromJson({'menu': 'Halal'}).menu, 'Veg');
    });

    test('reads the group fields the website writes', () {
      final g = Guest.fromJson({
        'city': 'Nashik',
        'group': 'Nashik',
        'groupId': 7,
        'groupData': {'name': 'Bride Side'},
      });
      expect(g.city, 'Nashik');
      expect(g.group, 'Nashik');
      // Kept as a String so a numeric id compares against /groups reliably —
      // the website's strict === on this silently buckets guests as "Other".
      expect(g.groupId, '7');
      expect(g.groupDataName, 'Bride Side');
    });
  });

  group('enums match the website', () {
    test('exact values, including the space in "Not Attending"', () {
      expect(kGuestStatusOptions, ['Attending', 'Not Attending', 'Pending']);
      expect(kGuestTypeOptions, ['Adult', 'Child']);
      expect(kGuestMenuOptions,
          ['Veg', 'NonVeg', 'Jain', 'Vegan', 'Eggetarian', 'All']);
    });

    test('normalizeGuestOption falls back rather than returning junk', () {
      expect(normalizeGuestOption(null, kGuestMenuOptions, 'Veg'), 'Veg');
      expect(normalizeGuestOption('  vegan ', kGuestMenuOptions, 'Veg'), 'Vegan');
      expect(normalizeGuestOption('nonsense', kGuestMenuOptions, 'Veg'), 'Veg');
    });
  });

  group('create-group dialog lifecycle', () {
    // Regression: the dialog's TextEditingController used to be created next
    // to `showDialog` and disposed as soon as the await returned. `showDialog`
    // completes on `Navigator.pop`, while the dialog is still animating out
    // and its TextField is still rebuilding — so the next frame threw
    // "A TextEditingController was used after being disposed", which then
    // cascaded into a second assertion as the overlay tore down.
    //
    // The controller now belongs to a StatefulWidget that disposes it when
    // the route is actually gone. Pumping past the exit transition is the
    // whole point of these tests — `pumpAndSettle` runs it to completion.

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);
      await tester.tap(find.byTooltip('Create group'));
      await tester.pumpAndSettle();
      expect(find.text('New group'), findsOneWidget);
    }

    testWidgets('cancelling survives the exit animation', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('New group'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('creating survives the exit animation', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextField).last, 'Bride Side');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('New group'), findsNothing);
      // The POST fails in the test binding; what matters is that no
      // controller was touched after disposal on the way out.
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening and closing repeatedly does not reuse a controller', (
      tester,
    ) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Create group'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'iteration $i');
      }
    });

  });

  group('validation', () {
    testWidgets('a whitespace-only name is rejected', (tester) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Guest Name'), '   ');
      await tester.tap(find.text('Save Guest'));
      await tester.pump();

      // The old validator used `v.isEmpty` on the untrimmed string, so "   "
      // saved fine — and then crashed the list on `guest.name[0]`.
      expect(find.text('Guest name is required.'), findsOneWidget);
    });

    testWidgets('an email without an @ is rejected on create', (tester) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Guest Name'), 'Ravi');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'x');
      await tester.tap(find.text('Save Guest'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('a short phone number is rejected', (tester) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Guest Name'), 'Ravi');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'ravi@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone (optional)'), '12345');
      await tester.tap(find.text('Save Guest'));
      await tester.pump();

      expect(find.text('Enter at least 10 digits.'), findsOneWidget);
    });

    testWidgets('negative companions are rejected', (tester) async {
      await tester.pumpPhone(const GuestFormScreen(), width: 390);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Guest Name'), 'Ravi');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'ravi@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Companions'), '-3');
      await tester.tap(find.text('Save Guest'));
      await tester.pump();

      expect(find.text('Cannot be negative.'), findsOneWidget);
    });

    testWidgets('email may be left blank when editing', (tester) async {
      await tester.pumpPhone(
        GuestFormScreen(existing: _guest()),
        width: 390,
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email (optional)'), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // Matches the website, which requires an email on create but not on edit.
      expect(find.text('Email is required.'), findsNothing);
      expect(find.text('Please enter a valid email address.'), findsNothing);
    });
  });
}
