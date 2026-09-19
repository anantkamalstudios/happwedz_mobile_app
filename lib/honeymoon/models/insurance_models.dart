/// Travel-insurance models that sit around [InsurancePlan]: the search
/// itself, the premium breakdown, the booked policy, and its status.
///
/// Each mirrors a piece of `services/api/tripSafeApi.js`:
///  * [InsuranceSearchQuery.toPayload] ← `InsuranceSearchPanel.jsx`
///    `handleSearch` (three `isq` shapes, one per plan type);
///  * [InsurancePriceBreakdown] ← `getPriceBreakdown`;
///  * [insuranceAssistancePartner] ← the partner pick in
///    `mapTripSafeSearchResponse`;
///  * [InsuranceBookingDetails] ← `mapTripSafeBookingDetails`;
///  * [insuranceStatusOf] ← `utils/bookingStatus.js`, source `insurance`.
library;

import '../insurance_config.dart';
import 'booking_models.dart' show apiDate;
import 'honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// Everything an insurance search was made with.
class InsuranceSearchQuery {
  const InsuranceSearchQuery({
    required this.planType,
    required this.destination,
    required this.start,
    required this.end,
    required this.ages,
    this.coverageDays = InsuranceLimits.defaultStudentCoverageDays,
    this.amtTripDays = InsuranceLimits.defaultAmtTripDays,
    this.flightBookingId = '',
  });

  final InsurancePlanType planType;
  final InsuranceDestination destination;
  final DateTime start;

  /// For a student plan this is start + [coverageDays], for display only —
  /// the supplier takes `cd`, not `ed`.
  final DateTime end;

  /// One age per insured person; TripSafe prices on age.
  final List<int> ages;

  /// Student plans: cover length in days (`isq.cd`).
  final int coverageDays;

  /// Annual multi-trip: the longest single trip (`isq.adr`).
  final int amtTripDays;

  /// A flight booking to embed the cover in (`isq.bid`), optional.
  final String flightBookingId;

  int get travellerCount => ages.isEmpty ? 1 : ages.length;

  bool get isEmbedded =>
      planType != InsurancePlanType.annualMultiTrip &&
      flightBookingId.trim().isNotEmpty;

  /// The request body, exactly as the web builds it per plan type:
  ///
  /// ```
  /// International  {isq:{sd, ed, isc, iti, isp:{}}}            (+ isef, bid,
  ///                                                             ict API_EMB)
  /// Student        {isq:{sd, cd, isc, iti, isef:false, ict:STUDENT}} (+ bid)
  /// AMT            {isq:{sd, ed, isc(POPULARREGION), iti, isp:{}, adr},
  ///                 ict: AMT}
  /// ```
  Map<String, dynamic> toPayload() {
    final iti = [
      for (final age in ages) {'age': age},
    ];
    switch (planType) {
      case InsurancePlanType.student:
        final isq = <String, dynamic>{
          'sd': apiDate(start),
          'cd': '$coverageDays',
          'isc': {
            'iri': [destination.toIri()],
          },
          'iti': iti,
          'isef': false,
          'ict': 'STUDENT',
        };
        if (isEmbedded) {
          isq['isef'] = true;
          isq['bid'] = flightBookingId.trim();
        }
        return {'isq': isq};

      case InsurancePlanType.annualMultiTrip:
        return {
          'isq': {
            'sd': apiDate(start),
            'ed': apiDate(end),
            'isc': {
              'iri': [
                {'rkey': destination.rkey, 'rt': 'POPULARREGION'},
              ],
            },
            'iti': iti,
            'isp': <String, dynamic>{},
            'adr': amtTripDays,
          },
          'ict': 'AMT',
        };

      case InsurancePlanType.international:
        final isq = <String, dynamic>{
          'sd': apiDate(start),
          'ed': apiDate(end),
          'isc': {
            'iri': [destination.toIri()],
          },
          'iti': iti,
          'isp': <String, dynamic>{},
        };
        final payload = <String, dynamic>{'isq': isq};
        if (isEmbedded) {
          isq['isef'] = true;
          isq['bid'] = flightBookingId.trim();
          payload['ict'] = 'API_EMB';
        }
        return payload;
    }
  }

  /// The web's "nothing found" message per plan type.
  String get emptyMessage => switch (planType) {
    InsurancePlanType.student =>
      'No student insurance packages found. Try a different country or '
          'duration.',
    InsurancePlanType.annualMultiTrip =>
      'No annual multi-trip packages found. Try different settings.',
    InsurancePlanType.international =>
      'No insurance packages found for the selected criteria. Try different '
          'dates or destination.',
  };
}

// ---------------------------------------------------------------------------
// Premium
// ---------------------------------------------------------------------------

/// The premium split the web's plan summary shows (`getPriceBreakdown`).
class InsurancePriceBreakdown {
  const InsurancePriceBreakdown({
    this.total = 0,
    this.serviceFee = 0,
    this.serviceFeeGst = 0,
    this.perTraveller = 0,
  });

  /// `TF` for the party — what is charged.
  final double total;

  /// `SP` / `SPGST` — the "TripSafe Fee" and its GST lines.
  final double serviceFee;
  final double serviceFeeGst;
  final double perTraveller;

  /// Reads `pfd.ppd.ppdf` the way [InsurancePlan.priceFor] does: a map keyed
  /// by party size, quoting per traveller when every key agrees and the whole
  /// party at the highest key when they differ.
  factory InsurancePriceBreakdown.of(dynamic product, int travellerCount) {
    final ppdf = digPath(product, ['pfd', 'ppd', 'ppdf']);
    if (ppdf is! Map || ppdf.isEmpty) return const InsurancePriceBreakdown();

    final keys = ppdf.keys.map((k) => asString(k)).toList()
      ..sort((a, b) => asInt(a).compareTo(asInt(b)));
    double tf(String k) => asDouble(digPath(ppdf[k], [0, 'ifc', 'TF']));
    final allSame = keys.every((k) => tf(k) == tf(keys.first));

    final ifc = allSame
        ? digPath(ppdf['$travellerCount'] ?? ppdf['1'], [0, 'ifc'])
        : digPath(ppdf[keys.last], [0, 'ifc']);
    final count = allSame ? travellerCount : 1;

    final perTf = asDouble(readKey(ifc, 'TF'));
    return InsurancePriceBreakdown(
      total: perTf * count,
      serviceFee: asDouble(readKey(ifc, 'SP')) * count,
      serviceFeeGst: asDouble(readKey(ifc, 'SPGST')) * count,
      perTraveller: perTf,
    );
  }
}

/// What the web derives from a plan beyond [InsurancePlan]'s own fields.
extension InsurancePlanExtras on InsurancePlan {
  /// "TripSafe Fee" / GST split of the premium for this party.
  InsurancePriceBreakdown get breakdown =>
      InsurancePriceBreakdown.of(raw, travellerCount);

  /// "Assistance by …" on the card.
  String get assistancePartner => insuranceAssistancePartner(partners);

  /// This plan at the premium the review confirmed.
  InsurancePlan withPrice(double reviewed) => InsurancePlan(
    planId: planId,
    productId: productId,
    name: name,
    insurer: insurer,
    coverageAmount: coverageAmount,
    regionName: regionName,
    price: reviewed > 0 ? reviewed : price,
    currency: currency,
    travellerCount: travellerCount,
    partners: partners,
    benefits: benefits,
    raw: raw,
  );
}

/// The assistance partner a card names: the first `aps` entry that looks
/// like an assistance provider, else the first partner.
String insuranceAssistancePartner(List<String> partners) {
  final match = RegExp(r'assist|boxx|zetexa|brb', caseSensitive: false);
  for (final p in partners) {
    if (match.hasMatch(p)) return p;
  }
  return partners.isEmpty ? '' : partners.first;
}

// ---------------------------------------------------------------------------
// Booked policy
// ---------------------------------------------------------------------------

/// One insured person on an issued policy.
class InsuredTraveller {
  const InsuredTraveller({
    required this.id,
    this.name = '',
    this.age = 0,
    this.email = '',
    this.mobile = '',
    this.passport = '',
    this.pincode = '',
    this.gender = '',
    this.policyId = '',
    this.nominee = '',
  });

  final String id;
  final String name;
  final int age;
  final String email;
  final String mobile;
  final String passport;
  final String pincode;
  final String gender;
  final String policyId;
  final String nominee;
}

/// A `POST tripsafe/booking-details` answer — `mapTripSafeBookingDetails`.
class InsuranceBookingDetails {
  const InsuranceBookingDetails({
    required this.bookingId,
    this.orderStatus = '',
    this.amount = 0,
    this.createdOn,
    this.emails = const [],
    this.contacts = const [],
    this.planId = '',
    this.productId = '',
    this.planLabel = 'Insurance Plan',
    this.coverageAmount = '',
    this.regionName = '',
    this.insurer = '',
    this.partners = const [],
    this.activeFrom,
    this.startDate,
    this.endDate,
    this.benefits = const [],
    this.travellers = const [],
    this.raw = const <String, dynamic>{},
  });

  final String bookingId;
  final String orderStatus;
  final double amount;
  final DateTime? createdOn;
  final List<String> emails;
  final List<String> contacts;
  final String planId;
  final String productId;
  final String planLabel;
  final String coverageAmount;
  final String regionName;
  final String insurer;
  final List<String> partners;
  final DateTime? activeFrom;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<InsuranceBenefit> benefits;
  final List<InsuredTraveller> travellers;
  final Map<String, dynamic> raw;

  String get insurerLabel => insurerLabelFor(insurer);

  /// The web issues the policy document and allows cancelling only once the
  /// order is SUCCESS.
  bool get isSuccess => orderStatus.toUpperCase() == 'SUCCESS';

  /// Cancelling names the plan and product the travellers are insured under.
  bool get canCancel => isSuccess && planId.isNotEmpty && productId.isNotEmpty;

  factory InsuranceBookingDetails.fromJson(dynamic payload) {
    final raw = readKey(payload, 'data') ?? payload;
    final order = readKey(raw, 'order');
    final insurance = digPath(raw, ['itemInfos', 'INSURANCE']);
    final iinfo = readKey(insurance, 'iinfo');
    final isq = readKey(insurance, 'isq');
    final product = digPath(iinfo, ['pli', 0, 'pi', 0]);
    final fromProduct = asList(readKey(product, 'iti'));
    final travellers = fromProduct.isNotEmpty
        ? fromProduct
        : asList(readKey(isq, 'iti'));

    final orderAmount = asDouble(readKey(order, 'amount'));
    final amount = orderAmount > 0
        ? orderAmount
        : asDouble(digPath(product, ['tfd', 'ifc', 'TF'])) > 0
        ? asDouble(digPath(product, ['tfd', 'ifc', 'TF']))
        : asDouble(digPath(product, ['iti', 0, 'fd', 'ifc', 'TF']));

    final seen = <String>{};
    return InsuranceBookingDetails(
      bookingId: firstNonEmpty([
        readKey(order, 'bookingId'),
        readKey(raw, 'bookingId'),
      ]),
      orderStatus: firstNonEmpty([
        readKey(order, 'status'),
        readKey(insurance, 'ios'),
      ]),
      amount: amount,
      createdOn: DateTime.tryParse(asString(readKey(order, 'createdOn'))),
      emails: [
        for (final e in asList(digPath(order, ['deliveryInfo', 'emails'])))
          if (asString(e).isNotEmpty) asString(e),
      ],
      contacts: [
        for (final c in asList(digPath(order, ['deliveryInfo', 'contacts'])))
          if (asString(c).isNotEmpty) asString(c),
      ],
      planId: asString(digPath(iinfo, ['pli', 0, 'plid'])),
      productId: asString(readKey(product, 'pid')),
      planLabel: asString(readKey(product, 'pi'), fallback: 'Insurance Plan'),
      coverageAmount: asString(readKey(product, 'pn')),
      regionName: asString(readKey(product, 'rname')),
      insurer: asString(readKey(product, 'ip')),
      partners: [
        for (final p in asList(readKey(product, 'aps')))
          if (asString(p).isNotEmpty) asString(p),
      ],
      activeFrom: DateTime.tryParse(
        firstNonEmpty([readKey(iinfo, 'activeFrom'), readKey(isq, 'sd')]),
      ),
      startDate: DateTime.tryParse(asString(readKey(isq, 'sd'))),
      endDate: DateTime.tryParse(asString(readKey(isq, 'ed'))),
      benefits: [
        for (final b in asList(readKey(product, 'pbft')))
          if (asString(readKey(b, 'name')).trim().isNotEmpty &&
              seen.add(asString(readKey(b, 'name')).trim()))
            InsuranceBenefit.fromJson(b),
      ],
      travellers: [
        for (final t in travellers)
          InsuredTraveller(
            id: asString(readKey(t, 'id')),
            name: [
              asString(readKey(t, 'fn')),
              asString(readKey(t, 'ln')),
            ].where((s) => s.isNotEmpty).join(' '),
            age: asInt(readKey(t, 'age')),
            email: asString(readKey(t, 'eid')),
            mobile: asString(readKey(t, 'cnum')),
            passport: asString(readKey(t, 'pnum')),
            pincode: asString(readKey(t, 'pincode')),
            gender: switch (asString(readKey(t, 'gen'))) {
              'F' => 'Female',
              'M' => 'Male',
              final other => other,
            },
            policyId: asString(readKey(t, 'policyId')),
            nominee: firstNonEmpty([
              digPath(t, ['ni', 0, 'nn']),
              digPath(t, ['ni', 0, 'nr']),
            ]),
          ),
      ],
      raw: asJsonMap(raw),
    );
  }
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

enum InsuranceStatusKey { confirmed, pending, cancelled, failed, unknown }

typedef InsuranceStatus = ({InsuranceStatusKey key, String label});

/// The web dashboard's insurance vocabulary: SUCCESS/ISSUED read "Policy
/// Issued", CONFIRMED "Confirmed", the pending family "Pending".
InsuranceStatus insuranceStatusOf(String raw) {
  final value = raw.trim().toUpperCase();
  final key = switch (value) {
    'SUCCESS' || 'CONFIRMED' || 'ISSUED' => InsuranceStatusKey.confirmed,
    'PENDING' ||
    'PAYMENT_PENDING' ||
    'IN_PROGRESS' ||
    '' => InsuranceStatusKey.pending,
    'CANCELLED' || 'CANCELED' => InsuranceStatusKey.cancelled,
    'FAILED' => InsuranceStatusKey.failed,
    _ => InsuranceStatusKey.unknown,
  };
  final label = switch (value) {
    'SUCCESS' || 'ISSUED' => 'Policy Issued',
    _ => switch (key) {
      InsuranceStatusKey.confirmed => 'Confirmed',
      InsuranceStatusKey.pending => 'Pending',
      InsuranceStatusKey.cancelled => 'Cancelled',
      InsuranceStatusKey.failed => 'Failed',
      InsuranceStatusKey.unknown =>
        value
            .toLowerCase()
            .split(RegExp(r'[\s_-]+'))
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' '),
    },
  };
  return (key: key, label: label);
}

/// The filter pills the web's insurance panel always shows.
const List<InsuranceStatusKey> kInsuranceStatusFilters = [
  InsuranceStatusKey.confirmed,
  InsuranceStatusKey.pending,
  InsuranceStatusKey.cancelled,
];
