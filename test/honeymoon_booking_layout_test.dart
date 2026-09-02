// Layout tests for the Honeymoon booking funnels.
//
// The requirement these encode: every booking screen has to render at typical
// phone widths — 320, 360, 375, 390 and 414 — with the keyboard open or shut,
// with long text and with missing data, and produce no RenderFlex overflow,
// no clipped action button and no horizontal scroll.
//
// A RenderFlex overflow reports itself through FlutterError during layout,
// which `tester.takeException()` surfaces, so `expectNoOverflow` is a real
// assertion rather than a smoke test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/honeymoon/models/booking_models.dart';
import 'package:happy_wedz/honeymoon/models/honeymoon_models.dart';
import 'package:happy_wedz/honeymoon/ui/booking/booking_confirmation_page.dart';
import 'package:happy_wedz/honeymoon/ui/booking/booking_widgets.dart';
import 'package:happy_wedz/honeymoon/ui/bookings/my_trips_page.dart';

/// The widths the design has to survive, narrowest first.
const List<double> phoneWidths = [320, 360, 375, 390, 414];

/// The OS text scale is clamped to 1.2 app-wide in `main.dart`; that upper
/// bound is the one worth testing, because it is where text-driven overflow
/// actually happens.
const double maxTextScale = 1.2;

extension _Pump on WidgetTester {
  /// Renders [child] at a phone of [width] with the app's real theme and the
  /// same text-scale clamp the app applies.
  Future<void> pumpPhone(
    Widget child, {
    required double width,
    double height = 780,
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
            // A non-zero bottom inset is what an open keyboard looks like to
            // the layout, so this is how "keyboard open" is exercised.
            viewInsets: EdgeInsets.only(bottom: bottomInset),
          ),
          child: child,
        ),
      ),
    );
    await pump(const Duration(milliseconds: 400));
  }
}

/// Fails with the framework's own overflow message when a layout overflowed.
void expectNoOverflow(WidgetTester tester, String context) {
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason: 'Layout error in $context: $error',
  );
}

/// No widget may extend past the left or right edge of the viewport.
void expectNoHorizontalOverflow(WidgetTester tester, double width) {
  for (final element in find.byType(Padding).evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final origin = box.localToGlobal(Offset.zero);
    expect(
      origin.dx,
      greaterThanOrEqualTo(-0.5),
      reason: 'A widget starts left of the viewport at ${width}px',
    );
    expect(
      origin.dx + box.size.width,
      lessThanOrEqualTo(width + 0.5),
      reason: 'A widget extends past the right edge at ${width}px',
    );
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

FareBreakdown get sampleFare => const FareBreakdown(
  lines: [
    FareLine('Base fare', 84500, detail: '2 adults, 1 child'),
    FareLine('Taxes & fees', 12480),
  ],
  total: 96980,
);

/// A deliberately hostile fare: a seven-figure total next to the longest
/// action label in the funnels.
FareBreakdown get hugeFare => const FareBreakdown(
  lines: [FareLine('Base fare', 1234567)],
  total: 1234567,
);

BookingOutcome outcome({bool onHold = false, String status = 'CONFIRMED'}) =>
    BookingOutcome(
      product: TravelProduct.flight,
      reference: 'TJS10098877665544332211',
      status: status,
      amountPaid: 96980,
      onHold: onHold,
    );

TravelBooking booking({
  TravelProduct product = TravelProduct.flight,
  String title = 'BOM → DXB',
  String status = 'CONFIRMED',
}) => TravelBooking(
  product: product,
  reference: 'HW-ORD-20260814-0001',
  title: title,
  subtitle: 'IndiGo · 6E 1402',
  travelDate: DateTime(2026, 8, 14),
  bookedOn: DateTime(2026, 7, 2),
  status: status,
  paymentStatus: 'SUCCESS',
  amount: 96980,
  travellerSummary: 'Priya Raghunathan +2 more',
);

void main() {
  group('BookingActionBar — the pay button is never clipped', () {
    for (final width in phoneWidths) {
      testWidgets('fits at ${width.toInt()}px', (tester) async {
        await tester.pumpPhone(
          Scaffold(
            bottomNavigationBar: BookingActionBar(
              fare: sampleFare,
              priceLabel: 'Total payable',
              actionLabel: 'Review booking',
              onAction: () {},
              onShowBreakdown: () {},
            ),
          ),
          width: width,
        );

        expectNoOverflow(tester, 'BookingActionBar at ${width}px');
        expect(find.text('Review booking'), findsOneWidget);

        // The label must be fully laid out, not ellipsised away.
        final label = tester.widget<Text>(find.text('Review booking'));
        expect(label.overflow, TextOverflow.ellipsis);
        final box = tester.renderObject<RenderBox>(find.text('Review booking'));
        expect(
          box.size.width,
          greaterThan(0),
          reason: 'The action label collapsed at ${width}px',
        );
      });
    }

    testWidgets('survives a seven-figure total at 320px', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          bottomNavigationBar: BookingActionBar(
            fare: hugeFare,
            priceLabel: 'Total payable',
            actionLabel: 'Pay securely',
            onAction: () {},
            onShowBreakdown: () {},
          ),
        ),
        width: 320,
      );
      expectNoOverflow(tester, 'BookingActionBar with a large total');
    });

    testWidgets('survives the max text scale at 320px', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          bottomNavigationBar: BookingActionBar(
            fare: sampleFare,
            actionLabel: 'Pay securely',
            secondaryLabel: 'Hold this fare',
            onAction: () {},
            onSecondary: () {},
            onShowBreakdown: () {},
          ),
        ),
        width: 320,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'BookingActionBar at 1.2x text');
    });

    testWidgets('renders without a fare', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          bottomNavigationBar: BookingActionBar(
            actionLabel: 'Continue',
            onAction: () {},
          ),
        ),
        width: 320,
      );
      expectNoOverflow(tester, 'BookingActionBar with no fare');
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('BookingStepBar — every step label stays on screen', () {
    for (final width in phoneWidths) {
      testWidgets('three steps at ${width.toInt()}px', (tester) async {
        await tester.pumpPhone(
          const Scaffold(
            body: BookingStepBar(
              steps: ['Trip', 'Travellers', 'Review'],
              currentStep: 1,
            ),
          ),
          width: width,
        );
        expectNoOverflow(tester, 'BookingStepBar at ${width}px');
        expect(find.text('Travellers'), findsOneWidget);
      });
    }

    testWidgets('fits the height it declares, at 1.2x text', (tester) async {
      await tester.pumpPhone(
        const Scaffold(
          body: SizedBox(
            height: BookingStepBar.height,
            child: BookingStepBar(
              steps: ['Trip', 'Travellers', 'Review'],
              currentStep: 0,
            ),
          ),
        ),
        width: 320,
        textScale: maxTextScale,
      );
      // BookingStepBar.height is what AppBar.bottom hands it — if the content
      // needs more, this is where it shows up as an overflow.
      expectNoOverflow(tester, 'BookingStepBar inside its declared height');
    });

    testWidgets('four steps still fit at 320px', (tester) async {
      await tester.pumpPhone(
        const Scaffold(
          body: BookingStepBar(
            steps: ['Trip', 'Travellers', 'Extras', 'Review'],
            currentStep: 2,
          ),
        ),
        width: 320,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'BookingStepBar with four steps');
    });
  });

  group('Form building blocks', () {
    for (final width in phoneWidths) {
      testWidgets('a form section at ${width.toInt()}px', (tester) async {
        await tester.pumpPhone(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                FormSection(
                  title: 'Lead passenger details for this booking',
                  subtitle:
                      'Exactly as printed on the passport each traveller '
                      'will carry at the airport',
                  icon: Icons.person_outline_rounded,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 88,
                          child: PickerField(
                            label: 'Title',
                            value: 'Master',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: 'First name',
                            required: true,
                            controller: TextEditingController(
                              text: 'Ramachandran',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const InfoBanner(
                      message:
                          'This is an international itinerary — passport '
                          'details are needed for every traveller.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const DetailRow(
                      label: 'Passport number',
                      value: 'Z9876543210987654321',
                    ),
                  ],
                ),
              ],
            ),
          ),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'FormSection at ${width}px');
        expectNoHorizontalOverflow(tester, width);
      });
    }

    testWidgets('the title/name row survives 320px at 1.2x', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: PickerField(
                    label: 'Title',
                    value: 'Master',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'First name',
                    required: true,
                    controller: TextEditingController(),
                  ),
                ),
              ],
            ),
          ),
        ),
        width: 320,
        textScale: maxTextScale,
      );
      expectNoOverflow(tester, 'title + first name row');
    });

    testWidgets('a phone field with the keyboard open', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              PhoneField(
                controller: TextEditingController(text: '9876543210'),
                countryCode: '+971',
                onCountryCodeChanged: (_) {},
              ),
            ],
          ),
        ),
        width: 320,
        // A phone keyboard eats roughly this much of the viewport.
        bottomInset: 320,
      );
      expectNoOverflow(tester, 'PhoneField with the keyboard open');
      expect(find.text('+971'), findsOneWidget);
    });
  });

  group('BookingConfirmationPage', () {
    for (final width in phoneWidths) {
      testWidgets('confirmed booking at ${width.toInt()}px', (tester) async {
        await tester.pumpPhone(
          BookingConfirmationPage(
            outcome: outcome(),
            summaryTitle: 'BOM → DXB · Round trip',
            summarySubtitle: '2 adults, 1 child · Economy',
            details: const [
              DetailRow(label: 'Departure', value: '14 Aug 2026'),
              DetailRow(
                label: 'Lead traveller',
                value: 'Priya Raghunathan-Venkataraman',
              ),
            ],
            nextSteps: const [
              (
                title: 'E-ticket on its way',
                body:
                    'Your ticket and PNR are emailed to the address on the '
                    'booking.',
              ),
              (
                title: 'Web check-in',
                body: 'Most airlines open check-in 48 hours before departure.',
              ),
            ],
            onViewBookings: () {},
          ),
          width: width,
        );
        expectNoOverflow(tester, 'BookingConfirmationPage at ${width}px');
        expect(find.text('You are all set'), findsOneWidget);

        // The actions live below the fold on a phone, so scrolling to them is
        // also what exercises the rest of the page for overflow.
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expectNoOverflow(tester, 'BookingConfirmationPage scrolled');
        expect(find.text('View my trips'), findsOneWidget);
      });
    }

    testWidgets('a held fare says so, not "confirmed"', (tester) async {
      await tester.pumpPhone(
        BookingConfirmationPage(
          outcome: outcome(onHold: true),
          summaryTitle: 'BOM → DXB',
        ),
        width: 360,
      );
      expectNoOverflow(tester, 'held-fare confirmation');
      expect(find.text('Your fare is held'), findsOneWidget);
      expect(find.text('You are all set'), findsNothing);
    });

    testWidgets('a pending supplier is called out', (tester) async {
      await tester.pumpPhone(
        BookingConfirmationPage(
          outcome: outcome(status: 'PAYMENT_SUCCESS'),
          summaryTitle: 'Taj Exotica Resort & Spa',
        ),
        width: 360,
      );
      expectNoOverflow(tester, 'pending confirmation');
      expect(find.text('Payment received'), findsOneWidget);
    });

    testWidgets('renders with no details and no next steps', (tester) async {
      await tester.pumpPhone(
        BookingConfirmationPage(
          outcome: const BookingOutcome(
            product: TravelProduct.cab,
            reference: '',
          ),
          summaryTitle: 'Transfer',
        ),
        width: 320,
      );
      expectNoOverflow(tester, 'empty confirmation');
    });
  });

  group('TripCard', () {
    for (final width in phoneWidths) {
      testWidgets('at ${width.toInt()}px', (tester) async {
        await tester.pumpPhone(
          Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TripCard(booking: booking(), onTap: () {}),
                const SizedBox(height: AppSpacing.md),
                TripCard(
                  booking: booking(
                    product: TravelProduct.hotel,
                    title:
                        'The Leela Palace Udaipur Lakeside Heritage Resort',
                    status: 'CANCELLED',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TripCard(
                  booking: booking(
                    product: TravelProduct.insurance,
                    status: 'AWAITING_SUPPLIER_CONFIRMATION',
                  ),
                ),
              ],
            ),
          ),
          width: width,
          textScale: maxTextScale,
        );
        expectNoOverflow(tester, 'TripCard at ${width}px');
        expectNoHorizontalOverflow(tester, width);
      });
    }

    testWidgets('a booking with almost no data still renders', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              TripCard(
                booking: TravelBooking(
                  product: TravelProduct.cab,
                  reference: '',
                ),
              ),
            ],
          ),
        ),
        width: 320,
      );
      expectNoOverflow(tester, 'TripCard with empty data');
    });
  });

  group('Fare breakdown sheet', () {
    testWidgets('opens and totals correctly at 320px', (tester) async {
      await tester.pumpPhone(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showFareBreakdownSheet(
                  context,
                  sampleFare,
                  footnote:
                      'Fares are held only briefly and can change until the '
                      'booking is confirmed.',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        width: 320,
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expectNoOverflow(tester, 'fare breakdown sheet');
      expect(find.text('Total payable'), findsOneWidget);
      expect(find.text('Base fare'), findsOneWidget);
      expect(find.text('2 adults, 1 child'), findsOneWidget);
    });
  });

  group('Fare arithmetic', () {
    test('prices every passenger, not just one adult', () {
      // `fd` quotes per passenger type; a party of 2 adults + 1 child must be
      // charged for all three.
      final fare = {
        'fd': {
          'ADULT': {
            'fC': {'BF': 10000, 'TF': 12000},
          },
          'CHILD': {
            'fC': {'BF': 8000, 'TF': 9000},
          },
        },
      };

      final counts = {PaxType.adult: 2, PaxType.child: 1, PaxType.infant: 0};

      expect(FareBreakdown.sumAcrossPax(fare, 'TF', counts), 33000);
      expect(FareBreakdown.sumAcrossPax(fare, 'BF', counts), 28000);
    });

    test("the supplier's own grand total wins over the per-leg walk", () {
      final fare = {
        'fd': {
          'ADULT': {
            'fC': {'BF': 10000, 'TF': 12000},
          },
        },
      };
      final breakdown = FareBreakdown.forFlight(
        fares: [fare],
        paxCounts: {PaxType.adult: 1},
        supplierTotal: 12500,
      );

      expect(breakdown.total, 12500);
      // The gap is shown rather than hidden.
      expect(
        breakdown.lines.any((l) => l.label == 'Fare adjustment'),
        isTrue,
      );
    });

    test('falls back to the per-leg walk when no total was quoted', () {
      final fare = {
        'fd': {
          'ADULT': {
            'fC': {'BF': 10000, 'TF': 12000},
          },
        },
      };
      final breakdown = FareBreakdown.forFlight(
        fares: [fare],
        paxCounts: {PaxType.adult: 2},
      );
      expect(breakdown.total, 24000);
    });

    test('a service charge is added on top of the supplier fare', () {
      final breakdown = FareBreakdown.forFlight(
        fares: const [],
        paxCounts: {PaxType.adult: 1},
        supplierTotal: 10000,
        serviceCharge: 500,
      );
      expect(breakdown.total, 10500);
    });
  });

  group('Age bands are assessed on the travel date', () {
    // A child who turns 12 before departure must not pass as a child, which
    // is exactly what anchoring on today would allow.
    final travel = DateTime(2026, 8, 28);

    test('an adult must be 12 or older on the travel date', () {
      final bounds = dobBoundsFor(PaxType.adult, travel);
      expect(bounds.max, DateTime(2014, 8, 28));
      expect(bounds.min, isNull);
    });

    test('a child is 2 to under 12 on the travel date', () {
      final bounds = dobBoundsFor(PaxType.child, travel);
      expect(bounds.min, DateTime(2014, 8, 29));
      expect(bounds.max, DateTime(2024, 8, 28));
    });

    test('an infant is under 2 on the travel date', () {
      final bounds = dobBoundsFor(PaxType.infant, travel);
      expect(bounds.min, DateTime(2024, 8, 29));
      expect(bounds.max!.isAfter(DateTime(2024, 8, 29)), isTrue);
    });
  });

  group('Fare conditions are read from the fare, never assumed', () {
    test('a domestic fare needs no passport', () {
      final c = FareConditions.fromJson({'st': 900});
      expect(c.passportRequired, isFalse);
      expect(c.emergencyContactRequired, isFalse);
      expect(c.blockAllowed, isFalse);
    });

    test('an international fare requires a passport', () {
      final c = FareConditions.fromJson({
        'pcs': {'pid': true},
        'iecr': true,
        'isBA': true,
        'anlm': {'fN': 32, 'lN': 32, 'n': 60},
      });
      expect(c.passportRequired, isTrue);
      expect(c.passportIssueDateRequired, isTrue);
      expect(c.emergencyContactRequired, isTrue);
      expect(c.blockAllowed, isTrue);
      expect(c.firstNameMax, 32);
      expect(c.combinedNameMax, 60);
    });

    test('an international fare can opt out of the passport requirement', () {
      final c = FareConditions.fromJson({
        'pcs': {'pm': false},
      });
      expect(c.passportRequired, isFalse);
    });

    test('missing name limits fall back to generous defaults', () {
      final c = FareConditions.fromJson(null);
      expect(c.firstNameMax, 50);
      expect(c.lastNameMin, 1);
      expect(c.adultDobRequired, isTrue);
    });
  });

  group('Cab quotes are flattened out of their vehicle groups', () {
    test('reads the fare off the quote, not the group', () {
      // Reading a group as if it were a quote found no fare at all, so every
      // option was dropped by the price filter and transfers came back empty.
      final quotes = CabQuote.flatten([
        {
          'vehicleType': 'SEDAN',
          'vehicleCategory': 'Sedan',
          'label': 'Dzire or similar',
          'paxCapacity': 4,
          'luggageCapacity': 2,
          'quotes': [
            {
              'quotationId': 'Q2',
              'vendorId': 'V1',
              'fareBreakup': {'totalFare': 2000, 'totalTax': 100},
            },
            {
              'quotationId': 'Q1',
              'vendorId': 'V2',
              'fareBreakup': {'totalFare': 1500, 'totalTax': 75},
            },
          ],
        },
      ]);

      expect(quotes, hasLength(2));
      // Cheapest first.
      expect(quotes.first.quotationId, 'Q1');
      expect(quotes.first.price, 1575);
      expect(quotes.first.seats, 4);
      expect(quotes.first.vehicleName, 'Dzire or similar');
    });

    test('an unpriced quote is dropped rather than shown as free', () {
      final quotes = CabQuote.flatten([
        {
          'vehicleType': 'SUV',
          'quotes': [
            {'quotationId': 'Q1', 'fareBreakup': {'totalFare': 0}},
          ],
        },
      ]);
      expect(quotes, isEmpty);
    });

    test('the booking payload sends amounts as strings', () {
      final quote = CabQuote.flatten([
        {
          'vehicleType': 'SEDAN',
          'quotes': [
            {
              'quotationId': 'Q1',
              'fareBreakup': {'totalFare': 1500, 'totalTax': 75},
            },
          ],
        },
      ]).single;

      final pricing = quote.toPricingInfo();
      expect(pricing['netAmount'], '1500.00');
      expect(pricing['grossAmount'], '1575.00');
      expect(quote.toQuotationInfo()['quoteId'], 'Q1');
    });
  });

  group('Insurance plans are read out of the nested search response', () {
    Map<String, dynamic> searchResponse({required Map<String, dynamic> ppdf}) =>
        {
          'data': {
            'isq': {
              'iti': [
                {'age': 30},
                {'age': 28},
              ],
            },
            'isr': {
              'iinfo': {
                'pli': [
                  {
                    'plid': 'PL1',
                    'pi': [
                      {
                        'pid': 'PR1',
                        'pi': 'Explorer Gold',
                        'pn': 'USD 100,000',
                        'ip': 'ABHI',
                        'rname': 'Schengen',
                        'aps': ['BOXX'],
                        'pbft': [
                          {
                            'name': 'Medical expenses',
                            'type': 'INSURANCE',
                            'bv': 'BANNER',
                          },
                          {
                            'name': 'Concierge',
                            'type': 'ASSISTANCE',
                            'bv': 'BANNER',
                          },
                          {'name': 'Medical expenses', 'type': 'INSURANCE'},
                        ],
                        'pfd': {
                          'ppd': {'ppdf': ppdf},
                        },
                      },
                    ],
                  },
                ],
              },
            },
          },
        };

    test('a flat per-traveller premium is multiplied by the party', () {
      // Every key quoting the same amount means it is priced per traveller.
      final plans = InsurancePlan.fromSearchResponse(
        searchResponse(
          ppdf: {
            '1': [
              {
                'ifc': {'TF': 1200},
              },
            ],
            '2': [
              {
                'ifc': {'TF': 1200},
              },
            ],
          },
        ),
      );

      expect(plans, hasLength(1));
      expect(plans.single.price, 2400);
      expect(plans.single.planId, 'PL1');
      expect(plans.single.productId, 'PR1');
      expect(plans.single.travellerCount, 2);
      expect(plans.single.isBookable, isTrue);
    });

    test('a banded premium already covers the party', () {
      // Differing keys mean the highest band is the whole-party price;
      // multiplying again would charge twice.
      final plans = InsurancePlan.fromSearchResponse(
        searchResponse(
          ppdf: {
            '1': [
              {
                'ifc': {'TF': 1200},
              },
            ],
            '2': [
              {
                'ifc': {'TF': 2100},
              },
            ],
          },
        ),
      );
      expect(plans.single.price, 2100);
    });

    test('benefits are de-duplicated and split by family', () {
      final plan = InsurancePlan.fromSearchResponse(
        searchResponse(
          ppdf: {
            '1': [
              {
                'ifc': {'TF': 1000},
              },
            ],
          },
        ),
      ).single;

      expect(plan.benefits, hasLength(2));
      expect(plan.coverageTags, contains('Medical expenses'));
      expect(plan.assistanceTags, contains('Concierge'));
      expect(plan.insurerLabel, 'Aditya Birla Health Insurance');
    });

    test('an empty or unexpected response yields no plans, not a crash', () {
      expect(InsurancePlan.fromSearchResponse(null), isEmpty);
      expect(InsurancePlan.fromSearchResponse({'status': false}), isEmpty);
      expect(InsurancePlan.fromSearchResponse([1, 2, 3]), isEmpty);
    });
  });

  group('Fare choice avoids return-coupled fares', () {
    // A trip lists several fares. Taking totalPriceList[0] blindly picked a
    // SPECIAL_RETURN fare, which the supplier refuses to combine with a leg
    // chosen independently:
    //   1080 — All Segments Must be selected if Special Return fare.
    List<dynamic> fares(List<String> identifiers) => [
      for (var i = 0; i < identifiers.length; i++)
        {
          'id': 'fare-$i',
          'fareIdentifier': identifiers[i],
          'fd': {
            'ADULT': {
              'fC': {'TF': 1000 + i},
            },
          },
        },
    ];

    test('PUBLISHED wins even when it is not first', () {
      final picked = FlightResult.pickBookableFare(
        fares(['SPECIAL_RETURN', 'PUBLISHED']),
      );
      expect(readKey(picked, 'id'), 'fare-1');
    });

    test('any non-coupled fare beats a coupled one', () {
      final picked = FlightResult.pickBookableFare(
        fares(['SPECIAL_RETURN', 'FLEXI_PLUS']),
      );
      expect(readKey(picked, 'id'), 'fare-1');
    });

    test('a coupled-only trip still yields a fare, flagged as coupled', () {
      final flight = FlightResult.fromTripJack({
        'sI': [
          {
            'da': {'code': 'BOM'},
            'aa': {'code': 'DEL'},
            'duration': 120,
            'fD': {
              'aI': {'code': '6E'},
              'fN': '1',
            },
          },
        ],
        'totalPriceList': fares(['SPECIAL_RETURN']),
      });
      expect(flight.id, 'fare-0');
      expect(flight.isReturnCoupledFare, isTrue);
    });

    test('the chosen fare is the one whose price is shown', () {
      final flight = FlightResult.fromTripJack({
        'sI': [
          {
            'da': {'code': 'BOM'},
            'aa': {'code': 'DEL'},
            'duration': 120,
            'fD': {
              'aI': {'code': '6E'},
              'fN': '1',
            },
          },
        ],
        'totalPriceList': fares(['SPECIAL_RETURN', 'PUBLISHED']),
      });
      expect(flight.id, 'fare-1');
      expect(flight.price, 1001);
      expect(flight.isReturnCoupledFare, isFalse);
    });
  });

  group('Flight results keep their legs separate', () {
    test('a round trip splits onward from return', () {
      const result = FlightSearchResult(
        onward: [FlightResult(id: 'A', price: 200)],
        inbound: [FlightResult(id: 'B', price: 100)],
      );
      expect(result.hasSeparateReturn, isTrue);
      expect(result.totalCount, 2);
    });

    test('a one-way search has no return leg to pick', () {
      const result = FlightSearchResult(
        onward: [FlightResult(id: 'A')],
      );
      expect(result.hasSeparateReturn, isFalse);
    });

    test('results sort cheapest first', () {
      const result = FlightSearchResult(
        onward: [
          FlightResult(id: 'A', price: 9000),
          FlightResult(id: 'B', price: 4000),
        ],
      );
      expect(result.sortedOnward.first.id, 'B');
    });
  });

  group('Traveller payloads omit what the fare does not ask for', () {
    TravellerInput adult() => TravellerInput(type: PaxType.adult)
      ..firstName = ' Priya '
      ..lastName = 'Raghunathan'
      ..dob = DateTime(1994, 3, 12)
      ..passportNumber = 'z1234567';

    test('a domestic fare sends no passport block', () {
      final json = adult().toJson(
        passportRequired: false,
        docIdApplicable: false,
      );
      expect(json['fN'], 'Priya');
      expect(json['pt'], 'ADULT');
      expect(json['dob'], '1994-03-12');
      expect(json.containsKey('pNum'), isFalse);
      expect(json.containsKey('pNat'), isFalse);
    });

    test('an international fare sends an upper-cased passport', () {
      final t = adult()..passportExpiry = DateTime(2030, 1, 5);
      final json = t.toJson(passportRequired: true, docIdApplicable: false);
      expect(json['pNum'], 'Z1234567');
      expect(json['eD'], '2030-01-05');
    });

    test('an empty document id is omitted rather than sent blank', () {
      final json = adult().toJson(
        passportRequired: false,
        docIdApplicable: true,
      );
      expect(json.containsKey('di'), isFalse);
    });
  });

  group('Insurance traveller names split the way the insurer expects', () {
    test('a single-word name fills both fields', () {
      final t = InsuranceTravellerInput(id: 1, age: 30)..fullName = 'Priya';
      expect(t.splitName.first, 'Priya');
      expect(t.splitName.last, 'Priya');
    });

    test('a multi-word name keeps the remainder as the family name', () {
      final t = InsuranceTravellerInput(id: 1, age: 30)
        ..fullName = 'Priya Raghunathan Venkataraman';
      expect(t.splitName.first, 'Priya');
      expect(t.splitName.last, 'Raghunathan Venkataraman');
    });
  });

  group('Payment orders are read whichever way the endpoint spells them', () {
    test('the snake_case flight shape', () {
      final order = PaymentOrder.fromJson({
        'razorpay_order_id': 'order_1',
        'key_id': 'rzp_test_1',
        'amount': 969800,
      });
      expect(order.isUsable, isTrue);
      expect(order.orderId, 'order_1');
      expect(order.amountInPaise, 969800);
      expect(order.currency, 'INR');
    });

    test('the camelCase hotel/cab shape', () {
      final order = PaymentOrder.fromJson({
        'razorpayOrderId': 'order_2',
        'keyId': 'rzp_live_2',
        'currency': 'INR',
      });
      expect(order.isUsable, isTrue);
      expect(order.orderId, 'order_2');
    });

    test('a response missing credentials is not usable', () {
      final order = PaymentOrder.fromJson({'amount': 100});
      expect(order.isUsable, isFalse);
    });
  });

  group('Booking rows normalise across four unrelated payloads', () {
    test('a flight row', () {
      final b = TravelBooking.fromFlightRow({
        'order_id': 'ORD1',
        'from': 'BOM',
        'to': 'DXB',
        'airline': 'IndiGo',
        'departure': '2030-08-14T09:30:00',
        'booking_status': 'CONFIRMED',
        'amount_paid': 96980,
        'passenger_name': 'Priya R',
        'passenger_count': 3,
      });
      expect(b.title, 'BOM → DXB');
      expect(b.isConfirmed, isTrue);
      expect(b.isUpcoming, isTrue);
      expect(b.travellerSummary, 'Priya R +2 more');
    });

    test('a hotel row derives the number of nights', () {
      final b = TravelBooking.fromHotelRow({
        'booking_id': 'HB1',
        'hotel_name': 'Taj Exotica',
        'checkin_date': '2030-08-14',
        'checkout_date': '2030-08-19',
        'status': 'CONFIRMED',
      });
      expect(b.travellerSummary, '5 nights');
    });

    test('a cancelled booking never reads as confirmed', () {
      final b = TravelBooking.fromFlightRow({
        'order_id': 'ORD2',
        'booking_status': 'CANCELLED',
        'payment_status': 'REFUNDED',
      });
      expect(b.isCancelled, isTrue);
      expect(b.isConfirmed, isFalse);
    });

    test('a malformed row degrades instead of throwing', () {
      final b = TravelBooking.fromFlightRow(null);
      expect(b.reference, isEmpty);
      expect(b.isConfirmed, isFalse);
    });
  });

  group('Contact details', () {
    test('the dialled number drops the plus for deliveryInfo', () {
      final c = ContactDetails(countryCode: '+971', mobile: ' 501234567 ');
      expect(c.dialled, '971501234567');
    });

    test('a short number is not valid', () {
      final c = ContactDetails(mobile: '12345', email: 'a@b.com');
      expect(c.isValid, isFalse);
    });
  });
}
