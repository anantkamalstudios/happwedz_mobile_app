// Write-a-review flow — parity with the website's WriteReviewPage.jsx:
// rating labels → backend fields, step validation copy, always-multipart
// POST to ${apiBase}/reviews/{serviceId}, and popping back with `true`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/Review.dart';
import 'package:happy_wedz/authservice.dart';
import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/main.dart' show rootNavigatorKey;

ReviewData _complete() => ReviewData.simple(
      wouldRecommend: 'yes',
      happywedzHelped: 'yes',
    )
      ..ratingQuality = 5
      ..ratingResponsiveness = 4
      ..ratingProfessionalism = 3
      ..ratingValue = 2
      ..ratingFlexibility = 1
      ..title = 'Amazing'
      ..comment = 'Loved it';

void main() {
  test('web rating labels map to the web backend fields', () {
    expect(kReviewRatingLabels, {
      'rating_quality': 'Quality',
      'rating_responsiveness': 'Responsiveness',
      'rating_professionalism': 'Professionalism',
      'rating_value': 'Value',
      'rating_flexibility': 'Flexibility',
    });
  });

  test('ratings error lists missing labels in web order', () {
    final d = ReviewData.simple(wouldRecommend: 'yes', happywedzHelped: 'yes')
      ..ratingProfessionalism = 4;
    expect(reviewRatingsError(d),
        'Please select a star rating for: Quality, Responsiveness, Value, Flexibility');
    expect(reviewRatingsError(_complete()), isNull);
  });

  test('title / comment copy', () {
    expect(reviewTextError(' ', 'x'), 'Please provide a title for your review.');
    expect(reviewTextError('x', ''),
        'Please write a comment about your experience.');
    expect(reviewTextError('x', 'y'), isNull);
    expect(reviewSubmitError(_complete()..title = ''),
        'Please complete all required fields and ratings before submitting.');
  });

  test('URL is apiBase/reviews/{id}; non-numeric id throws FormatException',
      () {
    expect(reviewSubmitUri('77').toString(),
        '${ApiConfig.apiBase}/reviews/77');
    expect(reviewSubmitUri('77').toString(), isNot(contains('/api/')));
    expect(() => reviewSubmitUri('abc'), throwsFormatException);
    expect(() => reviewSubmitUri(''), throwsFormatException);
  });

  test('form fields match the web FormData (blank optionals are "")', () {
    expect(_complete().toFormFields(), {
      'would_recommend': 'yes',
      'rating_quality': '5',
      'rating_responsiveness': '4',
      'rating_professionalism': '3',
      'rating_value': '2',
      'rating_flexibility': '1',
      'title': 'Amazing',
      'comment': 'Loved it',
      'happywedz_helped': 'yes',
      'guest_count': '',
      'spent': '',
    });
  });

  test('postReview sends multipart even without photos', () async {
    late http.Request sent;
    final client = MockClient((req) async {
      sent = req;
      return http.Response('{"success":true}', 201);
    });
    final data = _complete()
      ..guestCount = '250'
      ..amountSpent = '150000';
    final result = await postReview(
        client: client, serviceId: '77', data: data, token: 'tkn');

    expect(result.ok, isTrue);
    expect(result.message, 'Review submitted successfully!');
    expect(sent.method, 'POST');
    expect(sent.url.toString(), '${ApiConfig.apiBase}/reviews/77');
    expect(sent.headers['Authorization'], 'Bearer tkn');
    expect(sent.headers['content-type'], startsWith('multipart/form-data'));
    final body = sent.body;
    for (final f in [
      'rating_quality',
      'rating_responsiveness',
      'rating_professionalism',
      'rating_value',
      'rating_flexibility',
      'would_recommend',
      'happywedz_helped',
      'guest_count',
      'spent',
    ]) {
      expect(body, contains('name="$f"'), reason: f);
    }
    expect(body, contains('250'));
    expect(body, isNot(contains('name="vendor_id"')));
  });

  test('postReview surfaces server message, else "Failed to submit."',
      () async {
    final withMsg = MockClient(
        (_) async => http.Response('{"message":"Already reviewed"}', 400));
    final r1 = await postReview(
        client: withMsg, serviceId: '1', data: _complete(), token: 't');
    expect(r1.ok, isFalse);
    expect(r1.message, 'Already reviewed');

    final noMsg = MockClient((_) async => http.Response('oops', 500));
    final r2 = await postReview(
        client: noMsg, serviceId: '1', data: _complete(), token: 't');
    expect(r2.message, 'Failed to submit.');
  });

  group('widgets', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        UserPrefs.isLoggedInKey: true,
        UserPrefs.userIdKey: 42,
        UserPrefs.userNameKey: 'Asha',
        UserPrefs.tokenKey: 'jwt-token',
        UserPrefs.tokenSavedAtKey: DateTime.now().toIso8601String(),
      });
      await AuthSession.instance.refresh();
    });

    Future<void> pump(WidgetTester tester, Widget page,
        {List<Object?>? pops}) async {
      tester.view.physicalSize = const Size(414, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        navigatorKey: rootNavigatorKey,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => page));
                  pops?.add(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('rate step shows web labels and blocks with web copy',
        (tester) async {
      await pump(
        tester,
        RateExperienceScreen(
          reviewData: ReviewData.simple(
              wouldRecommend: 'yes', happywedzHelped: 'yes'),
          vendorId: '77',
          vendorName: 'DW',
        ),
      );
      for (final l in [
        'Quality',
        'Responsiveness',
        'Professionalism',
        'Value',
        'Flexibility'
      ]) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
      expect(find.text('Communication'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('review_rate_next')));
      await tester.pump();
      expect(
          find.text(
              'Please select a star rating for: Quality, Responsiveness, Professionalism, Value, Flexibility'),
          findsOneWidget);
      expect(find.byType(WriteReviewScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey('star_rating_quality_5')));
      await tester.tap(
          find.byKey(const ValueKey('star_rating_responsiveness_4')));
      await tester.tap(
          find.byKey(const ValueKey('star_rating_professionalism_3')));
      await tester.tap(find.byKey(const ValueKey('star_rating_value_2')));
      await tester.tap(find.byKey(const ValueKey('star_rating_flexibility_1')));
      await tester.tap(find.byKey(const ValueKey('review_rate_next')));
      await tester.pumpAndSettle();
      expect(find.byType(WriteReviewScreen), findsOneWidget);
    });

    testWidgets('write step validates title then comment', (tester) async {
      await pump(
        tester,
        WriteReviewScreen(reviewData: _complete(), vendorId: '77'),
      );
      await tester.tap(find.byKey(const ValueKey('review_write_next')));
      await tester.pump();
      expect(find.text('Please provide a title for your review.'),
          findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('review_title')), 'T');
      await tester.tap(find.byKey(const ValueKey('review_write_next')));
      await tester.pump();
      expect(find.text('Please write a comment about your experience.'),
          findsOneWidget);
    });

    testWidgets('submit success pops back with true', (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((req) async {
        requests.add(req);
        return http.Response('{"success":true}', 201);
      });
      final pops = <Object?>[];
      await pump(
        tester,
        AdditionalDetailsScreen(
            reviewData: _complete(), vendorId: '77', httpClient: client),
        pops: pops,
      );
      await tester.tap(find.byKey(const ValueKey('review_submit')));
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      expect(requests.single.url.toString(),
          '${ApiConfig.apiBase}/reviews/77');
      expect(requests.single.headers['Authorization'], 'Bearer jwt-token');
      expect(find.text('Review submitted successfully!'), findsOneWidget);
      expect(pops, [true]);
    });

    testWidgets('full flow closes every step and returns true to the opener',
        (tester) async {
      final pops = <Object?>[];
      await pump(
        tester,
        const RecommendVendorScreen(vendorId: '77', vendorName: 'DW'),
        pops: pops,
      );
      expect(find.text('Would you recommend this vendor?'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      for (final k in [
        'star_rating_quality_5',
        'star_rating_responsiveness_4',
        'star_rating_professionalism_3',
        'star_rating_value_2',
        'star_rating_flexibility_1',
      ]) {
        await tester.tap(find.byKey(ValueKey(k)));
      }
      await tester.tap(find.byKey(const ValueKey('review_rate_next')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('review_title')), 'T');
      await tester.enterText(
          find.byKey(const ValueKey('review_comment')), 'Great');
      await tester.tap(find.byKey(const ValueKey('review_write_next')));
      await tester.pumpAndSettle();
      // The real submit is covered above; here only the pop chain matters.
      final additional = find.byType(AdditionalDetailsScreen);
      expect(additional, findsOneWidget);
      Navigator.of(tester.element(additional)).pop(true);
      await tester.pumpAndSettle();
      expect(find.byType(RecommendVendorScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(pops, [true]);
    });

    testWidgets('non-numeric id shows an error instead of crashing',
        (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((req) async {
        requests.add(req);
        return http.Response('{}', 201);
      });
      final pops = <Object?>[];
      await pump(
        tester,
        AdditionalDetailsScreen(
            reviewData: _complete(), vendorId: 'abc', httpClient: client),
        pops: pops,
      );
      await tester.tap(find.byKey(const ValueKey('review_submit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(kReviewBadVendorMessage), findsOneWidget);
      expect(requests, isEmpty);
      expect(pops, isEmpty);
    });
  });
}
