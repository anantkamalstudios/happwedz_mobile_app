// Layout checks for the car-rental screens, at the phone widths the design
// has to survive and at the app's maximum text scale, with the longest
// addresses and labels the supplier realistically sends. An overflow is a
// FlutterError that `tester.takeException()` surfaces.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/honeymoon/data/honeymoon_api.dart';
import 'package:happy_wedz/honeymoon/models/cab_models.dart';
import 'package:happy_wedz/honeymoon/models/honeymoon_models.dart';
import 'package:happy_wedz/honeymoon/ui/booking/cab_booking_page.dart';
import 'package:happy_wedz/honeymoon/ui/booking/cab_confirmation_page.dart';
import 'package:happy_wedz/honeymoon/ui/bookings/cab_booking_detail_page.dart';
import 'package:happy_wedz/honeymoon/ui/cab_results_page.dart';

const List<double> _widths = [320, 360, 414];
const double _maxTextScale = 1.2;

const String _longFrom =
    'Chhatrapati Shivaji Maharaj International Airport Terminal 2, '
    'Andheri East, Mumbai, Maharashtra 400099, India';
const String _longTo =
    'The Westin Pune Koregaon Park, 36/3-B Koregaon Park Annex, '
    'Mundhwa Road, Ghorpadi, Pune, Maharashtra 411001, India';

Future<void> _pumpPhone(
  WidgetTester tester,
  Widget child, {
  required double width,
  double height = 780,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: const TextScaler.linear(_maxTextScale),
        ),
        child: child,
      ),
    ),
  );
  // Let the page's own load complete and the entry animations finish.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void _expectNoOverflow(WidgetTester tester, String where) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Layout error in $where: $error');
}

final Map<String, dynamic> _origin = {
  'type': 'location',
  'displayAddress': _longFrom,
  'lat': '19.09',
  'long': '72.86',
  'address': {'city': 'Mumbai', 'country': 'India', 'postalCode': '400099'},
};
final Map<String, dynamic> _destination = {
  'type': 'location',
  'displayAddress': _longTo,
  'lat': '18.52',
  'long': '73.85',
  'address': {'city': 'Pune', 'country': 'India', 'postalCode': '411001'},
};

CabSearchQuery _query({bool roundTrip = true}) => CabSearchQuery(
  journeyType: CabJourneyType.outstation,
  origin: _origin,
  destination: _destination,
  pickupAt: DateTime(2030, 12, 31, 23, 45),
  returnAt: roundTrip ? DateTime(2031, 1, 2, 18) : null,
  passengers: 10,
  bags: 10,
);

Map<String, dynamic> _quotesBody() => {
  'success': true,
  'data': {
    'journeyInfo': {
      'journeyType': 'AIRPORT_TRANSFER',
      'tripType': 'roundtrip',
      'distance': '1,234.5 km',
    },
    'routeDetails': {
      'origin': {'city': 'Mumbai', 'displayAddress': _longFrom},
      'destination': {'city': 'Pune', 'displayAddress': _longTo},
    },
    'quotesInfo': [
      {
        'vehicleType': 'PREMIUM_SUV_EXECUTIVE',
        'vehicleCategory': 'LUXURY',
        'label': 'Premium Executive SUV with Extra Luggage Space',
        'similarType':
            'Toyota Innova Crysta, Mahindra XUV700, Kia Carnival or similar',
        'paxCapacity': 7,
        'luggageCapacity': 10,
        'quotes': [
          for (final (id, fare) in [('Q1', 123456.0), ('Q2', 99999.0)])
            {
              'vendorId': 'V$id',
              'quotationId': id,
              'quoteChildId': 'C$id',
              'fareBreakup': {'totalFare': fare, 'totalTax': 6172.8},
              'model': 'Toyota Innova Crysta 2.8 ZX Automatic',
              'policies': {
                'inclusions': ['Driver allowance', 'Meet and greet'],
                'exclusions': ['Tolls', 'Parking'],
                'cancellationPolicy': [
                  {'minHours': 24, 'refundPercentage': 100},
                  {'minHours': 0, 'refundPercentage': 0},
                ],
                'waitingTime': '45 minutes free waiting at the airport',
              },
            },
        ],
      },
    ],
  },
};

HoneymoonApi _api() => HoneymoonApi(
  client: MockClient((request) async {
    final path = request.url.path;
    Object body = {'status': true};
    if (path.endsWith('/tripjack-cabs/quotes')) body = _quotesBody();
    if (path.endsWith('/details')) {
      body = {
        'status': true,
        'invoice': {
          'invoiceNumber': 'HW-CAB-2030-000000123456',
          'bookingId': 'TJC123456789012345',
          'orderId': 'order_ABCDEFGHIJKLMN',
          'journey': {
            'pickupLocation': _longFrom,
            'dropoffLocation': _longTo,
            'pickupTime': '2030-12-31T23:45:00',
            'distance': '1,234.5 km',
          },
          'passenger': {
            'name': 'Anantkamal Venkataraghavan Subramanian-Iyer',
            'email': 'a.very.long.email.address.for.testing@example-domain.com',
            'phone': '+91 98765 43210',
          },
          'pricing': {'baseFare': 123456, 'taxes': 6172.8, 'total': 129628.8},
          'booking': {'status': 'PAYMENT_PENDING'},
          'payment': {'status': 'SUCCESS'},
          'createdAt': '2030-12-01T10:00:00',
        },
      };
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
);

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'user_id': 42,
      'user_name': 'Anantkamal Venkataraghavan Subramanian-Iyer',
      'user_email': 'a.very.long.email.address.for.testing@example-domain.com',
      'user_phone': '+91 98765 43210',
    }),
  );

  for (final width in _widths) {
    testWidgets('search form fits at ${width.toInt()}px', (tester) async {
      await _pumpPhone(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CabSearchForm(api: _api(), initial: _query()),
          ),
        ),
        width: width,
      );
      expect(find.text('Airport Transfers'), findsOneWidget);
      expect(find.text('Search Cabs'), findsOneWidget);
      _expectNoOverflow(tester, 'CabSearchForm @ $width');
    });

    testWidgets('results and Compare fit at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpPhone(
        tester,
        CabResultsPage(api: _api(), query: _query()),
        width: width,
      );
      expect(find.text('Book Cab'), findsOneWidget);
      await tester.tap(find.text('Compare'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      _expectNoOverflow(tester, 'CabResultsPage @ $width');
    });

    testWidgets('review page fits at ${width.toInt()}px', (tester) async {
      final result = CabQuoteResult.fromJson(_quotesBody()['data']);
      await _pumpPhone(
        tester,
        CabBookingPage(
          api: _api(),
          quote: result.quotes.first,
          result: result,
          query: _query(),
        ),
        width: width,
      );
      expect(find.text('Pay Now'), findsOneWidget);
      expect(find.textContaining('Cab Booking | Round Trip'), findsOneWidget);
      // Scroll the whole form through the viewport.
      // Scroll through the whole page and let any bounce settle.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'CabBookingPage @ $width');
    });

    testWidgets('success page fits at ${width.toInt()}px', (tester) async {
      final result = CabQuoteResult.fromJson(_quotesBody()['data']);
      await _pumpPhone(
        tester,
        CabConfirmationPage(
          api: _api(),
          booking: const CabCreatedBooking(
            id: 'TJC123456789012345',
            totalPrice: 129628.8,
          ),
          detail: CabBookingDetail(
            bookingId: 'TJC123456789012345',
            status: 'SUCCESS',
            paymentStatus: 'SUCCESS',
            rideStatus: 'DRIVER_DETAILS_SHARED_WITH_CUSTOMER',
            trackingLink: 'https://example.com/track/1',
            helpline:
                'For any help call our 24x7 helpline on +91 1800 000 0000',
            passengerName: 'Anantkamal Venkataraghavan Subramanian-Iyer',
            vehicleClass: 'Premium Executive SUV with Extra Luggage Space',
            source: _longFrom,
            destination: _longTo,
            pickupDate: DateTime(2030, 12, 31, 23, 45),
            distance: '1,234.5 km',
            grossAmount: 129628.8,
          ),
          paymentRef: 'pay_ABCDEFGHIJKLMNOP',
          quote: result.quotes.first,
          query: _query(),
        ),
        width: width,
      );
      // Scroll through the whole page and let any bounce settle.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Track your ride'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Track your ride'), findsOneWidget);
      _expectNoOverflow(tester, 'CabConfirmationPage @ $width');
    });

    testWidgets('booking detail fits at ${width.toInt()}px', (tester) async {
      await _pumpPhone(
        tester,
        CabBookingDetailPage(
          api: _api(),
          invoiceId: '7',
          orderId: 'order_ABCDEFGHIJKLMN',
        ),
        width: width,
      );
      // Scroll through the whole page and let any bounce settle.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Download Invoice PDF'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Download Invoice PDF'), findsOneWidget);
      _expectNoOverflow(tester, 'CabBookingDetailPage @ $width');
    });
  }
}
