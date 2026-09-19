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

import 'package:happy_wedz/honeymoon/data/flight_filters.dart';
import 'package:happy_wedz/honeymoon/data/flight_search_store.dart';
import 'package:happy_wedz/honeymoon/data/honeymoon_api.dart';
import 'package:happy_wedz/honeymoon/data/traveller_store.dart';
import 'package:happy_wedz/honeymoon/honeymoon_config.dart';
import 'package:happy_wedz/honeymoon/insurance_config.dart';
import 'package:happy_wedz/honeymoon/models/insurance_models.dart';
import 'package:happy_wedz/honeymoon/models/booking_models.dart';
import 'package:happy_wedz/honeymoon/models/cab_models.dart';
import 'package:happy_wedz/honeymoon/data/cab_draft_store.dart';
import 'package:happy_wedz/honeymoon/models/flight_models.dart';
import 'package:happy_wedz/honeymoon/models/honeymoon_models.dart';
import 'package:happy_wedz/honeymoon/ui/widgets/flight_ticket.dart';

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

/// Answers a flight search by which half of the web's direct + connecting
/// pair it is: [direct] for `isDirectFlight: true`, [connecting] otherwise.
/// A null body answers that half with a 500.
MockClient flightSearchPair({
  Object? direct,
  Object? connecting,
  List<http.Request>? sink,
}) {
  return MockClient((request) async {
    sink?.add(request);
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final isDirect =
        body['searchQuery']?['searchModifiers']?['isDirectFlight'] == true;
    final answer = isDirect ? direct : connecting;
    return http.Response(
      answer == null ? 'down' : jsonEncode(answer),
      answer == null ? 500 : 200,
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

    test(
      'the traveller is told to retry, not shown Cloudflare prose',
      () async {
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
      },
    );

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

    const emptySearch = {
      'searchResult': {'tripInfos': <String, dynamic>{}},
    };

    test('a round trip comes back as two separate legs', () async {
      final api = HoneymoonApi(
        client: flightSearchPair(
          direct: {
            'searchResult': {
              'tripInfos': {
                'ONWARD': [trip('BOM', 'DEL', 'p1')],
                'RETURN': [trip('DEL', 'BOM', 'p2')],
              },
            },
          },
          connecting: emptySearch,
        ),
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
        client: flightSearchPair(
          direct: {
            'searchResult': {
              'tripInfos': {
                'ONWARD': [trip('BOM', 'DEL', 'p1')],
              },
            },
          },
          connecting: emptySearch,
        ),
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
        client: flightSearchPair(
          direct: {
            'searchResult': {
              'tripInfos': {
                'ONWARD': [trip('BOM', 'DEL', 'p1')],
              },
            },
          },
          connecting: emptySearch,
        ),
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
        DateTime.parse(
          '2030-01-01T10:00:00.000',
        ).add(const Duration(seconds: 840)),
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

    test(
      'a response with no bookingId is refused, not carried forward',
      () async {
        // Without this the funnel would proceed to payment with no session.
        final api = HoneymoonApi(client: respondWith({'conditions': {}}));
        await expectLater(
          api.reviewFlight(['p1']),
          throwsA(isA<HoneymoonApiException>()),
        );
      },
    );
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

      await api.createFlightPaymentOrder(bookingPayload(), isHoldConfirm: true);

      expect(jsonDecode(sent.single.body)['is_hold_confirm'], isTrue);
    });

    test('a hold sends the amount but no offer_id', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {'status': true, 'held_booking_id': 'HOLD1'}),
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
        client: respondWith({
          'message': 'Missing offer_id/provider/amount',
        }, status: 400),
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
              'message':
                  'All Segments Must be selected if Special Return fare.',
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

  group('Hotel detail sends the payload the backend actually requires', () {
    // Confirmed live: the endpoint rejected the old {hotelId, searchId,
    // optionId} payload with 400 { error: "searchQuery.checkInDate is
    // required" }. This pins the fields it needs so the regression can't
    // silently come back.
    test('includes a searchQuery with checkInDate', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(client: capturing(sent, {'ok': true}));

      await api.fetchHotelDetail(
        hotel: const HotelResult(
          id: 'H1',
          name: 'Goa Resort',
          optionId: 'OPT1',
          price: 4500,
        ),
        query: HotelSearchQuery(
          destination: const HoneymoonDestination(
            id: 'D1',
            displayName: 'Goa',
            city: 'Goa',
            searchRegionName: 'Goa',
            searchRegionType: 'CITY',
          ),
          checkIn: DateTime(2026, 12, 10),
          checkOut: DateTime(2026, 12, 15),
          rooms: [RoomOccupancy(adults: 2)],
        ),
        searchId: 'S1',
      );

      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      final searchQuery = body['searchQuery'] as Map<String, dynamic>;
      expect(searchQuery['checkInDate'], '2026-12-10');
      expect(searchQuery['checkoutDate'], '2026-12-15');
      expect(searchQuery['roomInfo'], isNotEmpty);
      expect(searchQuery['searchPreferences'], {
        'hids': ['H1'],
      });
      expect(body['searchId'], 'S1');
      expect(body['userIntent'], containsPair('optionId', 'OPT1'));
    });
  });

  group('Auth header', () {
    test('is attached when a token is stored', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'payload': {'suggestions': []},
        }),
      );

      await api.searchFlightLocations('Goa');
      expect(sent.single.headers['Authorization'], 'Bearer jwt-123');
    });

    test('is omitted when there is none, so public reads still work', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'payload': {'suggestions': []},
        }),
      );

      await api.searchFlightLocations('Goa');
      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'insurance is called unauthenticated, matching the web client',
      () async {
        SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
        final sent = <http.Request>[];
        final api = HoneymoonApi(
          client: capturing(sent, {
            'status': true,
            'data': {'bid': 'B1'},
          }),
        );

        await api.reviewInsurancePlan(const InsurancePlanStub().plan);

        expect(sent.single.headers.containsKey('Authorization'), isFalse);
      },
    );
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

  group('Flight search runs direct and connecting, like the web', () {
    Map<String, dynamic> trip(String priceId, {int stops = 0}) => {
      'sI': [
        for (var i = 0; i <= stops; i++)
          {
            'id': 'seg$i',
            'da': {'code': i == 0 ? 'BOM' : 'HYD'},
            'aa': {'code': i == stops ? 'DEL' : 'HYD'},
            'dt': '2030-01-01T0${i + 6}:00',
            'at': '2030-01-01T0${i + 7}:00',
            'duration': 60,
            if (i < stops) 'cT': 45,
            'fD': {
              'aI': {'code': '6E', 'name': 'IndiGo'},
              'fN': '10$i',
            },
          },
      ],
      'totalPriceList': [
        {
          'id': priceId,
          'fareIdentifier': 'PUBLISHED',
          'fd': {
            'ADULT': {
              'fC': {'TF': 5000},
            },
          },
        },
      ],
    };

    Map<String, dynamic> onward(List<Map<String, dynamic>> trips) => {
      'searchResult': {
        'tripInfos': {'ONWARD': trips},
      },
    };

    test(
      'sends one direct and one connecting search and merges them',
      () async {
        final sent = <http.Request>[];
        final api = HoneymoonApi(
          client: flightSearchPair(
            direct: onward([trip('direct')]),
            connecting: onward([trip('via', stops: 1)]),
            sink: sent,
          ),
        );

        final results = await api.searchFlights(
          fromCode: 'BOM',
          toCode: 'DEL',
          departure: DateTime(2030, 1, 1),
          adults: 1,
        );

        expect(sent, hasLength(2));
        final modifiers = [
          for (final r in sent)
            (jsonDecode(r.body) as Map)['searchQuery']['searchModifiers'],
        ];
        // Sent in parallel, so they may arrive in either order.
        expect(
          modifiers,
          unorderedEquals([
            {'isDirectFlight': true, 'isConnectingFlight': false},
            {'isDirectFlight': false, 'isConnectingFlight': true},
          ]),
        );
        // Listed direct first, then connecting, whichever answered first.
        expect(results.onward.map((f) => f.id), ['direct', 'via']);
      },
    );

    test('non-stop only sends a single direct search', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: flightSearchPair(direct: onward([trip('direct')]), sink: sent),
      );

      await api.searchFlights(
        fromCode: 'BOM',
        toCode: 'DEL',
        departure: DateTime(2030, 1, 1),
        directOnly: true,
      );

      expect(sent, hasLength(1));
      final modifiers =
          (jsonDecode(sent.single.body)
              as Map)['searchQuery']['searchModifiers'];
      expect(modifiers, {'isDirectFlight': true, 'isConnectingFlight': false});
    });

    test('one half failing still shows what the other found', () async {
      final api = HoneymoonApi(
        client: flightSearchPair(connecting: onward([trip('via', stops: 1)])),
      );

      final results = await api.searchFlights(
        fromCode: 'BOM',
        toCode: 'DEL',
        departure: DateTime(2030, 1, 1),
      );
      expect(results.onward.single.id, 'via');
    });

    test('both halves failing is an error', () async {
      final api = HoneymoonApi(client: flightSearchPair());
      await expectLater(
        api.searchFlights(
          fromCode: 'BOM',
          toCode: 'DEL',
          departure: DateTime(2030, 1, 1),
        ),
        throwsA(isA<HoneymoonApiException>()),
      );
    });

    test('duration includes the connection time, as the web counts it', () {
      final flight = FlightResult.fromTripJack(trip('via', stops: 1));
      // Two 60-minute hops plus a 45-minute connection.
      expect(flight.durationMinutes, 165);
      expect(tripDuration(flight.raw), 165);
    });

    test('multi-city sends pax counts as numbers', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(client: capturing(sent, {'searchResult': {}}));
      const bom = FlightLocation(code: 'BOM', name: 'Mumbai');
      const del = FlightLocation(code: 'DEL', name: 'Delhi');
      const goi = FlightLocation(code: 'GOI', name: 'Goa');

      await api.searchMultiCityFlights(
        legs: [
          FlightLeg(from: bom, to: del, date: DateTime(2030, 1, 1)),
          FlightLeg(from: del, to: goi, date: DateTime(2030, 1, 5)),
        ],
        adults: 2,
        infants: 1,
      );

      final paxInfo =
          (jsonDecode(sent.single.body) as Map)['searchQuery']['paxInfo'];
      expect(paxInfo, {'ADULT': 2, 'CHILD': 0, 'INFANT': 1});
    });
  });

  group('Flight review failures', () {
    test(
      'status.success false carries the supplier reason and payload',
      () async {
        final api = HoneymoonApi(
          client: respondWith({
            'status': {'success': false},
            'errors': [
              {
                'errCode': '1000',
                'message': 'Requested flight is no longer available',
              },
            ],
          }),
        );

        try {
          await api.reviewFlight(['p1']);
          fail('expected a HoneymoonApiException');
        } on HoneymoonApiException catch (e) {
          expect(e.message, 'Requested flight is no longer available');
          expect(isStaleFarePayload(e.data), isTrue);
        }
      },
    );

    test('a gone fare as a non-2xx is recognised as stale too', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'errors': [
            {'errCode': 1000, 'message': 'x'},
          ],
        }, status: 400),
      );
      try {
        await api.reviewFlight(['p1']);
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(isStaleFarePayload(e.data), isTrue);
      }
    });

    test('an unrelated refusal is not treated as stale', () {
      expect(
        isStaleFarePayload({
          'errors': [
            {'errCode': '2001', 'message': 'Invalid passenger name'},
          ],
        }),
        isFalse,
      );
    });
  });

  group('Fare choice on a results card', () {
    final raw = {
      'sI': [
        {
          'da': {'code': 'BOM'},
          'aa': {'code': 'DEL'},
          'dt': '2030-01-01T09:00',
          'at': '2030-01-01T11:00',
          'duration': 120,
          'fD': {
            'aI': {'code': 'AI', 'name': 'Air India'},
            'fN': '805',
          },
        },
      ],
      'totalPriceList': [
        {
          'id': 'saver',
          'fareIdentifier': 'PUBLISHED',
          'fd': {
            'ADULT': {
              'fC': {'TF': 5000},
              'rT': 0,
            },
          },
        },
        {
          'id': 'flex',
          'fareIdentifier': 'FLEXI',
          'fd': {
            'ADULT': {
              'fC': {'TF': 7000},
              'rT': 1,
              'bI': {'iB': '25 Kilograms', 'cB': '7 Kg'},
              'mI': true,
            },
          },
        },
      ],
    };

    test('the picked fare becomes the priceId and price', () {
      final flight = FlightResult.fromTripJack(raw);
      expect(flight.id, 'saver');

      final flex = flight.withSelectedFare('flex');
      expect(flex.id, 'flex');
      expect(flex.price, 7000);
      expect(flex.selectedFare['id'], 'flex');
      expect(flex.tripKey, flight.tripKey);
      expect(fareIsRefundable(flex.selectedFare), isTrue);
      expect(fareCheckinBaggage(flex.selectedFare), '25 Kilograms');
      expect(fareMealIncluded(flex.selectedFare), isTrue);
    });

    test('an unknown fare id leaves the trip as it was', () {
      final flight = FlightResult.fromTripJack(raw);
      expect(flight.withSelectedFare('gone').id, 'saver');
    });

    test('fare labels follow the web', () {
      expect(fareDisplayLabel(''), 'Published');
      expect(fareDisplayLabel('SME'), 'SME');
      expect(fareDisplayLabel('NDC_Economy Flex'), 'NDC Economy Flex');
      expect(fareDisplayLabel('SPECIAL_RETURN'), 'Special Return');
    });
  });

  group('Return Special', () {
    Map<String, dynamic> trip(String from, String to, List<Map> fares) => {
      'sI': [
        {
          'da': {'code': from},
          'aa': {'code': to},
          'dt': '2030-01-01T09:00',
          'at': '2030-01-01T11:00',
          'duration': 120,
          'fD': {
            'aI': {'code': '6E', 'name': 'IndiGo'},
            'fN': '1',
          },
        },
      ],
      'totalPriceList': fares,
    };

    Map<String, dynamic> fare(
      String id,
      double tf, {
      String? sri,
      List? msri,
    }) => {
      'id': id,
      'fareIdentifier': 'SPECIAL_RETURN',
      'sri': ?sri,
      'msri': ?msri,
      'fd': {
        'ADULT': {
          'fC': {'TF': tf},
        },
      },
    };

    test('pairs onward and return fares on sri / msri', () {
      final onward = [
        FlightResult.fromTripJack(
          trip('BOM', 'DEL', [
            fare('o1', 3000, msri: ['r-a']),
          ]),
        ),
      ];
      final inbound = [
        FlightResult.fromTripJack(
          trip('DEL', 'BOM', [
            fare('r1', 2500, sri: 'r-a'),
            fare('r2', 1000, sri: 'r-b'), // cheaper but not a valid match
          ]),
        ),
      ];

      final options = deriveSpecialReturn(onward, inbound);
      expect(options, hasLength(1));
      expect(options.single.code, '6E');
      expect(options.single.outFareId, 'o1');
      expect(options.single.returnFareId, 'r1');
      expect(options.single.price, 5500);
    });

    test('the filter keeps only that airline special fares', () {
      final mixed = FlightResult.fromTripJack(
        trip('BOM', 'DEL', [
          {
            'id': 'pub',
            'fareIdentifier': 'PUBLISHED',
            'fd': {
              'ADULT': {
                'fC': {'TF': 4000},
              },
            },
          },
          fare('sr', 3500, msri: ['x']),
        ]),
      );
      final out = filterFlights([
        mixed,
      ], const FlightFilters(specialReturn: {'6E'}));
      expect(out.single.fares.map((f) => f['id']), ['sr']);
      expect(
        filterFlights([mixed], const FlightFilters(specialReturn: {'AI'})),
        isEmpty,
      );
    });
  });

  group('Fare rules', () {
    test('parses bands and free text per route', () {
      final rules = FareRuleSet.fromJson({
        'fareRule': {
          'BOM-DEL': {
            'tfr': {
              'CANCELLATION': [
                {
                  'st': 4,
                  'et': 8760,
                  'amount': 3500,
                  'additionalFee': 300,
                  'policyInfo': 'Line one__nls__Line two',
                },
              ],
            },
            'miscInfo': ['Refund subject to airline __b__approval'],
          },
        },
      });

      expect(rules.routes.single.key, 'BOM-DEL');
      final slab = rules.slabsOf('CANCELLATION').single;
      expect(slab.timeFrame, '4 hrs to 365 days');
      expect(slab.amount, 3500);
      expect(slab.policyLines, ['Line one', 'Line two']);
      expect(rules.windowOf('CANCELLATION'), '4 hrs to 365 days');
      expect(
        rules.miscMatching('refund'),
        'Refund subject to airline approval',
      );
    });

    test('fetchFareRules posts id and flowType', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(client: capturing(sent, {'fareRule': {}}));
      final rules = await api.fetchFareRules('p1', 'SEARCH');
      expect(rules.isEmpty, isTrue);
      expect(sent.single.url.path, endsWith('/tj/fms/farerule'));
      expect(jsonDecode(sent.single.body), {'id': 'p1', 'flowType': 'SEARCH'});
    });
  });

  group('Recent flight searches', () {
    FlightSearchQuery query(String to, DateTime date) => FlightSearchQuery(
      tripType: FlightTripKind.oneWay,
      from: const FlightLocation(code: 'BOM', name: 'Mumbai'),
      to: FlightLocation(code: to, name: to),
      departure: date,
      adults: 2,
      cabinClass: 'PREMIUM_ECONOMY',
      paxType: 'STUDENT',
      preferredAirlines: const ['6E'],
    );

    test('round-trips through storage', () async {
      final day = DateTime(2030, 3, 4);
      await FlightSearchStore.saveRecent(query('DEL', day));
      final restored = (await FlightSearchStore.loadRecent()).single;

      expect(restored.from?.name, 'Mumbai');
      expect(restored.to?.code, 'DEL');
      expect(restored.departure, day);
      expect(restored.adults, 2);
      expect(restored.cabinClass, 'PREMIUM_ECONOMY');
      expect(restored.paxType, 'STUDENT');
      expect(restored.preferredAirlines, ['6E']);
    });

    test('keeps six, newest first, without duplicates', () async {
      for (var i = 1; i <= 7; i++) {
        await FlightSearchStore.saveRecent(query('C$i', DateTime(2030, 1, i)));
      }
      await FlightSearchStore.saveRecent(query('C5', DateTime(2030, 1, 5)));

      final recent = await FlightSearchStore.loadRecent();
      expect(recent.map((q) => q.to?.code), [
        'C5',
        'C7',
        'C6',
        'C4',
        'C3',
        'C2',
      ]);
    });

    test('multi-city searches are not remembered', () async {
      await FlightSearchStore.saveRecent(
        const FlightSearchQuery(tripType: FlightTripKind.multiCity),
      );
      expect(await FlightSearchStore.loadRecent(), isEmpty);
    });
  });

  group('Booking step: fare conditions and traveller payload', () {
    test('ffas lists the frequent-flyer airlines', () {
      final c = FareConditions.fromJson({
        'ffas': ['6E', 'AI'],
      });
      expect(c.frequentFlyerAirlines, ['6E', 'AI']);
      expect(FareConditions.fromJson({}).frequentFlyerAirlines, isEmpty);
    });

    test('frequent flyer rides on travellerInfo only when a number is set', () {
      final t = TravellerInput(type: PaxType.adult)
        ..firstName = 'Asha'
        ..lastName = 'Rao'
        ..frequentFlyerAirline = '6E';
      final without = t.toJson(passportRequired: false, docIdApplicable: false);
      expect(without.containsKey('fFNumber'), isFalse);

      t.frequentFlyerNumber = 'ab123';
      final withNumber = t.toJson(
        passportRequired: false,
        docIdApplicable: false,
      );
      expect(withNumber['fFNumber'], 'AB123');
      expect(withNumber['fFAirline'], '6E');
    });

    test('a student or senior search always asks for a document id', () {
      const conditions = FareConditions();
      final regular = FlightTripContext(
        from: const FlightLocation(code: 'BOM', name: 'Mumbai'),
        to: const FlightLocation(code: 'DEL', name: 'Delhi'),
        departure: DateTime(2030, 1, 1),
      );
      final student = FlightTripContext(
        from: const FlightLocation(code: 'BOM', name: 'Mumbai'),
        to: const FlightLocation(code: 'DEL', name: 'Delhi'),
        departure: DateTime(2030, 1, 1),
        paxType: 'STUDENT',
      );
      expect(regular.docIdApplicable(conditions), isFalse);
      expect(student.docIdApplicable(conditions), isTrue);
      expect(
        regular.docIdApplicable(const FareConditions(docIdApplicable: true)),
        isTrue,
      );
    });

    test('traveller key matches the web rule', () {
      expect(
        travellerKey(' asha ', 'rao', '1990-01-02'),
        'ASHA|RAO|1990-01-02',
      );
    });

    test('hidden travellers persist', () async {
      await TravellerSuppressionStore.save({'ASHA|RAO|1990-01-02'});
      expect(await TravellerSuppressionStore.load(), {'ASHA|RAO|1990-01-02'});
    });
  });

  group('Fare summary', () {
    final fare = {
      'fd': {
        'ADULT': {
          'fC': {'BF': 3000, 'TAF': 1000, 'TF': 4000},
          'afC': {
            'TAF': {'YQ': 600, 'OT': 400},
          },
        },
        'CHILD': {
          'fC': {'BF': 2000, 'TAF': 500, 'TF': 2500},
          'afC': {
            'TAF': {'YQ': 300, 'OT': 200},
          },
        },
      },
    };

    test('taxes are broken down by component across passengers', () {
      final b = FareBreakdown.forFlight(
        fares: [fare],
        paxCounts: {PaxType.adult: 2, PaxType.child: 1, PaxType.infant: 0},
      );
      final taxes = b.lines.firstWhere((l) => l.label == 'Taxes & fees');
      expect(taxes.amount, 2500);
      expect(
        {for (final p in taxes.parts) p.label: p.amount},
        {'Fuel surcharge (YQ)': 1500, 'Other taxes': 1000},
      );
      expect(b.total, 10500);
    });

    test('add-ons are one "Meal, Baggage & Seat" line with its parts', () {
      final b = FareBreakdown.forFlight(
        fares: [fare],
        paxCounts: {PaxType.adult: 1, PaxType.child: 0, PaxType.infant: 0},
        addOns: {'Seat': 350, 'Meal': 200},
      );
      final extras = b.lines.firstWhere(
        (l) => l.label == 'Meal, Baggage & Seat',
      );
      expect(extras.amount, 550);
      expect(extras.parts.map((p) => p.label), ['Meal', 'Seat']);
      expect(b.total, 4550);
    });
  });

  group('Block (hold) and payment', () {
    Map<String, dynamic> payload() => {
      'provider': 'tripjack',
      'offer_id': 'TJS1',
      'price': 4000.0,
      'booking_payload': {'bookingId': 'TJS1'},
    };

    test('a hold is only done when status is truthy', () async {
      final api = HoneymoonApi(
        client: respondWith({'held_booking_id': 'H1', 'message': 'nope'}),
      );
      try {
        await api.holdFlight(payload());
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'nope');
      }
    });

    test('a successful hold is on hold, unpaid, with the held id', () async {
      final api = HoneymoonApi(
        client: respondWith({'status': true, 'held_booking_id': 'H1'}),
      );
      final outcome = await api.holdFlight(payload());
      expect(outcome.onHold, isTrue);
      expect(outcome.reference, 'H1');
      expect(outcome.amountPaid, 0);
    });

    test('create order surfaces the endpoint own message', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'message': 'Fare changed, please review again',
        }, status: 400),
      );
      try {
        await api.createFlightPaymentOrder(payload());
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'Fare changed, please review again');
      }
    });
  });

  group('My Trips flight rows', () {
    test('read the fields my-bookings actually sends', () {
      final b = TravelBooking.fromFlightRow({
        'order_id': 'TJ1',
        'from_iata': 'BOM',
        'to_iata': 'DEL',
        'airline': 'IndiGo',
        'flight_no': '6E-123',
        'cabin_class': 'ECONOMY',
        'departure': '2030-01-01T09:00',
        'booked_at': '2029-12-01T10:00:00',
        'booking_status': 'on_hold',
        'price': 5400.5,
        'amount_paid': 0,
        'adults': 2,
        'children': 1,
        'passenger_name': 'Asha Rao',
      });
      expect(b.title, 'BOM → DEL');
      expect(b.subtitle, 'IndiGo · 6E-123 · ECONOMY');
      expect(b.amount, 5400.5);
      expect(b.isOnHold, isTrue);
      expect(b.bookedOn, DateTime(2029, 12, 1, 10));
      expect(b.travellerSummary, 'Asha Rao · 2 Adults · 1 Child');
    });

    test('status follows the web dashboard vocabulary', () {
      expect(flightStatusOf('on_hold').key, FlightStatusKey.hold);
      expect(flightStatusOf('ON_HOLD').label, 'Seat Held');
      expect(flightStatusOf('SUCCESS').key, FlightStatusKey.confirmed);
      expect(flightStatusOf('cancelled').key, FlightStatusKey.cancelled);
      expect(flightStatusOf('').key, FlightStatusKey.pending);
      expect(flightStatusOf('WEIRD_STATE').label, 'Weird State');
    });
  });

  group('Booking details', () {
    Map<String, dynamic> body({
      String status = 'SUCCESS',
      Map<String, String>? pnr,
      Object? tripInfos,
    }) => {
      'order': {
        'bookingId': 'TJ1',
        'status': status,
        'amount': 9000,
        'deliveryInfo': {
          'emails': ['a@b.com'],
          'contacts': ['919999999999'],
        },
      },
      'itemInfos': {
        'AIR': {
          'tripInfos':
              tripInfos ??
              [
                {
                  'sI': [
                    {
                      'id': 's1',
                      'da': {'code': 'BOM'},
                      'aa': {'code': 'DEL'},
                    },
                  ],
                },
              ],
          'travellerInfos': [
            {
              'ti': 'Mr',
              'fN': 'Ravi',
              'lN': 'Rao',
              'pt': 'ADULT',
              'pnrDetails': ?pnr,
              'ticketNumberDetails': {'BOM-DEL': '0981234'},
              'fd': {
                'fC': {'TF': 4500},
              },
            },
          ],
        },
      },
    };

    test('adapts like the web: fare from travellers, PNR per route', () async {
      final api = HoneymoonApi(
        client: respondWith(body(pnr: {'BOM-DEL': 'Y8CGHW'})),
      );
      final d = await api.fetchFlightBooking('TJ1');
      expect(d.bookingId, 'TJ1');
      expect(d.trips, hasLength(1));
      expect(d.travellers.single.pnrs, {'BOM-DEL': 'Y8CGHW'});
      expect(d.travellers.single.ticketNumbers['BOM-DEL'], '0981234');
      expect(d.fare?['fd']['ADULT']['fC']['TF'], 4500);
      expect(d.emails, ['a@b.com']);
      expect(d.isAwaitingPnr, isFalse);
    });

    test('PENDING or no PNR keeps the confirmation waiting', () {
      expect(
        FlightBookingDetails(body(status: 'PENDING')).isAwaitingPnr,
        isTrue,
      );
      expect(FlightBookingDetails(body()).isAwaitingPnr, isTrue);
    });

    test('an ONWARD/RETURN map of trips is flattened', () {
      final d = FlightBookingDetails(
        body(
          tripInfos: {
            'ONWARD': [
              {'sI': []},
            ],
            'RETURN': [
              {'sI': []},
            ],
          },
        ),
      );
      expect(d.trips, hasLength(2));
    });

    test(
      'a data envelope is unwrapped only when the root has nothing',
      () async {
        final api = HoneymoonApi(client: respondWith({'data': body()}));
        final d = await api.fetchFlightBooking('TJ1');
        expect(d.bookingId, 'TJ1');
      },
    );
  });

  group('Cancellation and amendments', () {
    test(
      'cancel sends reason, trips and charges; reads the amendment',
      () async {
        final sent = <http.Request>[];
        final api = HoneymoonApi(
          client: capturing(sent, {
            'status': true,
            'amendment_id': 'AM1',
            'amendment_status': 'REQUESTED',
          }),
        );
        final result = await api.cancelFlightBooking(
          'TJ1',
          remarks: 'Void this booking, process full refund',
          trips: [
            {
              'src': 'BOM',
              'dest': 'DEL',
              'departureDate': '2030-01-01',
              'travellers': [
                {'fn': 'Ravi', 'ln': 'Rao'},
              ],
            },
          ],
          charges: {'available': false},
        );
        final json = jsonDecode(sent.single.body) as Map<String, dynamic>;
        expect(json['provider'], 'tripjack');
        expect(json['order_id'], 'TJ1');
        expect(json['remarks'], 'Void this booking, process full refund');
        expect(json['skipCharges'], isTrue);
        expect((json['trips'] as List).single['src'], 'BOM');
        expect(result['amendment_id'], 'AM1');
      },
    );

    test('a cancel reply without status true is a refusal', () async {
      final api = HoneymoonApi(
        client: respondWith({'status': false, 'message': 'Not allowed'}),
      );
      try {
        await api.cancelFlightBooking('TJ1', remarks: 'x');
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'Not allowed');
      }
    });

    test('the cancel quote reads the web keys', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'available': true,
          'amendment_charges': 3500,
          'refund_amount': 1200,
          'total_fare': 4700,
        }),
      );
      final q = await api.fetchFlightCancelQuote('TJ1');
      expect(q.amendmentCharges, 3500);
      expect(q.refundAmount, 1200);
      expect(q.totalFare, 4700);
      expect(q.amendmentInProgress, isFalse);
      expect(
        const FlightCancelQuote({'err_code': '2512'}).amendmentInProgress,
        isTrue,
      );
    });

    test('amendment poll', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'amendmentId': 'AM1',
          'amendmentStatus': 'SUCCESS',
          'refundableAmount': 1200,
        }),
      );
      final a = await api.pollFlightAmendment('AM1');
      expect(jsonDecode(sent.single.body), {'amendmentId': 'AM1'});
      expect(a.status, 'SUCCESS');
      expect(a.refundableAmount, 1200);
    });

    test('release and email refuse on status false', () async {
      final api = HoneymoonApi(
        client: respondWith({'status': false, 'message': 'Too late'}),
      );
      await expectLater(
        api.releaseHeldFlight('TJ1'),
        throwsA(isA<HoneymoonApiException>()),
      );
      await expectLater(
        api.emailFlightTicket('TJ1'),
        throwsA(isA<HoneymoonApiException>()),
      );
    });
  });

  group('Ticket PDF', () {
    test('builds with every option on', () async {
      final data = FlightTicketData(
        bookingId: 'TJ1',
        legs: [
          (
            trip: {
              'sI': [
                {
                  'id': 's1',
                  'da': {'code': 'BOM', 'city': 'Mumbai', 'name': 'CSMIA'},
                  'aa': {'code': 'DEL', 'city': 'Delhi', 'name': 'IGI'},
                  'dt': '2030-01-01T09:00',
                  'at': '2030-01-01T11:00',
                  'duration': 120,
                  'fD': {
                    'aI': {'code': '6E', 'name': 'IndiGo'},
                    'fN': '123',
                  },
                },
              ],
            },
            fare: {
              'fareIdentifier': 'PUBLISHED',
              'fd': {
                'ADULT': {
                  'cc': 'ECONOMY',
                  'rT': 1,
                  'fC': {'BF': 3000, 'TF': 4000},
                  'afC': {
                    'TAF': {'YQ': 700, 'MF': 200, 'MFT': 100},
                  },
                  'bI': {'iB': '15 Kg', 'cB': '7 Kg'},
                },
              },
            },
          ),
        ],
        passengers: const [
          (
            title: 'Mr',
            firstName: 'Ravi',
            lastName: 'Rao',
            paxType: 'ADULT',
            dob: '1990-02-01',
            passport: 'Z123',
            frequentFlyer: '',
          ),
        ],
        paxInfos: const [
          BookedTraveller({
            'fN': 'Ravi',
            'lN': 'Rao',
            'pnrDetails': {'BOM-DEL': 'Y8CGHW'},
          }),
        ],
        contactEmail: 'a@b.com',
        gstNumber: '27ABCDE1234F1Z5',
        gstCompany: 'Acme',
        agentNote: 'Window seat',
      );
      expect(data.pnrs.single.code, 'Y8CGHW');
      final bytes = await buildFlightTicketPdf(
        data,
        const TicketPrintOptions(agentNotes: true),
      );
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('Flight static data matches the web', () {
    test('fare type notes are the web text', () {
      expect(FareType.seniorCitizen.note, contains('above the age of 61'));
      expect(FareType.student.note, contains('above 12 years of age'));
      expect(FareType.regular.note, isNull);
    });

    test('passenger limits', () {
      expect(FlightPaxLimits.maxTotal, 9);
      expect(FlightPaxLimits.defaultAdults, 1);
    });

    test('preferred airlines are the web list of 20', () {
      expect(kPreferredAirlines, hasLength(20));
      expect(kPreferredAirlines.first.code, '6E');
      expect(kPreferredAirlines.last.code, 'FZ');
    });
  });

  group('Trips too close together (errCode 1019)', () {
    // The answer from a live multi-city review.
    const refused = {
      'status': {'success': false, 'httpStatus': 400},
      'errors': [
        {
          'errCode': '1019',
          'message':
              'Minimum time between two consecutive trips does not satisfy '
              'the criteria.',
          'details': ' You can use booking Id TJS104103024688 for reference',
          'id': 'TJS104103024688',
        },
      ],
    };

    test('is recognised, and is not mistaken for a stale fare', () async {
      final api = HoneymoonApi(client: respondWith(refused, status: 400));
      try {
        await api.reviewFlight(['a', 'b']);
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(isTripGapError(e.data), isTrue);
        expect(isStaleFarePayload(e.data), isFalse);
      }
    });

    FlightResult trip(String from, String to, String dt, String at) =>
        FlightResult.fromTripJack({
          'sI': [
            {
              'da': {'code': from},
              'aa': {'code': to},
              'dt': dt,
              'at': at,
              'duration': 60,
              'fD': {
                'aI': {'code': 'AI'},
                'fN': '1',
              },
            },
          ],
          'totalPriceList': [
            {'id': 'p'},
          ],
        });

    test('a flight leaving before the previous one lands is blocked', () {
      final first = trip('BOM', 'PNQ', '2030-01-01T09:00', '2030-01-01T14:30');
      final early = trip('PNQ', 'BLR', '2030-01-01T13:00', '2030-01-01T14:00');
      final later = trip('PNQ', 'BLR', '2030-01-01T18:00', '2030-01-01T19:30');
      expect(tripOverlapReason(first, early), contains('PNQ 14:30'));
      expect(tripOverlapReason(first, later), isNull);
    });

    test('different airports are not compared', () {
      final first = trip('BOM', 'DEL', '2030-01-01T09:00', '2030-01-01T14:30');
      final openJaw = trip(
        'PNQ',
        'BLR',
        '2030-01-01T10:00',
        '2030-01-01T11:00',
      );
      expect(tripOverlapReason(first, openJaw), isNull);
    });
  });

  group('Flight payment order amount', () {
    Map<String, dynamic> payload(double price) => {
      'provider': 'tripjack',
      'offer_id': 'TJS1',
      'price': price,
      'booking_payload': {'bookingId': 'TJS1'},
    };

    test('a rupee answer is converted to paise for Razorpay', () async {
      // The live answer: the amount it was sent, in rupees.
      final api = HoneymoonApi(
        client: respondWith({
          'razorpay_order_id': 'order_1',
          'key_id': 'rzp_test_x',
          'amount': 56338,
          'currency': 'INR',
        }),
      );
      final order = await api.createFlightPaymentOrder(payload(56338.0));
      expect(order.amountInPaise, 5633800);
    });

    test('paise with a fraction of a rupee is kept exact', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'razorpay_order_id': 'order_1',
          'key_id': 'rzp_test_x',
          'amount': 6835.52,
        }),
      );
      final order = await api.createFlightPaymentOrder(payload(6835.52));
      expect(order.amountInPaise, 683552);
    });

    test('an answer already in paise is left alone', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'razorpay_order_id': 'order_1',
          'key_id': 'rzp_test_x',
          'amount': 5633800,
        }),
      );
      final order = await api.createFlightPaymentOrder(payload(56338.0));
      expect(order.amountInPaise, 5633800);
    });
  });

  group('Seat map', () {
    test(
      'a 1056 refusal shows the supplier message, not a load failure',
      () async {
        final api = HoneymoonApi(
          client: respondWith({
            'status': {'success': false, 'httpStatus': 400},
            'errors': [
              {
                'errCode': '1056',
                'message': 'Seat Selection Not Applicable for this Itinerary',
              },
            ],
          }, status: 400),
        );
        final result = await api.fetchSeatMap('TJS116403024922');
        expect(
          result.error,
          'Seat Selection Not Applicable for this Itinerary',
        );
      },
    );

    test('a server failure without errors keeps the generic line', () async {
      final api = HoneymoonApi(client: respondWith('oops', status: 500));
      final result = await api.fetchSeatMap('TJS1');
      expect(result.error, 'Could not load the seat map.');
    });
  });

  group('Insurance search payloads match the web', () {
    final start = DateTime(2030, 3, 10);
    const france = InsuranceDestination(rkey: 'FR', label: 'France');

    test('international', () {
      final q = InsuranceSearchQuery(
        planType: InsurancePlanType.international,
        destination: france,
        start: start,
        end: DateTime(2030, 3, 12),
        ages: const [30, 28],
      );
      expect(q.toPayload(), {
        'isq': {
          'sd': '2030-03-10',
          'ed': '2030-03-12',
          'isc': {
            'iri': [
              {'rkey': 'FR', 'rt': 'COUNTRY'},
            ],
          },
          'iti': [
            {'age': 30},
            {'age': 28},
          ],
          'isp': <String, dynamic>{},
        },
      });
      expect(q.isEmbedded, isFalse);
    });

    test('international embedded in a flight booking', () {
      final q = InsuranceSearchQuery(
        planType: InsurancePlanType.international,
        destination: france,
        start: start,
        end: start,
        ages: const [30],
        flightBookingId: ' TGS123 ',
      );
      final p = q.toPayload();
      expect(q.isEmbedded, isTrue);
      expect(p['ict'], 'API_EMB');
      expect(p['isq']['isef'], isTrue);
      expect(p['isq']['bid'], 'TGS123');
    });

    test('student sends cd and ict inside isq, no ed', () {
      final p = InsuranceSearchQuery(
        planType: InsurancePlanType.student,
        destination: france,
        start: start,
        end: start.add(const Duration(days: 180)),
        ages: const [22],
        coverageDays: 180,
      ).toPayload();
      expect(p['isq']['cd'], '180');
      expect(p['isq']['ict'], 'STUDENT');
      expect(p['isq']['isef'], isFalse);
      expect((p['isq'] as Map).containsKey('ed'), isFalse);
      expect(p.containsKey('ict'), isFalse);
    });

    test('annual multi trip sends adr and ict at the top', () {
      final p = InsuranceSearchQuery(
        planType: InsurancePlanType.annualMultiTrip,
        destination: kAmtDestinations[1],
        start: start,
        end: start.add(const Duration(days: 180)),
        ages: const [30],
        amtTripDays: 45,
      ).toPayload();
      expect(p['ict'], 'AMT');
      expect(p['isq']['adr'], 45);
      expect(p['isq']['isc']['iri'], [
        {'rkey': 'WWXUSCA', 'rt': 'POPULARREGION'},
      ]);
    });

    test('policy window stays inside the live TripJack 180-day rule', () {
      // Verified live: sd + 179 is accepted, sd + 180 is refused.
      expect(InsuranceLimits.maxPolicyWindowDays, 179);
      expect(InsuranceLimits.amtMaxWindowDays, 179);
    });

    test('destinations are the web keys, not invented ones', () {
      expect(kInsurancePopularRegions.map((r) => r.rkey), [
        'ASI',
        'EUR',
        'SCH',
        'WW',
      ]);
      expect(kInsuranceCountries, hasLength(250));
      expect(
        kInsuranceCountries.firstWhere((c) => c.label == 'United States').rkey,
        'US',
      );
    });
  });

  group('Insurance API', () {
    Map<String, dynamic> product(String pid, double tf) => {
      'pid': pid,
      'pi': 'Gold',
      'pn': 'USD 50,000',
      'ip': 'ABHI',
      'aps': ['BRB Assist'],
      'pfd': {
        'ppd': {
          'ppdf': {
            '1': [
              {
                'ifc': {'TF': tf, 'SP': 100, 'SPGST': 18},
              },
            ],
            '2': [
              {
                'ifc': {'TF': tf, 'SP': 100, 'SPGST': 18},
              },
            ],
          },
        },
      },
    };

    test(
      'search uses the embedded endpoint and keeps supplier order',
      () async {
        final sent = <http.Request>[];
        final api = HoneymoonApi(
          client: capturing(sent, {
            'status': true,
            'data': {
              'isq': {
                'iti': [
                  {'age': 30},
                  {'age': 30},
                ],
              },
              'isr': {
                'iinfo': {
                  'pli': [
                    {
                      'plid': 'PL1',
                      'pi': [product('B', 900), product('A', 500)],
                    },
                  ],
                },
              },
            },
          }),
        );
        final plans = await api.searchInsurance(
          InsuranceSearchQuery(
            planType: InsurancePlanType.international,
            destination: const InsuranceDestination(
              rkey: 'FR',
              label: 'France',
            ),
            start: DateTime(2030, 1, 1),
            end: DateTime(2030, 1, 3),
            ages: const [30, 30],
            flightBookingId: 'TGS1',
          ),
        );
        expect(sent.single.url.path, endsWith('/tripsafe/search/embedded'));
        expect(sent.single.headers.containsKey('Authorization'), isFalse);
        expect(plans.map((p) => p.productId), ['B', 'A']);
        // Every ppdf key agrees → per traveller × 2.
        expect(plans.first.price, 1800);
        expect(plans.first.breakdown.serviceFee, 200);
        expect(plans.first.assistancePartner, 'BRB Assist');
      },
    );

    test(
      'a TripJack failure inside a 200 is an error, not "no plans"',
      () async {
        final api = HoneymoonApi(
          client: respondWith({
            'status': true,
            'data': {
              'status': {'success': false, 'httpStatus': 400},
            },
          }),
        );
        try {
          await api.searchInsurance(
            InsuranceSearchQuery(
              planType: InsurancePlanType.international,
              destination: const InsuranceDestination(rkey: 'FR', label: 'F'),
              start: DateTime(2030, 1, 1),
              end: DateTime(2030, 1, 1),
              ages: const [30],
            ),
          );
          fail('expected a HoneymoonApiException');
        } on HoneymoonApiException catch (e) {
          expect(e.message, 'TripJack error: 400');
        }
      },
    );

    test('review reads the price from iinfo.pli for the whole party', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'status': true,
          'data': {
            'bid': 'TJINS1',
            'iinfo': {
              'pli': [
                {
                  'plid': 'PL1',
                  'pi': [product('A', 650)],
                },
              ],
            },
          },
        }),
      );
      const plan = InsurancePlan(
        planId: 'PL1',
        productId: 'A',
        name: 'Gold',
        price: 1000,
        travellerCount: 2,
      );
      final review = await api.reviewInsurancePlan(plan);
      expect(review.bookingId, 'TJINS1');
      expect(review.price, 1300);
    });

    test('booking details map like the web', () {
      final d = InsuranceBookingDetails.fromJson({
        'order': {
          'bookingId': 'TJINS1',
          'status': 'SUCCESS',
          'amount': 1300.5,
          'deliveryInfo': {
            'emails': ['a@b.com'],
            'contacts': ['9999999999'],
          },
        },
        'itemInfos': {
          'INSURANCE': {
            'isq': {'sd': '2030-01-01', 'ed': '2030-01-03'},
            'iinfo': {
              'pli': [
                {
                  'plid': 'PL1',
                  'pi': [
                    {
                      'pid': 'A',
                      'pi': 'Gold',
                      'ip': 'ABHI',
                      'iti': [
                        {
                          'id': 1,
                          'fn': 'Asha',
                          'ln': 'Rao',
                          'gen': 'F',
                          'policyId': 'POL9',
                          'ni': [
                            {'nn': 'Ravi', 'nr': 'SPOUSE'},
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        },
      });
      expect(d.isSuccess, isTrue);
      expect(d.canCancel, isTrue);
      expect(d.amount, 1300.5);
      expect(d.insurerLabel, 'Aditya Birla Health Insurance');
      expect(d.travellers.single.gender, 'Female');
      expect(d.travellers.single.policyId, 'POL9');
      expect(d.travellers.single.nominee, 'Ravi');
      expect(d.startDate, DateTime(2030, 1, 1));
    });

    test('My Trips rows are keyed by tripjack_booking_id', () {
      final b = TravelBooking.fromInsuranceRow({
        'id': 7,
        'tripjack_booking_id': 'TJINS1',
        'plan_label': 'Gold',
        'coverage_amount': 'USD 50,000',
        'region_name': 'Europe',
        'traveller_count': 2,
        'booking_status': 'SUCCESS',
        'amount': 1300,
        'start_date': '2030-01-01',
      });
      expect(b.reference, 'TJINS1');
      expect(b.title, 'Gold');
      expect(b.subtitle, 'USD 50,000 · Europe');
      expect(b.travellerSummary, '2 travellers');
    });

    test('status labels follow the web dashboard', () {
      expect(insuranceStatusOf('SUCCESS').label, 'Policy Issued');
      expect(insuranceStatusOf('CONFIRMED').label, 'Confirmed');
      expect(
        insuranceStatusOf('payment_pending').key,
        InsuranceStatusKey.pending,
      );
      expect(insuranceStatusOf('CANCELLED').key, InsuranceStatusKey.cancelled);
    });
  });

  group('Car rental search matches the web', () {
    final origin = {
      'type': 'location',
      'displayAddress': 'Mumbai Airport',
      'lat': '19.09',
      'long': '72.86',
      'address': {'city': 'Mumbai', 'country': 'India', 'postalCode': '400099'},
    };
    final destination = {
      'type': 'location',
      'displayAddress': 'Pune',
      'lat': '18.52',
      'long': '73.85',
      'address': {'city': 'Pune', 'country': 'India', 'postalCode': '411001'},
    };

    test('airport transfer, one way: no returnDate, no luggageCount', () {
      final p = CabSearchQuery(
        journeyType: CabJourneyType.airportTransfer,
        origin: origin,
        destination: destination,
        pickupAt: DateTime(2030, 3, 10, 9, 5),
        passengers: 2,
        bags: 3,
      ).toPayload();
      expect(p, {
        'pickupDate': '2030-03-10 09:05',
        'origin': origin,
        'destination': destination,
        'journeyType': 'airport_transfer',
        'tripType': 'oneway',
        'passengers': 2,
        'quoteFilter': {'paxCount': 2},
      });
    });

    test('outstation with a return is a round trip carrying luggage', () {
      final p = CabSearchQuery(
        journeyType: CabJourneyType.outstation,
        origin: origin,
        destination: destination,
        pickupAt: DateTime(2030, 3, 10, 9),
        returnAt: DateTime(2030, 3, 12, 18),
        passengers: 4,
        bags: 0,
      ).toPayload();
      expect(p['tripType'], 'roundtrip');
      expect(p['returnDate'], '2030-03-12 18:00');
      expect(p['journeyType'], 'outstation');
      // `Number(luggage) || 1`: zero bags still sends 1.
      expect(p['quoteFilter'], {'paxCount': 4, 'luggageCount': 1});
    });

    test('local keeps the same shape', () {
      final p = CabSearchQuery(
        journeyType: CabJourneyType.local,
        origin: origin,
        destination: destination,
        pickupAt: DateTime(2030, 3, 10, 9),
      ).toPayload();
      expect(p['journeyType'], 'local');
      expect(p['passengers'], 1);
    });

    test('timing rules and their messages', () {
      final now = DateTime(2030, 3, 10, 10);
      expect(
        cabPickupProblem(DateTime(2030, 3, 10, 11, 59), now: now),
        'Pickup time must be at least 2 hours from now',
      );
      expect(cabPickupProblem(DateTime(2030, 3, 10, 12), now: now), isNull);
      final pickup = DateTime(2030, 3, 10, 12);
      expect(
        cabReturnProblem(pickup, DateTime(2030, 3, 10, 12, 29)),
        'Return time must be atleast 30 minutes after pickup time',
      );
      expect(cabReturnProblem(pickup, DateTime(2030, 3, 10, 12, 30)), isNull);
      expect(
        cabReturnProblem(null, pickup),
        'Select a pickup date and time first',
      );
    });

    test('the field reads like the portal', () {
      expect(
        formatCabDateTime(DateTime(2026, 8, 29, 0, 0)),
        "Sat, 29 Aug'26, 12:00 AM",
      );
      expect(
        formatCabDateTime(DateTime(2026, 8, 30, 21, 5)),
        "Sun, 30 Aug'26, 09:05 PM",
      );
    });

    test('a parked booking survives a round trip through storage', () {
      final draft = CabBookingDraft(
        query: CabSearchQuery(
          journeyType: CabJourneyType.outstation,
          origin: origin,
          destination: destination,
          pickupAt: DateTime(2030, 3, 10, 9),
          returnAt: DateTime(2030, 3, 11, 9),
          passengers: 3,
          bags: 2,
        ),
        quoteIdentity: 'SEDAN|ECONOMY|Sedan|V1',
        firstName: 'Asha',
        savedAt: DateTime(2030, 3, 1),
      );
      final back = CabBookingDraft.fromJson(
        jsonDecode(jsonEncode(draft.toJson())),
      )!;
      expect(back.query.toPayload(), draft.query.toPayload());
      expect(back.quoteIdentity, 'SEDAN|ECONOMY|Sedan|V1');
      expect(back.firstName, 'Asha');
    });
  });

  group('Car rental API', () {
    test('location search starts at two characters', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'status': true,
          'data': {
            'places': [
              {
                'id': 'p1',
                'name': 'Mumbai Airport',
                'displayLabel': 'Mumbai Airport, MH',
              },
            ],
          },
        }),
      );
      expect(await api.searchCabLocations('M'), isEmpty);
      expect(sent, isEmpty);
      final places = await api.searchCabLocations('Mu');
      expect(sent.single.url.path, endsWith('/tripjack-cabs/search-locations'));
      expect(jsonDecode(sent.single.body), {'input': 'Mu'});
      expect(places.single['id'], 'p1');
    });

    test(
      'a status:false location answer is an error, not "no places"',
      () async {
        final api = HoneymoonApi(
          client: respondWith({
            'status': false,
            'message': 'Request failed with status code 404',
          }),
        );
        expect(
          () => api.searchCabLocations('Mumbai'),
          throwsA(isA<HoneymoonApiException>()),
        );
      },
    );

    test('the location node carries subLocality only when present', () {
      final withSub = HoneymoonApi.buildCabLocationNode(
        displayAddress: 'T2',
        details: {
          'location': {'lat': 19.1, 'lng': 72.8},
          'address': {'subLocality': 'Andheri', 'city': 'Mumbai'},
        },
      );
      expect(withSub['lat'], '19.1');
      expect(withSub['long'], '72.8');
      expect((withSub['address'] as Map)['subLocality'], 'Andheri');
      final without = HoneymoonApi.buildCabLocationNode(
        displayAddress: 'T2',
        details: {
          'location': {'lat': 19.1, 'lng': 72.8},
          'address': {'city': 'Mumbai'},
        },
      );
      expect((without['address'] as Map).containsKey('subLocality'), isFalse);
    });

    test(
      'quotes post the query and cheapest first, unpriced dropped',
      () async {
        final sent = <http.Request>[];
        final api = HoneymoonApi(
          client: capturing(sent, {
            'success': true,
            'data': {
              'journeyInfo': {
                'journeyType': 'AIRPORT_TRANSFER',
                'tripType': 'oneway',
              },
              'routeDetails': {
                'origin': {'city': 'Mumbai'},
              },
              'quotesInfo': [
                {
                  'vehicleType': 'SEDAN',
                  'vehicleCategory': 'ECONOMY',
                  'label': 'Sedan',
                  'similarType': 'Dzire or similar',
                  'vehicleImages': ['https://x/sedan.png'],
                  'quotes': [
                    {
                      'vendorId': 'V2',
                      'quotationId': 'Q2',
                      'quoteChildId': 'C2',
                      'fareBreakup': {'totalFare': 900, 'totalTax': 45},
                      'paxCount': 4,
                      'luggageCount': 2,
                    },
                    {
                      'vendorId': 'V3',
                      'quotationId': 'Q3',
                      'quoteChildId': 'C3',
                      'paxCount': 4,
                    },
                  ],
                },
                {
                  'vehicleType': 'SUV',
                  'label': 'SUV',
                  'paxCapacity': 6,
                  'luggageCapacity': 4,
                  'quotes': [
                    {
                      'vendorId': 'V1',
                      'quotationId': 'Q1',
                      'quoteChildId': 'C1',
                      'fareBreakup': {'totalFare': 1500, 'totalTax': 75},
                    },
                  ],
                },
              ],
            },
          }),
        );
        final query = CabSearchQuery(
          journeyType: CabJourneyType.airportTransfer,
          origin: const {'displayAddress': 'A'},
          destination: const {'displayAddress': 'B'},
          pickupAt: DateTime(2030, 1, 1, 9),
        );
        final result = await api.searchCabQuotes(query);
        expect(sent.single.url.path, endsWith('/tripjack-cabs/quotes'));
        expect(
          jsonDecode(sent.single.body),
          jsonDecode(jsonEncode(query.toPayload())),
        );
        // The unpriced quote (Q3) is dropped, not offered as a free cab.
        expect(result.quotes.map((q) => q.quotationId), ['Q2', 'Q1']);
        final sedan = result.quotes.first;
        expect(sedan.price, 945);
        expect(sedan.label, 'Sedan');
        expect(sedan.similarType, 'Dzire or similar');
        // No group capacity → the quote's own counts.
        expect(sedan.seats, 4);
        expect(sedan.luggage, 2);
        expect(result.quotes.last.seats, 6);
        expect(cabClassKey(sedan), 'SEDAN|ECONOMY|Sedan');
        expect(result.isAirportTransfer, isTrue);
      },
    );

    test('a supplier failure on quotes surfaces its own message', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'success': false,
          'message': 'Pickup time must be at least 2 hours from now',
        }),
      );
      try {
        await api.searchCabQuotes(
          CabSearchQuery(
            journeyType: CabJourneyType.local,
            origin: const {'displayAddress': 'A'},
            destination: const {'displayAddress': 'B'},
            pickupAt: DateTime(2030, 1, 1, 9),
          ),
        );
        fail('expected a HoneymoonApiException');
      } on HoneymoonApiException catch (e) {
        expect(e.message, 'Pickup time must be at least 2 hours from now');
      }
    });

    test('a rupee payment order is converted to paise', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'keyId': 'rzp_test',
          'razorpayOrderId': 'order_1',
          'amount': 945,
          'currency': 'INR',
        }),
      );
      final order = await api.createCabPaymentOrder(
        bookingId: 'B1',
        amount: 945,
        supplierAmount: 945,
      );
      expect(order.orderId, 'order_1');
      expect(order.amountInPaise, 94500);
    });

    test('a paise payment order is left alone', () async {
      final api = HoneymoonApi(
        client: respondWith({
          'keyId': 'rzp_test',
          'razorpayOrderId': 'order_1',
          'amount': 94500,
        }),
      );
      final order = await api.createCabPaymentOrder(
        bookingId: 'B1',
        amount: 945,
        supplierAmount: 945,
      );
      expect(order.amountInPaise, 94500);
    });

    final entry = {
      'order': {
        'bookingId': 'TJC1',
        'status': 'SUCCESS',
        'paymentStatus': 'SUCCESS',
        'rideStatus': 'DRIVER_ASSIGNED',
        'trackingLink': 'https://track/1',
        'helpline': 'Call 1800',
        'tripType': 'oneway',
      },
      'itemInfos': {
        'CAB': {
          'paxDetails': {'fullName': 'Asha Rao'},
          'vehicleDetail': {'clazz': 'Sedan'},
          'journeyInfo': {
            'source': 'Mumbai Airport',
            'destination': {'displayAddress': 'Pune'},
            'pickupDate': '2030-01-01T09:00:00',
            'distance': '150 km',
            'flightDetails': {'number': '6E 21'},
          },
          'pricing': {'grossAmount': 945},
        },
      },
    };

    test('booking details normalise like normalizeCabBookingDetail', () {
      final d = CabBookingDetail.fromEntry(entry);
      expect(d.bookingId, 'TJC1');
      expect(d.isPaid, isTrue);
      expect(d.rideStatus, 'DRIVER_ASSIGNED');
      expect(d.passengerName, 'Asha Rao');
      expect(d.vehicleClass, 'Sedan');
      expect(d.source, 'Mumbai Airport');
      expect(d.destination, 'Pune');
      expect(d.distance, '150 km');
      expect(d.flightNumber, '6E 21');
      expect(d.grossAmount, 945);
      expect(
        CabBookingDetail.fromVerify({
          'bookingDetails': [entry],
        })!.bookingId,
        'TJC1',
      );
      expect(CabBookingDetail.fromVerify({'status': true}), isNull);
    });

    test('check status reads booking/details by id', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'status': true,
          'data': [entry],
        }),
      );
      final list = await api.fetchCabBookingDetails(['TJC1']);
      expect(sent.single.url.path, endsWith('/tripjack-cabs/booking/details'));
      expect(sent.single.url.queryParameters['bookingIds'], 'TJC1');
      expect(list.single.isPaid, isTrue);
    });

    test('the dashboard detail is read by invoice id', () async {
      final sent = <http.Request>[];
      final api = HoneymoonApi(
        client: capturing(sent, {
          'status': true,
          'invoice': {
            'invoiceNumber': 'INV-7',
            'bookingId': 'TJC1',
            'orderId': 'order_1',
            'journey': {
              'pickupLocation': 'Mumbai Airport',
              'dropoffLocation': 'Pune',
              'pickupTime': '2030-01-01T09:00:00',
              'distance': '150 km',
            },
            'passenger': {'name': 'Asha', 'email': 'a@b.com', 'phone': '99'},
            'pricing': {'baseFare': 900, 'taxes': 45, 'total': 945},
            'booking': {'status': 'CONFIRMED'},
            'payment': {'status': 'SUCCESS'},
            'createdAt': '2029-12-01T10:00:00',
          },
        }),
      );
      final d = await api.fetchCabInvoiceDetail('7');
      expect(
        sent.single.url.path,
        endsWith('/tripjack-cabs/invoice/7/details'),
      );
      expect(d.displayId, 'INV-7');
      expect(d.orderId, 'order_1');
      expect(d.total, 945);
      expect(d.bookingStatus, 'CONFIRMED');
      expect(d.paymentStatus, 'SUCCESS');
    });

    test(
      'an invoice body without status + invoice is rejected like the web',
      () async {
        final api = HoneymoonApi(client: respondWith({'status': false}));
        try {
          await api.fetchCabInvoiceDetail('7');
          fail('expected a HoneymoonApiException');
        } on HoneymoonApiException catch (e) {
          expect(e.message, 'Invalid booking data received');
        }
      },
    );

    test('status labels follow the web dashboard', () {
      expect(cabStatusOf('SUCCESS').key, CabStatusKey.confirmed);
      expect(cabStatusOf('in_progress').key, CabStatusKey.pending);
      expect(cabStatusOf('CANCELED').key, CabStatusKey.cancelled);
      expect(cabStatusOf('PAYMENT_PENDING').label, 'Payment Pending');
      expect(cabStatusOf('PAYMENT_PENDING').key, CabStatusKey.unknown);
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
