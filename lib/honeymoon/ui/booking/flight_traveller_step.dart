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
import '../../data/honeymoon_api.dart';
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

  final _mobile = TextEditingController();
  final _email = TextEditingController();

  final _emergencyName = TextEditingController();
  final _emergencyEmail = TextEditingController();
  final _emergencyMobile = TextEditingController();

  bool _gstEnabled = false;
  final _gstCompany = TextEditingController();
  final _gstNumber = TextEditingController();
  final _gstEmail = TextEditingController();

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
      for (final t in widget.travellers) TextEditingController(text: t.lastName),
    ];
    _passports = [
      for (final t in widget.travellers)
        TextEditingController(text: t.passportNumber),
    ];
    _documentIds = [
      for (final t in widget.travellers)
        TextEditingController(text: t.documentId),
    ];

    _mobile.text = widget.contact.mobile;
    _email.text = widget.contact.email;
    _emergencyName.text = widget.emergency.name;
    _emergencyEmail.text = widget.emergency.email;
    _emergencyMobile.text = widget.emergency.mobile;

    _loadSavedTravellers();
  }

  @override
  void dispose() {
    for (final c in [
      ..._firstNames,
      ..._lastNames,
      ..._passports,
      ..._documentIds,
      _mobile,
      _email,
      _emergencyName,
      _emergencyEmail,
      _emergencyMobile,
      _gstCompany,
      _gstNumber,
      _gstEmail,
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
          final sixMonths = DateTime.now().add(const Duration(days: 182));
          if (t.passportExpiry!.isBefore(sixMonths)) {
            errors['${i}_passportExpiry'] =
                'Passport must be valid for at least 6 more months';
          }
        }
        if (c.passportIssueDateRequired && t.passportIssueDate == null) {
          errors['${i}_passportIssue'] = 'Passport issue date is required';
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
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
        ..documentId = _documentIds[i].text.trim();
    }
    widget.contact
      ..mobile = _mobile.text.trim()
      ..email = _email.text.trim();
    widget.emergency
      ..name = _emergencyName.text.trim()
      ..email = _emergencyEmail.text.trim()
      ..mobile = _emergencyMobile.text.trim();
  }

  /// Non-null when the traveller filled in GST details.
  GstDetails? get gstIfEnabled => _gstEnabled
      ? (GstDetails()
          ..companyName = _gstCompany.text.trim()
          ..gstNumber = _gstNumber.text.trim().toUpperCase()
          ..companyEmail = _gstEmail.text.trim())
      : null;

  String? _ageError(DateTime dob, PaxType type) {
    final bounds = dobBoundsFor(type, widget.trip.departure);
    if (bounds.max != null && dob.isAfter(bounds.max!)) {
      return switch (type) {
        PaxType.adult =>
          'An adult must be 12 or older on the travel date',
        PaxType.child => 'A child must be at least 2 on the travel date',
        PaxType.infant => 'Date of birth cannot be in the future',
      };
    }
    if (bounds.min != null && dob.isBefore(bounds.min!)) {
      return switch (type) {
        PaxType.child => 'A child must be under 12 on the travel date',
        PaxType.infant => 'An infant must be under 2 on the travel date',
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
  Future<void> _pickSavedTraveller(int index) async {
    final picked = await showOptionSheet<Map<String, dynamic>>(
      context,
      title: 'Previous travellers',
      options: _savedTravellers,
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
          DateTime.tryParse(asString(readKey(picked, 'eD'))) ?? t.passportExpiry;
      final nationality = asString(readKey(picked, 'pNat'));
      if (nationality.isNotEmpty) t.nationality = nationality;

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
            errors: _errors,
            anchorFor: _anchorFor,
            isOpen: _openIndex == i,
            onToggle: () => setState(() => _openIndex = _openIndex == i ? -1 : i),
            onPickTitle: () => _pickTitle(i),
            onPickDob: () => _pickDob(i),
            onPickExpiry: () => _pickPassportDate(i, isExpiry: true),
            onPickIssueDate: () => _pickPassportDate(i, isExpiry: false),
            onClearError: (field) => setState(() => _errors.remove('${i}_$field')),
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
        _GstSection(
          enabled: _gstEnabled,
          company: _gstCompany,
          number: _gstNumber,
          email: _gstEmail,
          errors: _errors,
          anchorFor: _anchorFor,
          onToggle: (v) => setState(() => _gstEnabled = v),
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

        if (conditions.docIdApplicable) ...[
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: anchorFor('${index}_documentId'),
            child: AppTextField(
              controller: documentId,
              label: 'Document ID',
              required: conditions.docIdMandatory,
              helperText: 'Student or senior-citizen fares need a document ID',
              errorText: _err('documentId'),
              onChanged: (_) => onClearError('documentId'),
            ),
          ),
        ],
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
    required this.errors,
    required this.anchorFor,
    required this.onToggle,
  });

  final bool enabled;
  final TextEditingController company;
  final TextEditingController number;
  final TextEditingController email;
  final Map<String, String> errors;
  final GlobalKey Function(String) anchorFor;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'GST details',
      subtitle: 'Optional — for a business invoice',
      icon: Icons.receipt_long_outlined,
      trailing: Switch.adaptive(value: enabled, onChanged: onToggle),
      children: enabled
          ? [
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
                key: anchorFor('gstEmail'),
                child: AppTextField(
                  controller: email,
                  label: 'Company email',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  errorText: errors['gstEmail'],
                ),
              ),
            ]
          : const [SizedBox.shrink()],
    );
  }
}
