// API-layer tests for the Honeymoon module.
//
// These pin down three things that were found by running the app against the
// live backend, not by reading code:
//
//   1. `tj/meta/locations` answers in the supplier's own envelope
//      (`payload.suggestions`), unlike every other endpoint. Missing it made
//      the airport picker permanently empty, which made flight search
//      unreachable.
//   2. An upstream outage arrives as HTTP 200 with `status.success: false` —
//      a Cloudflare 502 page passed straight through. Read as data, that is
//      an empty list, so the UI said "no airports found" while the supplier
//      was down and the traveller retyped instead of retrying.
//   3. The supplier's own error prose is a Cloudflare support page, which is
//      no use to a traveller.
//
// `HoneymoonApi` takes an `http.Client`, so all of this is testable without a
// network.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/honeymoon/data/honeymoon_api.dart';
import 'package:happy_wedz/honeymoon/models/booking_models.dart';
import 'package:happy_wedz/honeymoon/models/honeymoon_models.dart';

/// A client that answers every request with [body] at [status].
MockClient respondWith(Object body, {int status = 200}) {
  return MockClient((request) async {
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

/// Captures the outgoing request so the payload can be asserted on.
MockClient capturing(List<http.Request> sink, Object body) {
  return MockClient((request) async {
    sink.add(request);
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Airport lookup reads the supplier envelope', () {
    test('finds the list under payload.suggestions', () async {
      // The exact shape the live endpoint returns.
      final api = HoneymoonApi(
        client: respondWith({
          'payload': {
            'suggestions': [
              {
                'country': 'India',
                'code': 'BOM',
                'city': 'Mumbai',
                'countryCode': 'IN',
                'name': 'Chhatrapati Shivaji',
              },
              {
                'country': 'India',
                'code': 'NMI',
                'city': 'Navi mumbai',
                'name': 'Navi mumbai international airport',
              },
            ],
            'status': {'success': true, 'httpStatus': 200},
          },
        }),
      );

      final results = await api.searchFlightLocations('Mumbai');

      expect(results, hasLength(2));
      expect(results.first.code, 'BOM');
      expect(results.first.name, 'Chhatrapati Shivaji');
      expect(results.first.subtitle, 'Mumbai, India');
    });

    test('still reads a plain data envelope', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'data': [
            {'code': 'DEL', 'name': 'Delhi Indira Gandhi Intl'},
          ],
        }),
      );
      final results = await api.searchFlightLocations('Delhi');
      expect(results.single.code, 'DEL');
    });

    test('a one-letter query never reaches the network', () async {
      var called = false;
      final api = HoneymoonApi(
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      expect(await api.searchFlightLocations('D'), isEmpty);
      expect(called, isFalse);
    });

    test('entries without a code are dropped, not shown blank', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'payload': {
            'suggestions': [
              {'name': 'Nowhere'},
              {'code': 'GOI', 'name': 'Goa'},
            ],
          },
        }),
      );
      final results = await api.searchFlightLocations('Goa');
      expect(results.single.code, 'GOI');
    });
  });

  group('An upstream outage is an error, not an empty result', () {
    // Trimmed from the real body the backend passed through during a
    // TripJack outage: HTTP 200, with the failure buried in `status.success`.
    final cloudflare502 = {
      'title': 'Error 502: Bad gateway',
      'status': {'success': false},
      'detail':
          'The origin web server returned an invalid or incomplete response '
          'to Cloudflare.',
      'error_code': 502,
      'cloudflare_error': true,
      'retryable': true,
    };

    test('airport lookup surfaces it instead of returning []', () async {
      final api = HoneymoonApi(client: respondWith(cloudflare502));

      await expectLater(
        api.searchFlightLocations('Delhi'),
        throwsA(isA<HoneymoonApiException>()),
      );
    });

    test('the traveller is told to retry, not shown Cloudflare prose', () async {
      final api = HoneymoonApi(client: respondWith(cloudflare502));

      try {
        await api.searchFlightLocations('Delhi');
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, contains('busy'));
        expect(e.message, contains('try again'));
        // None of the supplier's own wording leaks through.
        expect(e.message.toLowerCase(), isNot(contains('cloudflare')));
        expect(e.message.toLowerCase(), isNot(contains('origin')));
        expect(e.message, isNot(contains('502')));
      }
    });

    test('flight search surfaces it too', () async {
      final api = HoneymoonApi(client: respondWith(cloudflare502));

      await expectLater(
        api.searchFlights(
          fromCode: 'BOM',
          toCode: 'DEL',
          departure: DateTime(2030, 1, 1),
        ),
        throwsA(isA<HoneymoonApiException>()),
      );
    });

    test('the flat {status:false, message} shape keeps its message', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'status': false,
          'message': 'Invalid supplier credentials',
        }),
      );

      try {
        await api.searchFlightLocations('Delhi');
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'Invalid supplier credentials');
      }
    });

    test('a genuinely empty result is still empty, not an error', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'payload': {
            'suggestions': <dynamic>[],
            'status': {'success': true},
          },
        }),
      );
      expect(await api.searchFlightLocations('Zzzz'), isEmpty);
    });
  });

  group('Flight search keeps ONWARD and RETURN apart', () {
    Map<String, dynamic> trip(String from, String to, String priceId) => {
      'sI': [
        {
          'da': {'code': from},
          'aa': {'code': to},
          'dt': '2030-01-01T09:00',
          'at': '2030-01-01T11:00',
          'duration': 120,
          'fD': {
            'aI': {'code': '6E', 'name': 'IndiGo'},
            'fN': '5056',
          },
        },
      ],
      'totalPriceList': [
        {
          'id': priceId,
          'fd': {
            'ADULT': {
              'fC': {'TF': 4369.5, 'BF': 3150, 'NF': 4369.5},
            },
          },
        },
      ],
    };

    test('a round trip comes back as two separate legs', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'searchResult': {
            'tripInfos': {
              'ONWARD': [trip('BOM', 'DEL', 'p1')],
              'RETURN': [trip('DEL', 'BOM', 'p2')],
            },
          },
        }),
      );

      final results = await api.searchFlights(
        fromCode: 'BOM',
        toCode: 'DEL',
        departure: DateTime(2030, 1, 1),
        returnDate: DateTime(2030, 1, 8),
      );

      expect(results.hasSeparateReturn, isTrue);
      expect(results.onward.single.fromCode, 'BOM');
      expect(results.inbound.single.fromCode, 'DEL');
      // The priceId is what the review call needs; it must survive the parse.
      expect(results.onward.single.id, 'p1');
      expect(results.onward.single.price, 4369.5);
    });

    test('a one-way response has no return leg', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'searchResult': {
            'tripInfos': {
              'ONWARD': [trip('BOM', 'DEL', 'p1')],
            },
          },
        }),
      );

      final results = await api.searchFlights(
        fromCode: 'BOM',
        toCode: 'DEL',
        departure: DateTime(2030, 1, 1),
      );

      expect(results.hasSeparateReturn, isFalse);
      expect(results.onward, hasLength(1));
    });

    test('the raw trip is kept so a booking payload can be built', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'searchResult': {
            'tripInfos': {
              'ONWARD': [trip('BOM', 'DEL', 'p1')],
            },
          },
        }),
      );

      final flight = (await api.searchFlights(
        fromCode: 'BOM',
        toCode: 'DEL',
        departure: DateTime(2030, 1, 1),
      )).onward.single;

      expect(flight.segments, hasLength(1));
      expect(flight.selectedFare['id'], 'p1');
    });
  });

  group('Flight review', () {
    // The real response, trimmed. Everything the funnel branches on is here.
    final reviewBody = {
      'bookingId': 'TJS103102911743',
      'tripInfos': [
        {
          'totalPriceList': [
            {
              'id': 'p1',
              'fd': {
                'ADULT': {
                  'fC': {'TF': 4369.5, 'BF': 3150},
                },
              },
            },
          ],
        },
      ],
      'totalPriceInfo': {
        'totalFareDetail': {
          'fC': {'NF': 4369.5, 'BF': 3150, 'TF': 4369.5, 'TAF': 1219.5},
        },
      },
      'conditions': {
        'dob': {'adobr': true, 'cdobr': true, 'idobr': true},
        'iecr': false,
        'dc': {'ida': false, 'idm': false},
        'anlm': {'fN': 32, 'finml': 1, 'lN': 32, 'lnml': 1},
        'isBA': true,
        'st': 840,
        'sct': '2030-01-01T10:00:00.000',
      },
    };

    test('parses the session, the rules and the payable amount', () async {
      final api = HoneymoonApi(client: respondWith(reviewBody));
      final review = await api.reviewFlight(['p1']);

      expect(review.bookingId, 'TJS103102911743');
      expect(review.totalFare, 4369.5);
      // What `paymentInfos` must carry — the supplier rejects anything else.
      expect(review.supplierPayableAmount, 4369.5);

      final c = review.conditions;
      expect(c.blockAllowed, isTrue); // isBA → the Hold action is offered
      expect(c.passportRequired, isFalse); // no pcs → domestic
      expect(c.emergencyContactRequired, isFalse);
      expect(c.firstNameMax, 32); // the airline's real cap
      expect(c.sessionSeconds, 840);
      expect(
        c.expiresAt,
        DateTime.parse('2030-01-01T10:00:00.000').add(
          const Duration(seconds: 840),
        ),
      );
    });

    test('sends the priceIds the search returned', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(client: capturing(sent, reviewBody));

      await api.reviewFlight(['p1', 'p2']);

      expect(sent.single.url.path, endsWith('/tj/fms/review'));
      expect(jsonDecode(sent.single.body), {
        'priceIds': ['p1', 'p2'],
      });
    });

    test('an empty priceId list never reaches the network', () async {
      final api = HoneymoonApi(
        client: MockClient((_) async => fail('should not have been called')),
      );
      await expectLater(
        api.reviewFlight(const []),
        throwsA(isA<HoneymoonApiException>()),
      );
    });

    test('a response with no bookingId is refused, not carried forward', () async {
      // Without this the funnel would proceed to payment with no session.
      final api = HoneymoonApi(client: respondWith({'conditions': {}}));
      await expectLater(
        api.reviewFlight(['p1']),
        throwsA(isA<HoneymoonApiException>()),
      );
    });
  });

  group('Payment orders are sent in the endpoint own shape', () {
    // The endpoint reads `amount`; the caller describes a fare with `price`.
    // Passing the caller's shape straight through was rejected with
    // "Missing offer_id/provider/amount" and no order was ever created.
    Map<String, dynamic> bookingPayload() => {
      'provider': 'tripjack',
      'offer_id': 'TJS103102911743',
      'trip_type': 'round',
      'from': 'BOM',
      'to': 'DEL',
      'departure': '2030-01-01T20:45',
      'arrival': '2030-01-02T03:20',
      'flight_no': 'IX-1163',
      'airline': 'AI Express',
      'cabin_class': 'ECONOMY',
      'price': 14254.0,
      'passengers': [
        {'fN': 'Testone'},
      ],
      'contact': {'email': 'test@example.com', 'phone': '919999999999'},
      'booking_payload': {'bookingId': 'TJS103102911743'},
    };

    test('price is renamed to amount', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'razorpay_order_id': 'order_1',
          'key_id': 'rzp_test_1',
          'amount': 1425400,
        }),
      );

      await api.createFlightPaymentOrder(bookingPayload());

      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['amount'], 14254.0);
      expect(body.containsKey('price'), isFalse);
      expect(body['offer_id'], 'TJS103102911743');
      expect(body['provider'], 'tripjack');
      expect(body['is_hold_confirm'], isFalse);
      // The supplier payload has to survive intact.
      expect(body['booking_payload'], {'bookingId': 'TJS103102911743'});
    });

    test('paying for a held fare flags it as a hold confirmation', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'razorpay_order_id': 'order_1',
          'key_id': 'rzp_test_1',
        }),
      );

      await api.createFlightPaymentOrder(
        bookingPayload(),
        isHoldConfirm: true,
      );

      expect(jsonDecode(sent.single.body)['is_hold_confirm'], isTrue);
    });

    test('a hold sends the amount but no offer_id', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'status': true,
          'held_booking_id': 'HOLD1',
        }),
      );

      final outcome = await api.holdFlight(bookingPayload());

      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      expect(body['amount'], 14254.0);
      expect(body.containsKey('offer_id'), isFalse);
      expect(body.containsKey('is_hold_confirm'), isFalse);

      expect(outcome.onHold, isTrue);
      expect(outcome.reference, 'HOLD1');
    });

    test('the backend own reason is shown, not boilerplate', () async {
      final api = HoneymoonApi(
        client: respondWith(
          {'message': 'Missing offer_id/provider/amount'},
          status: 400,
        ),
      );

      try {
        await api.createFlightPaymentOrder(bookingPayload());
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'Missing offer_id/provider/amount');
      }
    });

    test('a supplier fare refusal keeps its errCode message', () async {
      // `{errors: [{errCode, message}]}` — the only place the reason appears.
      final api = HoneymoonApi(
        client: respondWith({
          'status': {'success': false, 'httpStatus': 400},
          'errors': [
            {
              'errCode': '1080',
              'message': 'All Segments Must be selected if Special Return fare.',
            },
          ],
        }, status: 400),
      );

      try {
        await api.reviewFlight(['p1', 'p2']);
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, contains('Special Return fare'));
      }
    });
  });

  group('Saved travellers never block a booking', () {
    test('a failure yields an empty list rather than throwing', () async {
      final api = HoneymoonApi(client: respondWith('nope', status: 500));
      expect(await api.fetchSavedTravellers(), isEmpty);
    });

    test('a 404 yields an empty list too', () async {
      final api = HoneymoonApi(client: respondWith({'x': 1}, status: 404));
      expect(await api.fetchSavedTravellers(), isEmpty);
    });
  });

  group('Auth header', () {
    test('is attached when a token is stored', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {'payload': {'suggestions': []}}),
      );

      await api.searchFlightLocations('Goa');
      expect(sent.single.headers['Authorization'], 'Bearer jwt-123');
    });

    test('is omitted when there is none, so public reads still work', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {'payload': {'suggestions': []}}),
      );

      await api.searchFlightLocations('Goa');
      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('insurance is called unauthenticated, matching the web client', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {'status': true, 'data': {'bid': 'B1'}}),
      );

      await api.reviewInsurancePlan(
        const InsurancePlanStub().plan,
      );

      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('HTTP failures are translated for a traveller', () {
    test('a 401 asks them to sign in', () async {
      final api = HoneymoonApi(client: respondWith({}, status: 401));
      try {
        await api.fetchFlightBookings();
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.isUnauthorized, isTrue);
        expect(e.message, contains('sign in'));
      }
    });

    test('a 500 blames the partner, not the traveller', () async {
      final api = HoneymoonApi(client: respondWith({}, status: 500));
      try {
        await api.fetchFlightBookings();
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, contains('busy'));
      }
    });

    test('a non-JSON body does not leak as a parse error', () async {
      final api = HoneymoonApi(client: respondWith('<html>oops</html>'));
      try {
        await api.fetchFlightBookings();
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, isNot(contains('<html>')));
      }
    });
  });
}

/// A minimal bookable plan, so the insurance auth test does not depend on
/// parsing a full search response.
class InsurancePlanStub {
  const InsurancePlanStub();

  InsurancePlan get plan => const InsurancePlan(
    planId: 'PL1',
    productId: 'PR1',
    name: 'Explorer Gold',
    price: 1200,
  );
}
