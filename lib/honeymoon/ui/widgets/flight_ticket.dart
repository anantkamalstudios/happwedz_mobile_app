/// The printable flight ticket and its print dialog — ports of
/// `components/TicketDocument.jsx` and `components/PrintTicketModal.jsx`.
///
/// On the web, "Download as PDF" and "Print Tickets" are the browser's print
/// dialog over a print-only copy of the ticket. The app has no page to print,
/// so the same ticket is drawn as a PDF: printed through the system dialog,
/// or shared/saved as a file. Every option in the dialog maps to the same
/// flag the web ticket reads.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/core.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import 'flight_widgets.dart';
import 'honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// A passenger as the booking recorded them.
typedef TicketPassenger = ({
  String title,
  String firstName,
  String lastName,
  String paxType,
  String dob,
  String passport,
  String frequentFlyer,
});

/// Everything the ticket prints. Built from the booking flow's own state on
/// the confirmation screen, or from `booking-details` on My Trips.
class FlightTicketData {
  const FlightTicketData({
    required this.bookingId,
    required this.legs,
    required this.passengers,
    this.createdAt,
    this.onHold = false,
    this.paxInfos = const [],
    this.preferences = const {},
    this.addOnTotal = 0,
    this.contactEmail = '',
    this.contactPhone = '',
    this.gstCompany = '',
    this.gstNumber = '',
    this.gstAddress = '',
    this.agentNote = '',
  });

  final String bookingId;
  final DateTime? createdAt;
  final bool onHold;
  final List<PricedLeg> legs;
  final List<TicketPassenger> passengers;

  /// The travellers booking-details returned — where PNRs and ticket numbers
  /// live.
  final List<BookedTraveller> paxInfos;

  /// Passenger index → route → "15 Kg Excess Baggage", "Veg Meal", "6F".
  final Map<int, Map<String, List<String>>> preferences;
  final double addOnTotal;
  final String contactEmail;
  final String contactPhone;
  final String gstCompany;
  final String gstNumber;
  final String gstAddress;
  final String agentNote;

  Map<String, int> get paxCounts => {
    for (final type in const ['ADULT', 'CHILD', 'INFANT'])
      type: passengers.where((p) => p.paxType == type).length,
  };

  /// The booked traveller behind passenger [i]: matched on name, else by
  /// position — the web's `infoFor`.
  BookedTraveller? infoFor(int i) {
    if (i >= passengers.length) return null;
    final p = passengers[i];
    for (final t in paxInfos) {
      if (t.firstName.toUpperCase() == p.firstName.toUpperCase() &&
          t.lastName.toUpperCase() == p.lastName.toUpperCase()) {
        return t;
      }
    }
    return i < paxInfos.length ? paxInfos[i] : null;
  }

  /// Distinct airline PNRs on the booking, with the route each covers.
  List<({String code, String route})> get pnrs {
    final seen = <String, String>{};
    for (final t in paxInfos) {
      for (final e in t.pnrs.entries) {
        seen.putIfAbsent(e.value, () => e.key);
      }
    }
    return [for (final e in seen.entries) (code: e.key, route: e.value)];
  }

  /// Segment id → "BOM-DEL".
  Map<String, String> get segmentRoutes => {
    for (final leg in legs)
      for (final s in asList(readKey(leg.trip, 'sI')))
        asString(readKey(s, 'id')):
            '${asString(digPath(s, ['da', 'code']))}-'
            '${asString(digPath(s, ['aa', 'code']))}',
  };

  Map<String, dynamic> get firstSegment =>
      asJsonMap(asList(readKey(legs.firstOrNull?.trip, 'sI')).firstOrNull);

  String get carrierCode =>
      asString(digPath(firstSegment, ['fD', 'aI', 'code']));
  String get carrierName =>
      asString(digPath(firstSegment, ['fD', 'aI', 'name']));
  String? get carrierLink => kCarrierTerms[carrierCode];
}

/// The print dialog's choices (`PrintTicketModal.jsx`), with its defaults.
class TicketPrintOptions {
  const TicketPrintOptions({
    this.showPrice = true,
    this.hideMarkup = false,
    this.agentDetails = true,
    this.gst = true,
    this.isOldPrintCopy = false,
    this.passportInfo = true,
    this.agentNotes = false,
    this.showRefundable = true,
    this.showContact = true,
    this.selectedPnrs,
  });

  final bool showPrice;
  final bool hideMarkup;
  final bool agentDetails;
  final bool gst;
  final bool isOldPrintCopy;
  final bool passportInfo;
  final bool agentNotes;
  final bool showRefundable;
  final bool showContact;

  /// Null prints every PNR.
  final List<String>? selectedPnrs;
}

// ---------------------------------------------------------------------------
// Print / share
// ---------------------------------------------------------------------------

/// "Print Tickets": the system print dialog over the ticket.
Future<void> printFlightTicket(
  FlightTicketData data, [
  TicketPrintOptions options = const TicketPrintOptions(),
]) {
  return Printing.layoutPdf(
    name: 'Ticket_${data.bookingId}',
    onLayout: (format) => buildFlightTicketPdf(data, options, format: format),
  );
}

/// "Download as PDF": the ticket as a file to save or send.
Future<void> shareFlightTicket(
  FlightTicketData data, [
  TicketPrintOptions options = const TicketPrintOptions(),
]) async {
  final bytes = await buildFlightTicketPdf(data, options);
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'Ticket_${data.bookingId}.pdf',
  );
}

/// The PRINT TICKET dialog. Resolves to the chosen options, or null when
/// closed.
Future<TicketPrintOptions?> showPrintTicketSheet(
  BuildContext context,
  FlightTicketData data,
) {
  return AppBottomSheet.show<TicketPrintOptions>(
    context,
    title: 'Print ticket',
    child: _PrintTicketBody(data: data),
  );
}

class _PrintTicketBody extends StatefulWidget {
  const _PrintTicketBody({required this.data});

  final FlightTicketData data;

  @override
  State<_PrintTicketBody> createState() => _PrintTicketBodyState();
}

class _PrintTicketBodyState extends State<_PrintTicketBody> {
  late final List<({String code, String route})> _pnrs = widget.data.pnrs;
  late final Set<String> _selected = {for (final p in _pnrs) p.code};
  String? _expanded;
  String _pricing = 'withPrice';

  final Map<String, bool> _flags = {
    'agentDetails': true,
    'gst': true,
    'isOldPrintCopy': false,
    'passportInfo': true,
    'agentNotes': false,
    'showRefundable': true,
    'showContact': true,
  };

  static const _flagLabels = {
    'agentDetails': 'With Agency',
    'gst': 'With GST',
    'isOldPrintCopy': 'Old Print Copy',
    'passportInfo': 'Passport Info',
    'agentNotes': 'Agent Notes',
    'showRefundable': 'Show Refundable/Non-Refundable',
    'showContact': 'Show Contact Details',
  };

  // Nothing to print until a PNR is ticked — unless the booking has none yet,
  // when blocking would make the ticket unprintable.
  bool get _canSubmit => _pnrs.isEmpty || _selected.isNotEmpty;

  void _submit() {
    Navigator.pop(
      context,
      TicketPrintOptions(
        showPrice: _pricing != 'withoutPrice',
        hideMarkup: _pricing == 'hideMarkup',
        agentDetails: _flags['agentDetails']!,
        gst: _flags['gst']!,
        isOldPrintCopy: _flags['isOldPrintCopy']!,
        passportInfo: _flags['passportInfo']!,
        agentNotes: _flags['agentNotes']!,
        showRefundable: _flags['showRefundable']!,
        showContact: _flags['showContact']!,
        selectedPnrs: _selected.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (final leg in widget.data.legs)
        for (final s in asList(readKey(leg.trip, 'sI'))) asJsonMap(s),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Select PNR to Print', style: AppText.formLabel),
            ),
            TextButton(
              onPressed: () => setState(
                () => _selected
                  ..clear()
                  ..addAll(_pnrs.map((p) => p.code)),
              ),
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: const Text('Clear All'),
            ),
          ],
        ),
        if (_pnrs.isEmpty)
          Text(
            'No airline PNR yet — the ticket will print without one.',
            style: AppText.caption,
          ),
        for (final p in _pnrs) ...[
          CheckboxListTile.adaptive(
            value: _selected.contains(p.code),
            onChanged: (_) => setState(() {
              if (!_selected.remove(p.code)) _selected.add(p.code);
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text('✈ ${p.code}', style: AppText.bodyStrong),
            secondary: TextButton(
              onPressed: () => setState(
                () => _expanded = _expanded == p.code ? null : p.code,
              ),
              child: Text(
                _expanded == p.code ? 'Hide details' : 'View Flight Details',
              ),
            ),
          ),
          if (_expanded == p.code)
            for (final s in segments)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xl,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    AirlineLogo(
                      code: asString(digPath(s, ['fD', 'aI', 'code'])),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${asString(digPath(s, ['fD', 'aI', 'code']))}-'
                        '${asString(digPath(s, ['fD', 'fN']))}  '
                        '${asString(digPath(s, ['da', 'code']))} '
                        '(${flightStamp(DateTime.tryParse(asString(readKey(s, 'dt'))))}) → '
                        '${asString(digPath(s, ['aa', 'code']))} '
                        '(${flightStamp(DateTime.tryParse(asString(readKey(s, 'at'))))})',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
        ],
        const Divider(height: AppSpacing.xl, color: AppColors.divider),
        Text('Select Desired Pricing Option', style: AppText.formLabel),
        Text('(you can select only one option)', style: AppText.caption),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final (value, label) in const [
              ('withPrice', 'With Price'),
              ('withoutPrice', 'Without Price'),
              ('hideMarkup', 'Hide Markup'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _pricing == value,
                selectedColor: AppColors.pinkSurface,
                onSelected: (_) => setState(() => _pricing = value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Select Other Options', style: AppText.formLabel),
        for (final key in _flagLabels.keys)
          CheckboxListTile.adaptive(
            value: _flags[key],
            onChanged: (v) => setState(() => _flags[key] = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(_flagLabels[key]!, style: AppText.bodySm),
          ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: 'Print',
          icon: Icons.print_rounded,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The document
// ---------------------------------------------------------------------------

/// The built-in PDF fonts carry no rupee glyph, so amounts print as "Rs.".
String _money(double n) => 'Rs. ${formatFlightFare(n).replaceFirst('₹', '')}';

const List<String> _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const List<String> _weekdaysShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// "Fri, 28 Aug '26, 08:15".
String _printStamp(String value) {
  final d = DateTime.tryParse(value);
  if (d == null) return '';
  return '${_weekdaysShort[d.weekday - 1]}, ${d.day} ${_monthsShort[d.month - 1]} '
      "'${d.year.toString().substring(2)}, "
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// "Aug 27, 2026 5:11 PM" — shared with the confirmation screen.
String _bookingStamp(DateTime? value) => flightBookingStamp(value);

// Previous local copy, kept for reference:
// /// "Aug 27, 2026 5:11 PM".
// String _bookingStamp(DateTime? value) {
//   final d = value ?? DateTime.now();
//   final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
//   return '${_monthsShort[d.month - 1]} ${d.day}, ${d.year} $h:'
//       '${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
// }

/// Draws the ticket - agency header, PNR block, then Flight Detail,
/// Passenger Details, Fare Details, Contact, GST, notes, Important
/// Information and the dangerous-goods panel, each behind a black bar.
Future<Uint8List> buildFlightTicketPdf(
  FlightTicketData data,
  TicketPrintOptions opts, {
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final doc = pw.Document(title: 'Ticket ${data.bookingId}');
  final small = pw.TextStyle(fontSize: 8);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget bar(String title, [String note = '']) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    color: PdfColors.black,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (note.isNotEmpty)
          pw.Text(
            note,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 7),
          ),
      ],
    ),
  );

  pw.Widget table(List<String> head, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: head,
        data: rows,
        headerStyle: bold,
        cellStyle: small,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignment: pw.Alignment.topLeft,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      );

  // --- sums, per passenger type across every leg --------------------------
  final pax = data.paxCounts;
  double sum(String key) {
    var total = 0.0;
    for (final leg in data.legs) {
      for (final e in pax.entries) {
        total +=
            asDouble(digPath(leg.fare, ['fd', e.key, 'fC', key])) * e.value;
      }
    }
    return total;
  }

  final taxParts = <String, double>{};
  var mgmtFee = 0.0;
  var mgmtGst = 0.0;
  for (final leg in data.legs) {
    for (final e in pax.entries) {
      if (e.value <= 0) continue;
      final taf = digPath(leg.fare, ['fd', e.key, 'afC', 'TAF']);
      if (taf is! Map) continue;
      for (final c in taf.entries) {
        final code = asString(c.key);
        final v = asDouble(c.value) * e.value;
        if (code == 'MF') {
          mgmtFee += v;
        } else if (code == 'MFT') {
          mgmtGst += v;
        } else {
          taxParts[code] = (taxParts[code] ?? 0) + v;
        }
      }
    }
  }
  final taxTotal = taxParts.values.fold<double>(0, (a, b) => a + b);
  // TripJack's TF is the authority - not always exactly BF + TAF - so the
  // total is taken from it and the components are display only.
  final grandTotal = sum('TF') + data.addOnTotal;

  final allPnrs = data.pnrs;
  final printed = opts.selectedPnrs == null || opts.selectedPnrs!.isEmpty
      ? allPnrs
      : allPnrs.where((p) => opts.selectedPnrs!.contains(p.code)).toList();
  final routes = data.segmentRoutes;

  // --- flight rows --------------------------------------------------------
  final flightRows = <List<String>>[];
  for (final leg in data.legs) {
    final segs = asList(readKey(leg.trip, 'sI'));
    final cc = asString(
      digPath(leg.fare, ['fd', 'ADULT', 'cc']),
      fallback: 'ECONOMY',
    );
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      String place(String k) {
        final p = readKey(s, k);
        final terminal = asString(readKey(p, 'terminal'));
        return '${asString(readKey(p, 'city'))}'
            '${terminal.isEmpty ? '' : ', $terminal'}\n'
            '${asString(readKey(p, 'name'))}';
      }

      flightRows.add([
        '${asString(digPath(s, ['fD', 'aI', 'code']))} - '
            '${asString(digPath(s, ['fD', 'fN']))}\n'
            '${asString(digPath(s, ['fD', 'aI', 'name']))}',
        asString(readKey(leg.fare, 'fareIdentifier'), fallback: 'NA'),
        '${cc[0]}${cc.substring(1).toLowerCase()}',
        if (opts.showRefundable)
          fareIsRefundable(leg.fare) ? 'Refundable' : 'Non-Refundable',
        '${_printStamp(asString(readKey(s, 'dt')))}\n${place('da')}',
        '${_printStamp(asString(readKey(s, 'at')))}\n${place('aa')}',
        flightMinutes(asInt(readKey(s, 'duration'))),
      ]);
      final layover = asInt(readKey(s, 'cT'));
      if (i < segs.length - 1 && layover > 0) {
        flightRows.add([
          'Layover Time - ${flightMinutes(layover)}',
          '',
          '',
          if (opts.showRefundable) '',
          '',
          '',
          '',
        ]);
      }
    }
  }

  // --- passenger rows -----------------------------------------------------
  final paxRows = <List<String>>[];
  for (var i = 0; i < data.passengers.length; i++) {
    final p = data.passengers[i];
    final info = data.infoFor(i);
    final pnrRoutes = info?.pnrs.keys.toList() ?? const <String>[];
    final shownRoutes = pnrRoutes.isNotEmpty
        ? pnrRoutes
        : routes.values.toSet().toList();
    final fd = digPath(data.legs.firstOrNull?.fare, ['fd', p.paxType]);
    final prefs = data.preferences[i] ?? const {};
    final dob = DateTime.tryParse(p.dob);
    paxRows.add([
      '${i + 1}',
      '${p.title} ${p.firstName} ${p.lastName} ( ${p.paxType.isEmpty ? 'A' : p.paxType[0]} )'
          '${dob == null ? '' : '\n${flightShortDate(dob)},'}'
          '${p.frequentFlyer.isEmpty ? '' : '\nFF: ${p.frequentFlyer}'}',
      shownRoutes.join('\n'),
      pnrRoutes.isEmpty
          ? 'Pending'
          : [
              for (final r in pnrRoutes)
                '${info!.pnrs[r]}'
                    '${info.ticketNumbers[r] == null ? '' : ' / ${info.ticketNumbers[r]}'}',
            ].join('\n'),
      [
        for (final _ in shownRoutes)
          '${asString(digPath(fd, ['bI', 'iB']), fallback: 'NA')} | '
              '${asString(digPath(fd, ['bI', 'cB']), fallback: 'NA')}',
      ].join('\n'),
      prefs.isEmpty
          ? 'NA'
          : [for (final items in prefs.values) items.join(' | ')].join('\n'),
      if (opts.passportInfo) p.passport,
    ]);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        // Agency header
        if (opts.agentDetails)
          pw.Align(
            alignment: pw.Alignment.topRight,
            child: pw.Container(
              width: 260,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(kTicketAgency.name, style: bold),
                  pw.Text('Email: ${kTicketAgency.email}', style: small),
                  pw.Text('Phone: ${kTicketAgency.phone}', style: small),
                  pw.Text('Address: ${kTicketAgency.address}', style: small),
                ],
              ),
            ),
          ),
        pw.SizedBox(height: 8),
        // Booking meta + PNRs
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Booking Time: ${_bookingStamp(data.createdAt)}',
                  style: small,
                ),
                pw.Text('Booking ID: ${data.bookingId}', style: small),
                pw.Text(
                  'Booking Status: ${data.onHold ? 'On Hold' : 'Confirmed'}',
                  style: bold,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: printed.isEmpty
                  ? [
                      pw.Text('Pending', style: bold),
                      pw.Text('Airline PNR', style: small),
                    ]
                  : [
                      for (final p in printed) ...[
                        pw.Text('${data.carrierName}  ${p.code}', style: bold),
                        pw.Text('Airline PNR', style: small),
                      ],
                    ],
            ),
          ],
        ),

        bar(
          'Flight Detail',
          '*Please verify flight timings & terminal info with the airlines',
        ),
        table([
          'Flight',
          'Fare Type',
          'Class',
          if (opts.showRefundable) 'Type',
          'Departing',
          'Arriving',
          'Duration',
        ], flightRows),

        bar('Passenger Details'),
        table([
          'Sr.',
          'Name & FF',
          'Sector',
          'PNR & Ticket No.',
          'Baggage (Check-in | Cabin)',
          'Meal, Seat & Other Preference',
          if (opts.passportInfo) 'Document Id',
        ], paxRows),

        if (opts.showPrice) ...[
          bar('Fare Details'),
          table(
            const ['Item', 'Amount'],
            [
              ['Base Price', _money(sum('BF'))],
              [
                'Airline Taxes and Fees',
                '${taxParts.isEmpty ? '' : '(${taxParts.entries.map((e) => '${e.key}${e.value.round()}').join(' ')}) '}'
                    '${_money(taxTotal)}',
              ],
              ['Management Fee', _money(mgmtFee)],
              ['Meal/ Seat/Baggage/ Misc Charges', _money(data.addOnTotal)],
              if (opts.gst) ['Management Fee GST', _money(mgmtGst)],
              ['Total Price', _money(grandTotal)],
            ],
          ),
        ],

        if (opts.showContact) ...[
          bar('Contact Details'),
          pw.Text(
            'Email: ${data.contactEmail.isEmpty ? '-' : data.contactEmail}',
            style: small,
          ),
          pw.Text(
            'Mobile: ${data.contactPhone.isEmpty ? '-' : data.contactPhone}',
            style: small,
          ),
        ],

        if (opts.gst && data.gstNumber.isNotEmpty) ...[
          bar('GST Details'),
          pw.Text('${data.gstCompany} - ${data.gstNumber}', style: small),
          if (data.gstAddress.isNotEmpty)
            pw.Text(data.gstAddress, style: small),
        ],

        if (opts.agentNotes && data.agentNote.isNotEmpty) ...[
          bar('Agent Notes'),
          pw.Text(data.agentNote, style: small),
        ],

        bar('Important Information'),
        for (var i = 0; i < kFlightImportantInfo.length; i++)
          pw.Text('${i + 1}. ${kFlightImportantInfo[i]}', style: small),
        if (data.carrierLink != null)
          pw.Text(
            '${kFlightImportantInfo.length + 1}. Please read the Conditions of '
            'Carriage as directed by ${data.carrierName}: ${data.carrierLink}',
            style: small,
          ),

        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'X  The items are Dangerous Goods and are not permitted to be '
                'carried as Hand/Check-in Baggage',
                style: bold,
              ),
              pw.Text(kDangerousGoods.join(' · '), style: small),
              pw.SizedBox(height: 4),
              pw.Text('OK  Items allowed only in Hand Baggage', style: bold),
              pw.Text(kHandBaggageOnly.join(' · '), style: small),
            ],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}
