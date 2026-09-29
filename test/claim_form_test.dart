// Business claim form — parity with the website's BusinessClaimForm.jsx /
// useClaimForm.js / claimFormApi.js: validation copy, keystroke rules,
// prefill from GET /vendor-services/{id}, and the JSON POST to
// /business/claims.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:happy_wedz/ClaimBusiness.dart';
import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/core/core.dart';

Map<String, String> _validForm() => {
      'businessName': 'Dream Weavers',
      'registeredAddress': 'Main Road, New Delhi',
      'phoneNumber': '9876543210',
      'emailAddress': 'hello@dreamweavers.in',
      'website': '',
      'category': 'Photographers',
      'registrationNumber': '',
    };

final Map<String, dynamic> _service = {
  'id': 77,
  'vendor_id': 12,
  'vendor_subcategory_id': 3,
  'attributes': {
    'vendor_name': 'Dream Weavers',
    'location': {'address': 'Main Road, New Delhi'},
    'cta_url': 'https://dw.example',
    'email': 'attr@dw.example',
  },
  'vendor': {
    'businessName': 'Dream Weavers Studio',
    'phone': '9876543210',
    'email': 'owner@dw.example',
    'vendorType': {'name': 'Photographers'},
  },
};

void main() {
  group('validateClaimForm (useClaimForm.validateForm)', () {
    test('valid form passes', () {
      expect(validateClaimForm(_validForm()), isNull);
    });

    test('required fields report "{Label} is required" in web order', () {
      final cases = {
        'businessName': 'Business Name is required',
        'registeredAddress': 'Registered Address is required',
        'phoneNumber': 'Business Phone Number is required',
        'emailAddress': 'Business Email is required',
        'category': 'Business Category is required',
      };
      cases.forEach((field, message) {
        final form = _validForm()..[field] = '   ';
        expect(validateClaimForm(form), message, reason: field);
      });
    });

    test('website and registration number are optional', () {
      final form = _validForm()
        ..['website'] = ''
        ..['registrationNumber'] = '';
      expect(validateClaimForm(form), isNull);
    });

    test('phone must be exactly 10 digits', () {
      final form = _validForm()..['phoneNumber'] = '98765';
      expect(validateClaimForm(form),
          'Business Phone Number must be exactly 10 digits');
    });

    test('email format', () {
      final form = _validForm()..['emailAddress'] = 'not-an-email';
      expect(validateClaimForm(form),
          'Please enter a valid business email address');
    });
  });

  group('claimInputError (handleInputChange)', () {
    test('text fields reject digits', () {
      expect(claimInputError('businessName', 'Studio 9'),
          'This field should only contain letters');
      expect(claimInputError('businessName', "O'Neil & Co"),
          'This field should only contain letters');
      expect(claimInputError('category', 'Photo-graphers, Delhi.'), isNull);
    });

    test('registration number is digits only', () {
      expect(claimInputError('registrationNumber', '12A'),
          'This field should only contain numbers');
      expect(claimInputError('registrationNumber', '123'), isNull);
    });

    test('phone is digits, at most 10', () {
      expect(claimInputError('phoneNumber', '98765432101'),
          'Please enter a valid 10-digit number');
      expect(claimInputError('phoneNumber', '98a'),
          'Please enter a valid 10-digit number');
      expect(claimInputError('phoneNumber', '9876543210'), isNull);
    });

    test('empty value is always accepted; free fields unrestricted', () {
      expect(claimInputError('businessName', ''), isNull);
      expect(claimInputError('website', 'https://x.y/1'), isNull);
      expect(claimInputError('emailAddress', 'a1@b.c'), isNull);
    });
  });

  test('prefill mirrors prefillFormData', () {
    expect(claimPrefillFrom(_service), {
      'businessName': 'Dream Weavers',
      'registeredAddress': 'Main Road, New Delhi',
      'phoneNumber': '9876543210',
      'emailAddress': 'owner@dw.example',
      'website': 'https://dw.example',
      'category': 'Photographers',
    });
    expect(claimBusinessDisplayName(_service), 'Dream Weavers Studio');
  });

  test('payload is {...formData, vendor_id, vendor_subcategory_data_id}', () {
    final payload = buildClaimPayload(_validForm(), _service);
    expect(payload['vendor_id'], 12);
    expect(payload['vendor_subcategory_data_id'], 77);
    expect(payload.keys.toSet(), {
      ...kClaimFieldKeys,
      'vendor_id',
      'vendor_subcategory_data_id',
    });
  });

  group('BusinessClaimForm widget', () {
    Future<List<http.Request>> pumpForm(
      WidgetTester tester, {
      String? serviceId,
      int postStatus = 201,
      String postBody = '{"success":true}',
      List<Object?>? popResults,
    }) async {
      final requests = <http.Request>[];
      final client = MockClient((req) async {
        requests.add(req);
        if (req.method == 'GET') {
          return http.Response(jsonEncode(_service), 200);
        }
        return http.Response(postBody, postStatus);
      });
      tester.view.physicalSize = const Size(414, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessClaimForm(
                        vendorId: '12',
                        vendorSubcategoryId: '3',
                        vendorServiceId: serviceId,
                        httpClient: client,
                      ),
                    ),
                  );
                  popResults?.add(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return requests;
    }

    testWidgets('prefills from /vendor-services/{id} and posts JSON',
        (tester) async {
      final pops = <Object?>[];
      final requests =
          await pumpForm(tester, serviceId: '77', popResults: pops);

      expect(requests.first.method, 'GET');
      expect(requests.first.url.toString(),
          '${ApiConfig.apiBase}/vendor-services/77');
      expect(find.text('Claiming Business: Dream Weavers Studio'),
          findsOneWidget);
      expect(find.text('Main Road, New Delhi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('claim_submit')));
      await tester.pumpAndSettle();

      final post = requests.last;
      expect(post.method, 'POST');
      expect(post.url.toString(), '${ApiConfig.apiBase}/business/claims');
      expect(post.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body['vendor_id'], 12);
      expect(body['vendor_subcategory_data_id'], 77);
      expect(body['businessName'], 'Dream Weavers');
      expect(body['phoneNumber'], '9876543210');
      expect(body['registrationNumber'], '');

      expect(find.text('Claim form submitted successfully!'), findsOneWidget);
      expect(pops, [true]);
    });

    testWidgets('validation blocks submit with the web copy', (tester) async {
      final requests = await pumpForm(tester, serviceId: '77');
      await tester.enterText(
          find.descendant(
              of: find.byKey(const ValueKey('claim_phoneNumber')),
              matching: find.byType(EditableText)),
          '98765');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('claim_submit')));
      await tester.pump();
      expect(find.text('Business Phone Number must be exactly 10 digits'),
          findsOneWidget);
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('rejected keystroke keeps previous value and toasts',
        (tester) async {
      await pumpForm(tester, serviceId: '77');
      final nameField = find.descendant(
          of: find.byKey(const ValueKey('claim_businessName')),
          matching: find.byType(EditableText));
      await tester.enterText(nameField, 'Dream Weavers 2');
      await tester.pump();
      expect(find.text('This field should only contain letters'),
          findsOneWidget);
      expect(
          tester.widget<EditableText>(nameField).controller.text,
          'Dream Weavers');
    });

    testWidgets('no service id: cannot identify business, nothing posted',
        (tester) async {
      final requests = await pumpForm(tester);
      expect(requests, isEmpty);
      Future<void> type(String key, String v) => tester.enterText(
          find.descendant(
              of: find.byKey(ValueKey('claim_$key')),
              matching: find.byType(EditableText)),
          v);
      await type('businessName', 'Dream Weavers');
      await type('registeredAddress', 'Main Road');
      await type('phoneNumber', '9876543210');
      await type('emailAddress', 'a@b.co');
      await type('category', 'Photographers');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('claim_submit')));
      await tester.pumpAndSettle();
      expect(find.text(kClaimMissingVendorMessage), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('server error shows server message, stays on form',
        (tester) async {
      final pops = <Object?>[];
      await pumpForm(tester,
          serviceId: '77',
          postStatus: 400,
          postBody: '{"message":"A claim already exists"}',
          popResults: pops);
      await tester.tap(find.byKey(const ValueKey('claim_submit')));
      await tester.pumpAndSettle();
      expect(find.text('A claim already exists'), findsOneWidget);
      expect(find.byType(BusinessClaimForm), findsOneWidget);
      expect(pops, isEmpty);
    });
  });
}
