// Quick Inquiry — validation copy and request shape must match the web's
// QuickInquiryModal.jsx.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/vendor/quick_inquiry_sheet.dart';

Future<void> _pump(WidgetTester tester, QuickInquiryForm form) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: form)),
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _field(String label) => find.byWidgetPredicate((w) => w is AppTextField && w.label == label);

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.descendant(of: _field(label), matching: find.byType(TextField)), text);
  await tester.pump();
}

Future<void> _pickToday(WidgetTester tester) async {
  await tester.tap(_field('Event Date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.text('Send Quick Inquiry'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the web copy', (tester) async {
    await _pump(tester, const QuickInquiryForm(vendorId: '1', vendorName: 'Vista'));
    expect(find.text('Inquiring about:'), findsOneWidget);
    expect(find.text('Vista'), findsOneWidget);
    expect(find.text("📱 We'll share this with the vendor to contact you"), findsOneWidget);
    expect(find.text('✨ No account needed! The vendor will contact you directly.'), findsOneWidget);
  });

  testWidgets('validation messages in web order', (tester) async {
    await _pump(tester, const QuickInquiryForm(vendorId: '1', vendorName: 'Vista'));

    await _send(tester);
    expect(find.text('⚠️ Please fill in all fields.'), findsOneWidget);

    await _enter(tester, 'Your Name', 'Asha Rao');
    await _enter(tester, 'Phone Number', '98765');
    await _send(tester);
    expect(find.text('⚠️ Please fill in all fields.'), findsOneWidget, reason: 'date still missing');

    await _pickToday(tester);
    await _send(tester);
    expect(find.text('⚠️ Please enter a valid phone number.'), findsOneWidget);
  });

  testWidgets('missing vendor id', (tester) async {
    await _pump(tester, const QuickInquiryForm(vendorId: '', vendorName: 'Vista'));
    await _enter(tester, 'Your Name', 'Asha');
    await _enter(tester, 'Phone Number', '9876543210');
    await _pickToday(tester);
    await _send(tester);
    expect(find.text('⚠️ Could not identify the vendor. Please try again.'), findsOneWidget);
  });

  testWidgets('posts the guest payload without auth, then the conversation', (tester) async {
    final requests = <http.Request>[];
    final client = MockClient((r) async {
      requests.add(r);
      if (r.url.path == '/request-pricing') {
        return http.Response('{"message":"ok","request":{"id":321}}', 201,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{"message":"Unauthorized"}', 401);
    });
    var sent = false;
    await _pump(
      tester,
      QuickInquiryForm(vendorId: '55', vendorName: 'Vista', client: client, onSent: () => sent = true),
    );
    await _enter(tester, 'Your Name', 'Asha  Rao Kumar');
    await _enter(tester, 'Phone Number', '+91 98765 43210');
    await _pickToday(tester);
    await _send(tester);
    await tester.pumpAndSettle();

    expect(sent, isTrue);
    expect(requests.length, 2);
    final first = requests[0];
    expect(first.url.toString(), 'https://api.happywedz.com/request-pricing');
    expect(first.headers.containsKey('Authorization'), isFalse);
    final body = jsonDecode(first.body) as Map<String, dynamic>;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    expect(body['vendorId'], 55);
    expect(body['firstName'], 'Asha');
    expect(body['lastName'], ' Rao Kumar'); // web: split(" ").slice(1).join(" ")
    expect(body['email'], matches(RegExp(r'^guest_\d+@happywedz\.com$')));
    expect(body['phone'], '+91 98765 43210');
    expect(body['eventDate'], today);
    expect(body['message'], 'Quick inquiry from listing page');
    expect(body['isGuestInquiry'], true);

    final second = requests[1];
    expect(second.url.toString(), 'https://api.happywedz.com/messages/user/conversations');
    expect(second.bodyFields, {'vendorId': '55', 'requestId': '321'});
  });

  testWidgets('server message is shown on failure', (tester) async {
    final client = MockClient((_) async => http.Response('{"message":"Vendor not found"}', 404));
    await _pump(tester, QuickInquiryForm(vendorId: '55', vendorName: 'Vista', client: client));
    await _enter(tester, 'Your Name', 'Asha');
    await _enter(tester, 'Phone Number', '9876543210');
    await _pickToday(tester);
    await _send(tester);
    await tester.pumpAndSettle();
    expect(find.text('⚠️ Vendor not found'), findsOneWidget);
  });

  testWidgets('generic error when the body has no message', (tester) async {
    final client = MockClient((_) async => http.Response('<html>', 502));
    await _pump(tester, QuickInquiryForm(vendorId: '55', vendorName: 'Vista', client: client));
    await _enter(tester, 'Your Name', 'Asha');
    await _enter(tester, 'Phone Number', '9876543210');
    await _pickToday(tester);
    await _send(tester);
    await tester.pumpAndSettle();
    expect(find.text('⚠️ Something went wrong.'), findsOneWidget);
  });
}
