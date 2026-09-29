// Info / legal pages ported from the website (About Us, Careers, Contact Us,
// Privacy Policy, Terms & Condition, Cancellation Policy).
//
// * Every page renders at 320x640 (and at the 1.2x text-scale clamp) with no
//   layout exception, scrolled top to bottom, and shows verbatim web copy.
// * Legal text is parsed with the web's line rules.
// * The contact form validates exactly like Contactus.jsx and POSTs the same
//   JSON body to {apiBase}/contact — against a MockClient, never the real API.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/info_pages/info_page_widgets.dart';
import 'package:happy_wedz/info_pages/info_pages.dart';
import 'package:happy_wedz/info_pages/legal_content.dart';

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  double width = 320,
  double height = 640,
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: page,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void _expectNoLayoutError(WidgetTester tester, String where) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $where: $error');
}

/// Drags the page's main vertical scrollable from top to bottom, checking
/// for layout errors on the way.
Future<void> _scrollThrough(WidgetTester tester, String where) async {
  final scrollable = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  final state = tester.state<ScrollableState>(scrollable.first);
  for (var i = 0; i < 200; i++) {
    final pos = state.position;
    if (pos.pixels >= pos.maxScrollExtent) break;
    pos.jumpTo((pos.pixels + 400).clamp(0, pos.maxScrollExtent));
    await tester.pump();
    _expectNoLayoutError(tester, '$where (offset ${pos.pixels})');
  }
  state.position.jumpTo(0);
  await tester.pump();
}

void main() {
  group('parseLegalContent (web formatContent rules)', () {
    test('headings, bullets, paragraphs and <br> spacers', () {
      final lines = parseLegalContent(
        '\n  Intro line\n\n1. Numbered heading\na) Lettered heading\n'
        '• Bullet text \n  plain paragraph\n',
      );
      expect(lines.map((l) => l.kind).toList(), [
        LegalLineKind.paragraph,
        LegalLineKind.spacer,
        LegalLineKind.heading,
        LegalLineKind.heading,
        LegalLineKind.bullet,
        LegalLineKind.paragraph,
      ]);
      expect(lines[4].text, 'Bullet text');
      expect(lines[2].text, '1. Numbered heading');
    });

    test('"100%" or "18 and over" are not headings (needs "N. ")', () {
      expect(parseLegalContent('100% secure').single.kind,
          LegalLineKind.paragraph);
      expect(parseLegalContent('A) upper-case letter').single.kind,
          LegalLineKind.paragraph);
    });
  });

  group('legal content matches the live site', () {
    test('privacy sections, order and last-updated date', () {
      expect(privacyPolicySections.map((s) => s.title).toList(), [
        'Overview',
        'Information We Collect',
        'How We Use Your Information',
        'When We Share Information',
        'Cookies & Tracking',
        'Payments & Financial Data',
        'Retention & Deleting Your Account',
        'Your Rights & Security',
        'Contact & Grievances',
      ]);
      expect(privacyPolicySections.first.content,
          contains('Last Updated: 23 September 2026'));
      expect(privacyPolicySections.last.content,
          contains('Grievance Officer, HappyWedz'));
      for (final s in privacyPolicySections) {
        expect(s.content, isNot(contains('\r')));
      }
    });

    test('terms sections, order and last-updated date', () {
      expect(termsSections.map((s) => s.title).toList(), [
        'Terms of Service',
        'Privacy Policy',
        'Cookie Policy',
        'Intellectual Property Policy',
        'Disclaimer of Liability',
      ]);
      expect(termsSections.first.content,
          contains('Last Updated: 04 Oct 2025'));
    });
  });

  group('InfoPage helper', () {
    test('footer order, labels and web paths', () {
      expect(InfoPage.values.map((p) => p.title).toList(), [
        'About HappyWedz', // website footer label
        'Careers',
        'Contact Us',
        'Privacy Policy',
        'Terms & Condition',
        'Cancellation Policy',
      ]);
      expect(InfoPage.fromWebPath('/contact-us'), InfoPage.contactUs);
      // Every info page opens the live website page.
      expect(InfoPage.privacyPolicy.externalUrl.toString(),
          'https://happywedz.com/privacy');
      expect(InfoPage.cancellationPolicy.externalUrl.toString(),
          'https://happywedz.com/cancellation');
      expect(InfoPage.terms.externalUrl.toString(),
          'https://happywedz.com/terms');
      expect(InfoPage.aboutUs.externalUrl.toString(),
          'https://happywedz.com/about-us');
      expect(InfoPage.careers.externalUrl.toString(),
          'https://happywedz.com/careers');
      expect(InfoPage.contactUs.externalUrl.toString(),
          'https://happywedz.com/contact-us');
      expect(InfoPage.fromWebPath('/terms?x=1'), InfoPage.terms);
      expect(InfoPage.fromWebPath('/blog'), isNull);
    });

    // No info page opens natively any more (all open the website, 2026-09-29).
    // testWidgets('open() pushes the native page', (tester) async {
    //   await _pumpPage(
    //     tester,
    //     Builder(
    //       builder: (context) => Scaffold(
    //         body: TextButton(
    //           onPressed: () => InfoPage.contactUs.open(context),
    //           child: const Text('go'),
    //         ),
    //       ),
    //     ),
    //   );
    //   await tester.tap(find.text('go'));
    //   await tester.pumpAndSettle();
    //   expect(find.byType(ContactUsPage), findsOneWidget);
    // });
  });

  group('pages render at 320x640 without layout errors', () {
    for (final scale in [1.0, 1.2]) {
      testWidgets('About Us @${scale}x', (tester) async {
        await _pumpPage(tester, const AboutUsPage(), textScale: scale);
        _expectNoLayoutError(tester, 'AboutUs');
        expect(find.text('About HappyWedz'), findsOneWidget);
        expect(find.text(AboutUsPage.intro), findsOneWidget);
        await _scrollThrough(tester, 'AboutUs');
        await tester.scrollUntilVisible(
          find.text('Satisfied Clients'),
          300,
          scrollable: find
              .byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down)
              .first,
        );
        expect(find.text('18k+'), findsOneWidget);
        expect(find.text('370+'), findsOneWidget);
      });

      testWidgets('Careers @${scale}x + tab switch', (tester) async {
        await _pumpPage(tester, const CareersPage(), textScale: scale);
        _expectNoLayoutError(tester, 'Careers');
        expect(find.text('HappyWedz Careers'), findsOneWidget);
        expect(find.text('TECHNOLOGY'), findsOneWidget);
        await _scrollThrough(tester, 'Careers/technology');
        expect(find.text('AI Product Research Intern'), findsOneWidget);

        await tester.tap(find.text('BUSINESS'));
        await tester.pumpAndSettle();
        expect(find.text('Creative Content Strategist'), findsOneWidget);
        expect(find.text('AI Product Research Intern'), findsNothing);
        await _scrollThrough(tester, 'Careers/business');
      });

      testWidgets('Cancellation Policy @${scale}x', (tester) async {
        await _pumpPage(
          tester,
          const CancellationPolicyPage(),
          textScale: scale,
        );
        _expectNoLayoutError(tester, 'Cancellation');
        expect(find.text('Cancellation Policy'), findsOneWidget);
        expect(
          find.text(
            'Understanding how cancellations and refunds work on Happywedz.',
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Important Notice'),
          300,
          scrollable: find
              .byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down)
              .first,
        );
        expect(find.text('4. Vendor Cancellation'), findsOneWidget);
        await _scrollThrough(tester, 'Cancellation');
      });

      testWidgets('Contact Us @${scale}x', (tester) async {
        await _pumpPage(tester, const ContactUsPage(), textScale: scale);
        _expectNoLayoutError(tester, 'ContactUs');
        expect(find.text('CONTACT US'), findsOneWidget);
        expect(find.text('SUBMIT'), findsOneWidget);
        await _scrollThrough(tester, 'ContactUs');
      });

      testWidgets('Privacy Policy @${scale}x, every section', (tester) async {
        await _pumpPage(tester, const PrivacyPolicyPage(), textScale: scale);
        _expectNoLayoutError(tester, 'Privacy');
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Last Updated: 23 September 2026'), findsOneWidget);
        await _visitEverySection(tester, privacyPolicySections, 'Privacy');
      });

      testWidgets('Terms @${scale}x, every section', (tester) async {
        await _pumpPage(tester, const TermsPage(), textScale: scale);
        _expectNoLayoutError(tester, 'Terms');
        expect(find.text('Legal Terms & Policies'), findsOneWidget);
        expect(find.text('Last Updated: 04 Oct 2025'), findsOneWidget);
        await _visitEverySection(tester, termsSections, 'Terms');
      });
    }

    testWidgets('Terms footer follows the active section', (tester) async {
      await _pumpPage(tester, const TermsPage(initialSectionId: 'cookies'));
      expect(find.text('Have questions about our cookie policy?'),
          findsOneWidget);
    });

    testWidgets('Privacy footer "contact support" opens Contact Us',
        (tester) async {
      await _pumpPage(tester, const PrivacyPolicyPage());
      final link = find.text('contact support');
      await tester.scrollUntilVisible(
        link,
        400,
        scrollable: find
            .byWidgetPredicate((w) =>
                w is Scrollable && w.axisDirection == AxisDirection.down)
            .first,
      );
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(ContactUsPage), findsOneWidget);
    });
  });

  group('contact form validation (Contactus.jsx)', () {
    ContactFormData form({
      String first = 'Asha',
      String last = 'Rao',
      String email = 'asha@example.com',
      String phone = '9876543210',
      String message = 'Hello',
    }) =>
        ContactFormData(
          firstName: first,
          lastName: last,
          email: email,
          phone: phone,
          message: message,
        );

    const incomplete = ContactValidationError(
      title: 'Incomplete Form',
      message: 'Please fill out all fields.',
    );
    const badEmail = ContactValidationError(
      title: 'Invalid Email',
      message: 'Please enter a valid email address.',
    );
    const badPhone = ContactValidationError(
      message: 'Please enter a valid 10-digit phone number.',
    );

    test('valid form passes', () => expect(validateContactForm(form()), isNull));

    test('any blank / whitespace field → Incomplete Form', () {
      expect(validateContactForm(form(first: '  ')), incomplete);
      expect(validateContactForm(form(last: '')), incomplete);
      expect(validateContactForm(form(email: ' ')), incomplete);
      expect(validateContactForm(form(phone: '')), incomplete);
      expect(validateContactForm(form(message: '\n')), incomplete);
    });

    test('email regex /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+\$/', () {
      expect(validateContactForm(form(email: 'a@b')), badEmail);
      expect(validateContactForm(form(email: 'a b@c.d')), badEmail);
      expect(validateContactForm(form(email: ' a@b.co')), badEmail);
      expect(validateContactForm(form(email: 'a@b.co')), isNull);
    });

    test('phone must be exactly 10 digits', () {
      expect(validateContactForm(form(phone: '987654321')), badPhone);
      expect(validateContactForm(form(phone: '98765432101')), badPhone);
      expect(validateContactForm(form(phone: '+919876543210')), badPhone);
      expect(validateContactForm(form(phone: '98765 43210')), badPhone);
    });

    test('email is checked before phone', () {
      expect(validateContactForm(form(email: 'x', phone: '1')), badEmail);
    });
  });

  group('ContactApi', () {
    const data = ContactFormData(
      firstName: 'Asha',
      lastName: 'Rao',
      email: 'asha@example.com',
      phone: '9876543210',
      message: 'Hello there',
    );

    test('POSTs JSON to {apiBase}/contact without auth when signed out',
        () async {
      late http.Request sent;
      final api = ContactApi(
        client: MockClient((req) async {
          sent = req;
          return http.Response('{"success":true}', 201);
        }),
        tokenReader: () async => null,
      );
      await api.submit(data);
      expect(sent.method, 'POST');
      expect(sent.url.toString(), '${ApiConfig.apiBase}/contact');
      expect(sent.url.toString(), 'https://api.happywedz.com/contact');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(sent.body), {
        'firstName': 'Asha',
        'lastName': 'Rao',
        'email': 'asha@example.com',
        'phone': '9876543210',
        'message': 'Hello there',
      });
    });

    test('adds Bearer token when one is saved', () async {
      late http.Request sent;
      final api = ContactApi(
        client: MockClient((req) async {
          sent = req;
          return http.Response('{}', 200);
        }),
        tokenReader: () async => 'abc123',
      );
      await api.submit(data);
      expect(sent.headers['Authorization'], 'Bearer abc123');
    });

    test('non-2xx → server message, else fallback', () async {
      ContactApi apiReturning(http.Response r) => ContactApi(
            client: MockClient((_) async => r),
            tokenReader: () async => null,
          );
      await expectLater(
        apiReturning(http.Response('{"message":"Email already used"}', 400))
            .submit(data),
        throwsA(isA<ContactSubmitException>()
            .having((e) => e.message, 'message', 'Email already used')),
      );
      await expectLater(
        apiReturning(http.Response('<html>oops</html>', 500)).submit(data),
        throwsA(isA<ContactSubmitException>().having((e) => e.message,
            'message', 'Failed to submit form. Please try again.')),
      );
    });

    test('network failure → fallback message', () async {
      final api = ContactApi(
        client: MockClient((_) async => throw http.ClientException('down')),
        tokenReader: () async => null,
      );
      await expectLater(
        api.submit(data),
        throwsA(isA<ContactSubmitException>().having((e) => e.message,
            'message', 'Failed to submit form. Please try again.')),
      );
    });
  });

  group('ContactUsPage submit flow', () {
    Future<void> fill(WidgetTester tester, {String phone = '9876543210'}) async {
      Future<void> enter(String key, String text) async {
        final f = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.enterText(f, text);
      }

      await enter('contact-firstName', 'Asha');
      await enter('contact-lastName', 'Rao');
      await enter('contact-email', 'asha@example.com');
      await enter('contact-phone', phone);
      await enter('contact-message', 'Hello there');
    }

    Future<void> tapSubmit(WidgetTester tester) async {
      final btn = find.byKey(const ValueKey('contact-submit'));
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
    }

    testWidgets('empty form shows Incomplete Form and sends nothing',
        (tester) async {
      var calls = 0;
      await _pumpPage(
        tester,
        ContactUsPage(
          api: ContactApi(
            client: MockClient((_) async {
              calls++;
              return http.Response('{}', 200);
            }),
            tokenReader: () async => null,
          ),
        ),
      );
      await tapSubmit(tester);
      await tester.pump();
      expect(find.text('Incomplete Form'), findsOneWidget);
      expect(find.text('Please fill out all fields.'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('bad phone shows the 10-digit message', (tester) async {
      var calls = 0;
      await _pumpPage(
        tester,
        ContactUsPage(
          api: ContactApi(
            client: MockClient((_) async {
              calls++;
              return http.Response('{}', 200);
            }),
            tokenReader: () async => null,
          ),
        ),
      );
      await fill(tester, phone: '12345');
      await tapSubmit(tester);
      await tester.pump();
      expect(find.text('Please enter a valid 10-digit phone number.'),
          findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('success: loading label, success message, form cleared',
        (tester) async {
      http.Request? sent;
      await _pumpPage(
        tester,
        ContactUsPage(
          api: ContactApi(
            client: MockClient((req) async {
              sent = req;
              await Future<void>.delayed(const Duration(milliseconds: 200));
              return http.Response('{"success":true}', 201);
            }),
            tokenReader: () async => 'tok',
          ),
        ),
      );
      await fill(tester);
      await tapSubmit(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('SUBMITTING...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Form submitted successfully!'), findsOneWidget);
      expect(find.text('SUBMIT'), findsOneWidget);
      expect(sent!.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(sent!.body)['message'], 'Hello there');
      for (final key in [
        'contact-firstName',
        'contact-lastName',
        'contact-email',
        'contact-phone',
        'contact-message',
      ]) {
        final field = tester.widget<EditableText>(find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ));
        expect(field.controller.text, isEmpty, reason: key);
      }
      _expectNoLayoutError(tester, 'ContactUs success');
    });

    testWidgets('server error message is shown and form kept',
        (tester) async {
      await _pumpPage(
        tester,
        ContactUsPage(
          api: ContactApi(
            client: MockClient(
              (_) async => http.Response('{"message":"Server busy"}', 503),
            ),
            tokenReader: () async => null,
          ),
        ),
      );
      await fill(tester);
      await tapSubmit(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Server busy'), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
    });
  });
}

Future<void> _visitEverySection(
  WidgetTester tester,
  List<LegalSection> sections,
  String where,
) async {
  final chipList = find.byKey(const ValueKey('legal-section-selector'));
  for (final s in sections) {
    final chip = find.descendant(
      of: chipList,
      matching: find.widgetWithText(ChoiceChip, s.title),
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('legal-content-${s.id}')), findsOneWidget);
    _expectNoLayoutError(tester, '$where/${s.id}');
    await _scrollThrough(tester, '$where/${s.id}');
  }
}
