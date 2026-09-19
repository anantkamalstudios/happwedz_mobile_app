/// Step two of the flight funnel: who is travelling, and where the ticket
/// goes.
///
/// Every rule enforced here comes from the fare's own review conditions rather
/// than being hardcoded — the same route can require a passport on one fare
/// and not on another, airlines cap name lengths differently, and the age
/// bands are assessed on the travel date, not today.
///
/// On a phone the web client's stacked panels become collapsible cards: one
/// traveller is open at a time, the rest collapse to a filled-in summary line,
/// so a party of four is still a navigable scroll rather than four screens of
/// identical fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/gst_profile_store.dart';
import '../../data/honeymoon_api.dart';
import '../../data/traveller_store.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../widgets/honeymoon_widgets.dart';
import 'booking_widgets.dart';

class FlightTravellerStep extends StatefulWidget {
  const FlightTravellerStep({
    super.key,
    required this.api,
    required this.trip,
    required this.conditions,
    required this.travellers,
    required this.contact,
    required this.emergency,
    this.initialGst,
    this.initialNote = '',
  });

  final HoneymoonApi api;
  final FlightTripContext trip;
  final FareConditions conditions;

  /// Mutated in place: the parent owns these and reads them back after
  /// [FlightTravellerStepState.validateAndCommit] returns true, which is what
  /// makes stepping back and forth non-destructive.
  final List<TravellerInput> travellers;
  final ContactDetails contact;
  final EmergencyContact emergency;

  /// What was entered last time this step was left, so Back from the review
  /// restores the GST panel and the notes rather than a blank form — the web
  /// seeds its form from the same kind of snapshot (`saved`).
  final GstDetails? initialGst;
  final String initialNote;

  @override
  State<FlightTravellerStep> createState() => FlightTravellerStepState();
}

class FlightTravellerStepState extends State<FlightTravellerStep> {
  // Field errors, keyed `${travellerIndex}_${field}` for travellers and by a
  // bare name for the shared sections.
  final Map<String, String> _errors = {};

  late final List<TextEditingController> _firstNames;
  late final List<TextEditingController> _lastNames;
  late final List<TextEditingController> _passports;
  late final List<TextEditingController> _documentIds;
  late final List<TextEditingController> _nationalities;
  late final List<TextEditingController> _ffNumbers;

  /// "Add this to My Travellers List", per panel. Kept per row rather than
  /// per name: every panel starts blank, so a name-based key would tie all
  /// of them together.
  final Map<int, bool> _saveTraveller = {};
  Set<String> _suppressed = <String>{};

  /// "Add notes (Optional)" — sent as the booking's `remarks`.
  final _note = TextEditingController();
  bool _noteOpen = false;

  final _mobile = TextEditingController();
  final _email = TextEditingController();

  final _emergencyName = TextEditingController();
  final _emergencyEmail = TextEditingController();
  final _emergencyMobile = TextEditingController();

  bool _gstEnabled = false;
  bool _gstSave = true;
  final _gstCompany = TextEditingController();
  final _gstNumber = TextEditingController();
  final _gstEmail = TextEditingController();
  final _gstPhone = TextEditingController();
  final _gstAddress = TextEditingController();
  List<GstProfile> _gstHistory = const [];

  /// Which traveller panel is open. One at a time keeps the scroll short.
  int _openIndex = 0;

  /// Anchors for scroll-to-first-error.
  final Map<String, GlobalKey> _anchors = {};

  List<Map<String, dynamic>> _savedTravellers = const [];

  @override
  void initState() {
    super.initState();

    _firstNames = [
      for (final t in widget.travellers)
        TextEditingController(text: t.firstName),
    ];
    _lastNames = [
      for (final t in widget.travellers)
        TextEditingController(text: t.lastName),
    ];
    _passports = [
      for (final t in widget.travellers)
        TextEditingController(text: t.passportNumber),
    ];
    _documentIds = [
      for (final t in widget.travellers)
        TextEditingController(text: t.documentId),
    ];
    _nationalities = [
      for (final t in widget.travellers)
        TextEditingController(text: t.nationality),
    ];
    _ffNumbers = [
      for (final t in widget.travellers)
        TextEditingController(text: t.frequentFlyerNumber),
    ];
    // The first airline the fare accepts is preselected, as on the web.
    final ffAirlines = widget.conditions.frequentFlyerAirlines;
    for (final t in widget.travellers) {
      if (t.frequentFlyerAirline.isEmpty && ffAirlines.isNotEmpty) {
        t.frequentFlyerAirline = ffAirlines.first;
      }
    }

    final gst = widget.initialGst;
    if (gst != null) {
      _gstEnabled = true;
      _gstCompany.text = gst.companyName;
      _gstNumber.text = gst.gstNumber;
      _gstEmail.text = gst.companyEmail;
      _gstPhone.text = gst.phone;
      _gstAddress.text = gst.address;
    }
    _note.text = widget.initialNote;
    _noteOpen = widget.initialNote.isNotEmpty;

    _mobile.text = widget.contact.mobile;
    _email.text = widget.contact.email;
    _emergencyName.text = widget.emergency.name;
    _emergencyEmail.text = widget.emergency.email;
    _emergencyMobile.text = widget.emergency.mobile;

    _loadSavedTravellers();
    _loadGstHistory();
    _loadSuppressed();
  }

  Future<void> _loadSuppressed() async {
    final hidden = await TravellerSuppressionStore.load();
    if (mounted) setState(() => _suppressed = hidden);
  }

  /// The booking's `remarks` — empty when no note was written.
  String get note => _note.text.trim();

  @override
  void dispose() {
    for (final c in [
      ..._firstNames,
      ..._lastNames,
      ..._passports,
      ..._documentIds,
      ..._nationalities,
      ..._ffNumbers,
      _note,
      _mobile,
      _email,
      _emergencyName,
      _emergencyEmail,
      _emergencyMobile,
      _gstCompany,
      _gstNumber,
      _gstEmail,
      _gstPhone,
      _gstAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// People this account has booked for before. A failure is silent — the
  /// picker simply does not appear, because a convenience lookup must never
  /// block a booking.
  Future<void> _loadSavedTravellers() async {
    final saved = await widget.api.fetchSavedTravellers();
    if (!mounted || saved.isEmpty) return;
    setState(() => _savedTravellers = saved);
  }

  /// Locally-saved GST profiles, most recent first. See [GstProfileStore].
  Future<void> _loadGstHistory() async {
    final history = await GstProfileStore.loadHistory();
    if (!mounted || history.isEmpty) return;
    setState(() => _gstHistory = history);
  }

  void _applyGstFromHistory(GstProfile profile) {
    setState(() {
      _gstEnabled = true;
      _gstCompany.text = profile.companyName;
      _gstNumber.text = profile.gstNumber;
      _gstEmail.text = profile.companyEmail;
      _gstPhone.text = profile.phone;
      _gstAddress.text = profile.address;
    });
  }

  void _clearGst() {
    setState(() {
      _gstCompany.clear();
      _gstNumber.clear();
      _gstEmail.clear();
      _gstPhone.clear();
      _gstAddress.clear();
    });
  }

  GlobalKey _anchorFor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  void _clearError(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  /// Validates every field, writes the values back into the models the parent
  /// owns, and reports whether the step may be left.
  ///
  /// Committing only on success is deliberate: a half-valid form must not
  /// leave partial data in the payload the review screen then displays.
  bool validateAndCommit() {
    final errors = <String, String>{};
    final c = widget.conditions;

    for (var i = 0; i < widget.travellers.length; i++) {
      final t = widget.travellers[i];
      final first = _firstNames[i].text.trim();
      final last = _lastNames[i].text.trim();

      if (first.isEmpty) {
        errors['${i}_firstName'] = 'First name is required';
      } else if (first.length < c.firstNameMin) {
        errors['${i}_firstName'] =
            'Needs at least ${c.firstNameMin} character'
            '${c.firstNameMin > 1 ? 's' : ''}';
      } else if (first.length > c.firstNameMax) {
        errors['${i}_firstName'] =
            'This airline allows up to ${c.firstNameMax} characters';
      }

      if (last.isEmpty) {
        errors['${i}_lastName'] = 'Last name is required';
      } else if (last.length < c.lastNameMin) {
        errors['${i}_lastName'] =
            'Needs at least ${c.lastNameMin} character'
            '${c.lastNameMin > 1 ? 's' : ''}';
      } else if (last.length > c.lastNameMax) {
        errors['${i}_lastName'] =
            'This airline allows up to ${c.lastNameMax} characters';
      }

      // Some carriers cap the full name too, not just each field.
      if (c.combinedNameMax > 0 &&
          first.isNotEmpty &&
          last.isNotEmpty &&
          '$first $last'.length > c.combinedNameMax) {
        errors['${i}_lastName'] =
            'Full name must be ${c.combinedNameMax} characters or fewer';
      }

      if (c.dobRequiredFor(t.type) && t.dob == null) {
        errors['${i}_dob'] = 'Date of birth is required';
      } else if (t.dob != null) {
        final ageError = _ageError(t.dob!, t.type);
        if (ageError != null) errors['${i}_dob'] = ageError;
      }

      if (c.passportRequired) {
        if (_passports[i].text.trim().isEmpty) {
          errors['${i}_passport'] = 'Passport number is required';
        }
        if (t.passportExpiry == null) {
          errors['${i}_passportExpiry'] = 'Passport expiry is required';
        } else {
          final now = DateTime.now();
          final sixMonths = DateTime(now.year, now.month + 6, now.day);
          if (t.passportExpiry!.isBefore(sixMonths)) {
            errors['${i}_passportExpiry'] =
                'Passport must be valid for at least 6 more months';
          }
        }
        if (c.passportIssueDateRequired && t.passportIssueDate == null) {
          errors['${i}_passportIssue'] = 'Passport issue date is required';
        }
        // `pNat` is the two-letter country code the passport was issued by.
        final nationality = _nationalities[i].text.trim();
        if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(nationality)) {
          errors['${i}_nationality'] = 'Use the 2-letter country code, e.g. IN';
        }
      }

      if (c.docIdMandatory && _documentIds[i].text.trim().isEmpty) {
        errors['${i}_documentId'] = 'Document ID is required for this fare';
      }
    }

    if (_mobile.text.trim().length < 10) {
      errors['mobile'] = 'Enter a valid mobile number';
    }
    if (!_email.text.trim().contains('@') || _email.text.trim().length < 5) {
      errors['email'] = 'Enter a valid email address';
    }

    if (c.emergencyContactRequired) {
      if (_emergencyName.text.trim().isEmpty) {
        errors['emergencyName'] = 'Emergency contact name is required';
      }
      if (!_emergencyEmail.text.trim().contains('@')) {
        errors['emergencyEmail'] = 'Enter a valid email address';
      }
      if (_emergencyMobile.text.trim().length < 10) {
        errors['emergencyMobile'] = 'Enter a valid mobile number';
      }
    }

    if (_gstEnabled) {
      if (_gstCompany.text.trim().isEmpty) {
        errors['gstCompany'] = 'Company name is required';
      }
      if (_gstNumber.text.trim().length != 15) {
        errors['gstNumber'] = 'A GST number is 15 characters';
      }
      if (!_gstEmail.text.trim().contains('@')) {
        errors['gstEmail'] = 'Enter a valid email address';
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      // Open the first traveller with a problem so the error is on screen
      // rather than hidden inside a collapsed panel.
      final firstBad = errors.keys
          .map((k) => int.tryParse(k.split('_').first))
          .whereType<int>()
          .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      if (firstBad != null) _openIndex = firstBad;
    });

    if (errors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstError(),
      );
      return false;
    }

    _commit();
    return true;
  }

  void _scrollToFirstError() {
    for (final key in _errors.keys) {
      final anchor = _anchors[key];
      final ctx = anchor?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          alignment: 0.15,
        );
        return;
      }
    }
  }

  void _commit() {
    for (var i = 0; i < widget.travellers.length; i++) {
      widget.travellers[i]
        ..firstName = _firstNames[i].text.trim()
        ..lastName = _lastNames[i].text.trim()
        ..passportNumber = _passports[i].text.trim()
        ..documentId = _documentIds[i].text.trim()
        ..nationality = _nationalities[i].text.trim().isEmpty
            ? 'IN'
            : _nationalities[i].text.trim().toUpperCase()
        ..frequentFlyerNumber = widget.travellers[i].type == PaxType.infant
            ? ''
            : _ffNumbers[i].text.trim().toUpperCase();
    }

    // Names exist by now, so each row's "My Travellers List" choice is
    // recorded against the key the picker looks people up by.
    final hidden = Set<String>.from(_suppressed);
    for (var i = 0; i < widget.travellers.length; i++) {
      final t = widget.travellers[i];
      final key = travellerKey(
        t.firstName,
        t.lastName,
        t.dob == null ? '' : apiDate(t.dob!),
      );
      if (_saveTraveller[i] == false) {
        hidden.add(key);
      } else {
        hidden.remove(key);
      }
    }
    _suppressed = hidden;
    TravellerSuppressionStore.save(hidden);
    widget.contact
      ..mobile = _mobile.text.trim()
      ..email = _email.text.trim();
    widget.emergency
      ..name = _emergencyName.text.trim()
      ..email = _emergencyEmail.text.trim()
      ..mobile = _emergencyMobile.text.trim();

    // Mirrors `persistGst()` in PassengerDetails.jsx, called right before the
    // web hands off to the review step. Fire-and-forget: a convenience save
    // must never block the booking it's attached to.
    final gst = gstIfEnabled;
    if (gst != null && _gstSave && gst.gstNumber.isNotEmpty) {
      GstProfileStore.save(
        GstProfile(
          gstNumber: gst.gstNumber,
          companyName: gst.companyName,
          companyEmail: gst.companyEmail,
          phone: gst.phone,
          address: gst.address,
        ),
      );
    }
  }

  /// Non-null when the traveller filled in GST details.
  GstDetails? get gstIfEnabled => _gstEnabled
      ? (GstDetails()
          ..companyName = _gstCompany.text.trim()
          ..gstNumber = _gstNumber.text.trim().toUpperCase()
          ..companyEmail = _gstEmail.text.trim()
          ..phone = _gstPhone.text.trim()
          ..address = _gstAddress.text.trim())
      : null;

  String? _ageError(DateTime dob, PaxType type) {
    final bounds = dobBoundsFor(type, widget.trip.departure);
    if (bounds.max != null && dob.isAfter(bounds.max!)) {
      final max = formatTripDate(bounds.max);
      return switch (type) {
        PaxType.adult =>
          'An adult must be 12 or older on the travel date (born on or '
              'before $max)',
        PaxType.child =>
          'A child must be at least 2 on the travel date (born on or before '
              '$max)',
        PaxType.infant => 'Infant date of birth cannot be in the future',
      };
    }
    if (bounds.min != null && dob.isBefore(bounds.min!)) {
      final min = formatTripDate(bounds.min!.subtract(const Duration(days: 1)));
      return switch (type) {
        PaxType.child =>
          'A child must be under 12 on the travel date (born after $min)',
        PaxType.infant =>
          'An infant must be under 2 on the travel date (born after $min)',
        PaxType.adult => null,
      };
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------------------

  Future<void> _pickDob(int index) async {
    final t = widget.travellers[index];
    final bounds = dobBoundsFor(t.type, widget.trip.departure);
    final first = bounds.min ?? DateTime(1920);
    final last = bounds.max ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      // Opening on the latest permitted date puts an adult's picker in the
      // right decade instead of on today, which is never a valid answer.
      initialDate: t.dob ?? last,
      firstDate: first,
      lastDate: last,
      helpText: 'Date of birth',
    );
    if (picked == null) return;
    setState(() {
      t.dob = picked;
      _errors.remove('${index}_dob');
    });
  }

  Future<void> _pickPassportDate(int index, {required bool isExpiry}) async {
    final t = widget.travellers[index];
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry
          ? (t.passportExpiry ?? now.add(const Duration(days: 365)))
          : (t.passportIssueDate ?? now),
      firstDate: isExpiry ? now : DateTime(1990),
      lastDate: isExpiry ? DateTime(now.year + 20) : now,
      helpText: isExpiry ? 'Passport expiry' : 'Passport issue date',
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        t.passportExpiry = picked;
        _errors.remove('${index}_passportExpiry');
      } else {
        t.passportIssueDate = picked;
        _errors.remove('${index}_passportIssue');
      }
    });
  }

  Future<void> _pickTitle(int index) async {
    final t = widget.travellers[index];
    final picked = await showOptionSheet<String>(
      context,
      title: 'Title',
      options: t.type.titles,
      labelOf: (v) => v,
      selected: t.title,
    );
    if (picked != null) setState(() => t.title = picked);
  }

  /// Fills a panel from someone this account has booked for before.
  /// Saved travellers this panel may be filled from: the right passenger type
  /// (an infant's row cannot take an adult's details) and not hidden by an
  /// earlier "My Travellers List" untick.
  List<Map<String, dynamic>> _savedFor(PaxType type) => [
    for (final t in _savedTravellers)
      if ((asString(readKey(t, 'pt')).isEmpty ||
              asString(readKey(t, 'pt')).toUpperCase() == type.code) &&
          !_suppressed.contains(_savedKeyOf(t)))
        t,
  ];

  static String _savedKeyOf(Map<String, dynamic> t) {
    final key = asString(readKey(t, 'key'));
    if (key.isNotEmpty) return key.toUpperCase();
    return travellerKey(
      asString(readKey(t, 'fN')),
      asString(readKey(t, 'lN')),
      asString(readKey(t, 'dob')),
    );
  }

  Future<void> _pickFfAirline(int index) async {
    final t = widget.travellers[index];
    final picked = await showOptionSheet<String>(
      context,
      title: 'Frequent flyer airline',
      options: widget.conditions.frequentFlyerAirlines,
      labelOf: (v) => v,
      selected: t.frequentFlyerAirline,
    );
    if (picked != null) setState(() => t.frequentFlyerAirline = picked);
  }

  Future<void> _pickSavedTraveller(int index) async {
    final options = _savedFor(widget.travellers[index].type);
    if (options.isEmpty) {
      AppSnackbar.info(
        context,
        'No saved ${widget.travellers[index].type.code.toLowerCase()} '
        'travellers yet — everyone you book for will appear here.',
      );
      return;
    }
    final picked = await showOptionSheet<Map<String, dynamic>>(
      context,
      title: 'Previous travellers',
      options: options,
      labelOf: (t) =>
          '${asString(readKey(t, 'ti'))} ${asString(readKey(t, 'fN'))} '
                  '${asString(readKey(t, 'lN'))}'
              .trim(),
      subtitleOf: (t) {
        final passport = asString(readKey(t, 'pNum'));
        final dob = asString(readKey(t, 'dob'));
        return [
          if (dob.isNotEmpty) dob,
          if (passport.isNotEmpty) passport,
        ].join(' · ');
      },
    );
    if (picked == null) return;

    setState(() {
      final t = widget.travellers[index];
      final title = asString(readKey(picked, 'ti'));
      if (title.isNotEmpty && t.type.titles.contains(title)) t.title = title;

      _firstNames[index].text = asString(readKey(picked, 'fN'));
      _lastNames[index].text = asString(readKey(picked, 'lN'));
      _passports[index].text = asString(readKey(picked, 'pNum'));
      t.dob = DateTime.tryParse(asString(readKey(picked, 'dob'))) ?? t.dob;
      t.passportExpiry =
          DateTime.tryParse(asString(readKey(picked, 'eD'))) ??
          t.passportExpiry;
      t.passportIssueDate =
          DateTime.tryParse(asString(readKey(picked, 'pid'))) ??
          t.passportIssueDate;
      final nationality = asString(readKey(picked, 'pNat'));
      if (nationality.isNotEmpty) {
        t.nationality = nationality;
        _nationalities[index].text = nationality;
      }

      for (final field in const [
        'firstName',
        'lastName',
        'dob',
        'passport',
        'passportExpiry',
      ]) {
        _errors.remove('${index}_$field');
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = widget.conditions;

    return ListView(
      key: const ValueKey('step-travellers'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        InfoBanner(
          icon: Icons.person_pin_circle_outlined,
          message: c.passportRequired
              ? 'Enter names exactly as they appear on each passport. '
                    'Airlines charge to correct a name after ticketing.'
              : 'Enter names exactly as they appear on the ID each traveller '
                    'will carry. Airlines charge to correct a name after '
                    'ticketing.',
        ),
        const SizedBox(height: AppSpacing.lg),

        for (var i = 0; i < widget.travellers.length; i++) ...[
          _TravellerCard(
            index: i,
            label: widget.trip.labelFor(i),
            traveller: widget.travellers[i],
            conditions: c,
            firstName: _firstNames[i],
            lastName: _lastNames[i],
            passport: _passports[i],
            documentId: _documentIds[i],
            nationality: _nationalities[i],
            ffNumber: _ffNumbers[i],
            docIdApplicable: widget.trip.docIdApplicable(c),
            onPickFfAirline: () => _pickFfAirline(i),
            saveTraveller: _saveTraveller[i] ?? true,
            onSaveTravellerChanged: (v) =>
                setState(() => _saveTraveller[i] = v),
            errors: _errors,
            anchorFor: _anchorFor,
            isOpen: _openIndex == i,
            onToggle: () =>
                setState(() => _openIndex = _openIndex == i ? -1 : i),
            onPickTitle: () => _pickTitle(i),
            onPickDob: () => _pickDob(i),
            onPickExpiry: () => _pickPassportDate(i, isExpiry: true),
            onPickIssueDate: () => _pickPassportDate(i, isExpiry: false),
            onClearError: (field) =>
                setState(() => _errors.remove('${i}_$field')),
            onUseSaved: _savedTravellers.isEmpty
                ? null
                : () => _pickSavedTraveller(i),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        FormSection(
          title: 'Contact details',
          subtitle: 'Your ticket and any airline updates go here',
          icon: Icons.alternate_email_rounded,
          children: [
            KeyedSubtree(
              key: _anchorFor('mobile'),
              child: PhoneField(
                controller: _mobile,
                countryCode: widget.contact.countryCode,
                errorText: _errors['mobile'],
                onChanged: (_) => _clearError('mobile'),
                onCountryCodeChanged: (code) =>
                    setState(() => widget.contact.countryCode = code),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            KeyedSubtree(
              key: _anchorFor('email'),
              child: AppTextField(
                controller: _email,
                label: 'Email address',
                required: true,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: _errors['email'],
                onChanged: (_) => _clearError('email'),
              ),
            ),
          ],
        ),

        if (c.emergencyContactRequired) ...[
          const SizedBox(height: AppSpacing.md),
          FormSection(
            title: 'Emergency contact',
            subtitle: 'Required by the airline on this fare',
            icon: Icons.emergency_outlined,
            children: [
              KeyedSubtree(
                key: _anchorFor('emergencyName'),
                child: AppTextField(
                  controller: _emergencyName,
                  label: 'Full name',
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  errorText: _errors['emergencyName'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('emergencyEmail'),
                child: AppTextField(
                  controller: _emergencyEmail,
                  label: 'Email address',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _errors['emergencyEmail'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('emergencyMobile'),
                child: AppTextField(
                  controller: _emergencyMobile,
                  label: 'Mobile number',
                  required: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _errors['emergencyMobile'],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Notes',
          subtitle: 'Optional',
          icon: Icons.sticky_note_2_outlined,
          trailing: Switch.adaptive(
            value: _noteOpen,
            onChanged: (v) => setState(() => _noteOpen = v),
          ),
          children: _noteOpen
              ? [
                  AppTextField(
                    controller: _note,
                    label: 'Add notes',
                    maxLength: 200,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Text(
                    '*These notes are for agent reference only, no action '
                    'will be taken against this.',
                    style: AppText.caption,
                  ),
                ]
              : const [SizedBox.shrink()],
        ),

        const SizedBox(height: AppSpacing.md),
        _GstSection(
          enabled: _gstEnabled,
          company: _gstCompany,
          number: _gstNumber,
          email: _gstEmail,
          phone: _gstPhone,
          address: _gstAddress,
          save: _gstSave,
          history: _gstHistory,
          errors: _errors,
          anchorFor: _anchorFor,
          onToggle: (v) => setState(() => _gstEnabled = v),
          onSaveToggle: (v) => setState(() => _gstSave = v),
          onApplyHistory: _applyGstFromHistory,
          onClear: _clearGst,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One traveller
// ---------------------------------------------------------------------------

class _TravellerCard extends StatelessWidget {
  const _TravellerCard({
    required this.index,
    required this.label,
    required this.traveller,
    required this.conditions,
    required this.firstName,
    required this.lastName,
    required this.passport,
    required this.documentId,
    required this.nationality,
    required this.ffNumber,
    required this.docIdApplicable,
    required this.onPickFfAirline,
    required this.saveTraveller,
    required this.onSaveTravellerChanged,
    required this.errors,
    required this.anchorFor,
    required this.isOpen,
    required this.onToggle,
    required this.onPickTitle,
    required this.onPickDob,
    required this.onPickExpiry,
    required this.onPickIssueDate,
    required this.onClearError,
    required this.onUseSaved,
  });

  final int index;
  final String label;
  final TravellerInput traveller;
  final FareConditions conditions;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController passport;
  final TextEditingController documentId;
  final TextEditingController nationality;
  final TextEditingController ffNumber;

  /// Fare says so (`dc.ida`) or the search was a student / senior fare.
  final bool docIdApplicable;
  final VoidCallback onPickFfAirline;
  final bool saveTraveller;
  final ValueChanged<bool> onSaveTravellerChanged;
  final Map<String, String> errors;
  final GlobalKey Function(String) anchorFor;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onPickTitle;
  final VoidCallback onPickDob;
  final VoidCallback onPickExpiry;
  final VoidCallback onPickIssueDate;
  final ValueChanged<String> onClearError;
  final VoidCallback? onUseSaved;

  String? _err(String field) => errors['${index}_$field'];

  bool get _hasError => errors.keys.any((k) => k.startsWith('${index}_'));

  /// What the collapsed panel shows.
  ///
  /// Read from the controllers, not from [traveller]: the model is only
  /// written on a successful submit, so reading it collapsed a fully typed-in
  /// panel down to a bare "Mr".
  String get _summary {
    final name = '${firstName.text.trim()} ${lastName.text.trim()}'.trim();
    return name.isEmpty ? '' : '${traveller.title} $name';
  }

  @override
  Widget build(BuildContext context) {
    final filled = _summary.isNotEmpty;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadii.rLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _hasError
                          ? AppColors.error.withValues(alpha: 0.10)
                          : AppColors.blush,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _hasError
                          ? Icons.error_outline_rounded
                          : traveller.type == PaxType.infant
                          ? Icons.child_friendly_outlined
                          : Icons.person_outline_rounded,
                      size: 18,
                      color: _hasError ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppText.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _hasError
                              ? 'Some details need attention'
                              : filled
                              ? _summary
                              : 'Tap to add details',
                          style: AppText.caption.copyWith(
                            color: _hasError ? AppColors.error : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: AppMotion.fast,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppMotion.normal,
            sizeCurve: AppMotion.standard,
            crossFadeState: isOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: _fields(context),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onUseSaved != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: PremiumButton.text(
              label: 'Use a previous traveller',
              icon: Icons.history_rounded,
              size: PremiumButtonSize.small,
              onPressed: onUseSaved,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Title is narrow and the name is long — a fixed-width title beside a
        // flexible name keeps both usable down to 320 px.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              // Narrow enough that the name field beside it stays usable at
              // 320 px, wide enough for "Master".
              width: 88,
              child: PickerField(
                label: 'Title',
                value: traveller.title,
                onTap: onPickTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KeyedSubtree(
                key: anchorFor('${index}_firstName'),
                child: AppTextField(
                  controller: firstName,
                  label: 'First name',
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: conditions.firstNameMax,
                  errorText: _err('firstName'),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .'-]")),
                  ],
                  onChanged: (_) => onClearError('firstName'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        KeyedSubtree(
          key: anchorFor('${index}_lastName'),
          child: AppTextField(
            controller: lastName,
            label: 'Last name',
            required: true,
            textCapitalization: TextCapitalization.words,
            maxLength: conditions.lastNameMax,
            errorText: _err('lastName'),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .'-]")),
            ],
            onChanged: (_) => onClearError('lastName'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        KeyedSubtree(
          key: anchorFor('${index}_dob'),
          child: PickerField(
            label: 'Date of birth',
            required: conditions.dobRequiredFor(traveller.type),
            value: traveller.dob == null ? '' : formatTripDate(traveller.dob),
            hint: 'Select date',
            icon: Icons.calendar_today_rounded,
            errorText: _err('dob'),
            onTap: onPickDob,
          ),
        ),

        if (conditions.passportRequired) ...[
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: anchorFor('${index}_nationality'),
            child: AppTextField(
              controller: nationality,
              label: 'Nationality',
              required: true,
              hint: 'IN',
              helperText: 'Two-letter country code of the passport',
              textCapitalization: TextCapitalization.characters,
              errorText: _err('nationality'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (_) => onClearError('nationality'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: anchorFor('${index}_passport'),
            child: AppTextField(
              controller: passport,
              label: 'Passport number',
              required: true,
              textCapitalization: TextCapitalization.characters,
              errorText: _err('passport'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onChanged: (_) => onClearError('passport'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: anchorFor('${index}_passportExpiry'),
            child: PickerField(
              label: 'Passport expiry',
              required: true,
              value: traveller.passportExpiry == null
                  ? ''
                  : formatTripDate(traveller.passportExpiry),
              hint: 'Select date',
              icon: Icons.event_outlined,
              errorText: _err('passportExpiry'),
              onTap: onPickExpiry,
            ),
          ),
          if (conditions.passportIssueDateRequired) ...[
            const SizedBox(height: AppSpacing.md),
            KeyedSubtree(
              key: anchorFor('${index}_passportIssue'),
              child: PickerField(
                label: 'Passport issue date',
                required: true,
                value: traveller.passportIssueDate == null
                    ? ''
                    : formatTripDate(traveller.passportIssueDate),
                hint: 'Select date',
                icon: Icons.event_available_outlined,
                errorText: _err('passportIssue'),
                onTap: onPickIssueDate,
              ),
            ),
          ],
        ],

        if (docIdApplicable) ...[
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: anchorFor('${index}_documentId'),
            child: AppTextField(
              controller: documentId,
              label: conditions.docIdMandatory
                  ? 'Document ID'
                  : 'Document ID (Student/Senior)',
              required: conditions.docIdMandatory,
              helperText: 'Student or senior-citizen fares need a document ID',
              errorText: _err('documentId'),
              onChanged: (_) => onClearError('documentId'),
            ),
          ),
        ],

        // Only offered for carriers this fare says accept a number, and never
        // for an infant.
        if (conditions.frequentFlyerAirlines.isNotEmpty &&
            traveller.type != PaxType.infant) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Frequent flyer (optional)', style: AppText.formLabel),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: PickerField(
                  label: 'Airline',
                  value: traveller.frequentFlyerAirline,
                  onTap: onPickFfAirline,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: ffNumber,
                  label: 'FF number',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile.adaptive(
          value: saveTraveller,
          onChanged: (v) => onSaveTravellerChanged(v ?? true),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: Text('Add this to My Travellers List', style: AppText.bodySm),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// GST
// ---------------------------------------------------------------------------

class _GstSection extends StatelessWidget {
  const _GstSection({
    required this.enabled,
    required this.company,
    required this.number,
    required this.email,
    required this.phone,
    required this.address,
    required this.save,
    required this.history,
    required this.errors,
    required this.anchorFor,
    required this.onToggle,
    required this.onSaveToggle,
    required this.onApplyHistory,
    required this.onClear,
  });

  final bool enabled;
  final TextEditingController company;
  final TextEditingController number;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController address;
  final bool save;
  final List<GstProfile> history;
  final Map<String, String> errors;
  final GlobalKey Function(String) anchorFor;
  final ValueChanged<bool> onToggle;
  final ValueChanged<bool> onSaveToggle;
  final ValueChanged<GstProfile> onApplyHistory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'GST details',
      subtitle: 'Optional — for a business invoice',
      icon: Icons.receipt_long_outlined,
      trailing: Switch.adaptive(value: enabled, onChanged: onToggle),
      children: enabled
          ? [
              if (history.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<GstProfile>(
                        key: const ValueKey('gstHistoryPicker'),
                        // Always shows the hint — picking an entry applies it
                        // and resets to the hint, matching the source's
                        // `<select value="">` "Select from History" control.
                        initialValue: null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select from history',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final g in history)
                            DropdownMenuItem(
                              value: g,
                              child: Text(
                                '${g.gstNumber} — ${g.companyName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (g) {
                          if (g != null) onApplyHistory(g);
                        },
                      ),
                    ),
                    TextButton(onPressed: onClear, child: const Text('Clear')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              KeyedSubtree(
                key: anchorFor('gstNumber'),
                child: AppTextField(
                  controller: number,
                  label: 'GST number',
                  required: true,
                  maxLength: 15,
                  textCapitalization: TextCapitalization.characters,
                  errorText: errors['gstNumber'],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: anchorFor('gstCompany'),
                child: AppTextField(
                  controller: company,
                  label: 'Registered company name',
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  errorText: errors['gstCompany'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: anchorFor('gstEmail'),
                child: AppTextField(
                  controller: email,
                  label: 'Registered email',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  errorText: errors['gstEmail'],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: phone,
                label: 'Registered phone',
                required: false,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: address,
                label: 'Registered address',
                required: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile.adaptive(
                value: save,
                onChanged: (v) => onSaveToggle(v ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save GST details for next time'),
              ),
            ]
          : const [SizedBox.shrink()],
    );
  }
}
