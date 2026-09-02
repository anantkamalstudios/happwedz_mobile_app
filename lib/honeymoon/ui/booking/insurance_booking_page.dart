/// The travel-insurance booking funnel.
///
/// ```
/// review (confirm premium, open booking id)
///   └─ traveller + nominee details  →  issue policy  →  confirmed
/// ```
///
/// Unlike the other three products this one takes no card payment in the app:
/// the insurer settles against the agent wallet (`paymentMedium: WALLET`), so
/// there is no gateway step between the form and the policy.
///
/// Every insured person needs their own nominee, passport and pincode, which
/// on a phone means a lot of fields. They are grouped into one collapsible
/// card per traveller, open one at a time, so the party stays navigable.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../widgets/honeymoon_widgets.dart';
import '../bookings/my_trips_page.dart';
import 'booking_confirmation_page.dart';
import 'booking_widgets.dart';

class InsuranceBookingPage extends StatefulWidget {
  const InsuranceBookingPage({
    super.key,
    required this.api,
    required this.plan,
    required this.regionLabel,
    required this.start,
    required this.end,
    required this.travellerAges,
  });

  final HoneymoonApi api;
  final InsurancePlan plan;
  final String regionLabel;
  final DateTime start;
  final DateTime end;

  /// One age per insured person — the insurer prices on age, not head count.
  final List<int> travellerAges;

  @override
  State<InsuranceBookingPage> createState() => _InsuranceBookingPageState();
}

class _InsuranceBookingPageState extends State<InsuranceBookingPage> {
  // --- Review session ------------------------------------------------------

  String? _bookingId;
  double _premium = 0;
  bool _loadingReview = true;
  Object? _reviewError;

  // --- Form ----------------------------------------------------------------

  late final List<InsuranceTravellerInput> _travellers = [
    for (var i = 0; i < widget.travellerAges.length; i++)
      InsuranceTravellerInput(id: i + 1, age: widget.travellerAges[i]),
  ];

  late final List<_TravellerControllers> _controllers = [
    for (var _ in _travellers) _TravellerControllers(),
  ];

  final Map<String, String> _errors = {};
  final Map<String, GlobalKey> _anchors = {};

  int _openIndex = 0;
  bool _agreed = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _premium = widget.plan.price;
    _openReview();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey _anchorFor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  /// Confirms the premium with the insurer and opens a booking id.
  ///
  /// The reviewed premium is authoritative and can differ from the quote the
  /// search returned, so the total shown from here on is this one.
  Future<void> _openReview() async {
    setState(() {
      _loadingReview = true;
      _reviewError = null;
    });
    try {
      final review = await widget.api.reviewInsurancePlan(widget.plan);
      if (!mounted) return;
      setState(() {
        _bookingId = review.bookingId;
        _premium = review.price > 0 ? review.price : widget.plan.price;
        _loadingReview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = e;
      });
    }
  }

  FareBreakdown get _fare => FareBreakdown(
    lines: [
      FareLine(
        widget.plan.name,
        _premium,
        detail:
            '${_travellers.length} traveller'
            '${_travellers.length == 1 ? '' : 's'}',
      ),
    ],
    total: _premium,
  );

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  bool _validate() {
    final errors = <String, String>{};

    for (var i = 0; i < _travellers.length; i++) {
      final c = _controllers[i];

      if (c.fullName.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).isEmpty) {
        errors['${i}_fullName'] = 'Full name is required';
      }
      if (c.passport.text.trim().isEmpty) {
        errors['${i}_passport'] = 'Passport number is required';
      }
      if (c.mobile.text.trim().length < 10) {
        errors['${i}_mobile'] = 'Enter a valid mobile number';
      }
      if (!c.email.text.trim().contains('@')) {
        errors['${i}_email'] = 'Enter a valid email address';
      }
      if (c.pincode.text.trim().length < 4) {
        errors['${i}_pincode'] = 'Enter a valid pincode';
      }
      if (c.nomineeName.text.trim().isEmpty) {
        errors['${i}_nomineeName'] = 'Nominee name is required';
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      final firstBad = errors.keys
          .map((k) => int.tryParse(k.split('_').first))
          .whereType<int>()
          .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      if (firstBad != null) _openIndex = firstBad;
    });

    if (errors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _anchors[errors.keys.first]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            alignment: 0.15,
          );
        }
      });
      return false;
    }

    for (var i = 0; i < _travellers.length; i++) {
      final c = _controllers[i];
      _travellers[i]
        ..fullName = c.fullName.text.trim()
        ..passport = c.passport.text.trim()
        ..mobile = c.mobile.text.trim()
        ..email = c.email.text.trim()
        ..pincode = c.pincode.text.trim()
        ..nomineeName = c.nomineeName.text.trim();
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // Booking
  // -------------------------------------------------------------------------

  Future<void> _book() async {
    final bookingId = _bookingId;
    if (bookingId == null || _submitting) return;

    FocusScope.of(context).unfocus();
    if (!_validate()) {
      AppSnackbar.error(context, 'Please complete the highlighted details.');
      return;
    }
    if (!_agreed) {
      setState(
        () => _submitError =
            'Please confirm you have read the policy terms before continuing.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final lead = _travellers.first;

    try {
      final outcome = await widget.api.bookInsurance({
        'bookingId': bookingId,
        'paymentInfos': [
          {'paymentMedium': 'WALLET', 'amount': _premium},
        ],
        'pli': [
          {
            'plid': widget.plan.planId,
            'pi': [
              {
                'pid': widget.plan.productId,
                'iti': [for (final t in _travellers) t.toJson()],
              },
            ],
          },
        ],
        'deliveryInfo': {
          'emails': [lead.email],
          'contacts': [lead.mobile],
        },
      });
      if (!mounted) return;
      _goToConfirmation(outcome);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToConfirmation(BookingOutcome outcome) {
    // Captured before the replace: this State's context is gone by the time
    // the confirmation screen's actions fire.
    final navigator = Navigator.of(context);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationPage(
          outcome: outcome,
          onViewBookings: () {
            // Unwind the checkout first so "back" from My trips lands where
            // the traveller started, not inside a spent booking form.
            navigator.popUntil((route) => route.isFirst);
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const MyTripsPage(
                  initialProduct: TravelProduct.insurance,
                ),
              ),
            );
          },
          summaryTitle: widget.plan.name,
          summarySubtitle: widget.plan.insurerLabel,
          details: [
            DetailRow(
              label: 'Destination',
              value: widget.regionLabel,
              icon: Icons.public_rounded,
            ),
            DetailRow(
              label: 'Cover from',
              value: formatTripDate(widget.start),
              icon: Icons.event_rounded,
            ),
            DetailRow(
              label: 'Cover to',
              value: formatTripDate(widget.end),
              icon: Icons.event_busy_rounded,
            ),
            DetailRow(
              label: 'Insured',
              value:
                  '${_travellers.length} traveller'
                  '${_travellers.length == 1 ? '' : 's'}',
              icon: Icons.people_outline_rounded,
            ),
            if (widget.plan.coverageAmount.isNotEmpty)
              DetailRow(
                label: 'Sum insured',
                value: widget.plan.coverageAmount,
                icon: Icons.shield_outlined,
              ),
          ],
          nextSteps: const [
            (
              title: 'Policy document',
              body:
                  'Your certificate is emailed to the address on the booking, '
                  'usually within a few minutes.',
            ),
            (
              title: 'Carry it with you',
              body:
                  'Some countries ask to see proof of cover at immigration — '
                  'keep a copy on your phone.',
            ),
            (
              title: 'Making a claim',
              body:
                  'Contact the insurer\'s 24×7 assistance line on the '
                  'certificate as soon as anything happens.',
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Traveller details',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.regionLabel} · '
              '${formatTripDate(widget.start)} – ${formatTripDate(widget.end)}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: AsyncView(
        isLoading: _loadingReview,
        error: _reviewError,
        onRetry: _openReview,
        errorTitle: 'We could not confirm that plan',
        child: _form(),
      ),
      bottomNavigationBar: _loadingReview || _reviewError != null
          ? null
          : BookingActionBar(
              fare: _fare,
              priceLabel: 'Premium',
              actionLabel: 'Buy policy',
              isLoading: _submitting,
              onAction: _book,
              onShowBreakdown: () => showFareBreakdownSheet(
                context,
                _fare,
                title: 'Premium',
                footnote:
                    'The premium covers every traveller listed on this policy '
                    'for the dates shown.',
              ),
            ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (_submitError != null) ...[
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _submitError!,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        _PlanSummary(plan: widget.plan, premium: _premium),
        const SizedBox(height: AppSpacing.md),

        const InfoBanner(
          icon: Icons.badge_outlined,
          message:
              'Enter each name exactly as it appears on that traveller\'s '
              'passport. A mismatch can invalidate a claim.',
        ),
        const SizedBox(height: AppSpacing.lg),

        for (var i = 0; i < _travellers.length; i++) ...[
          _InsuredCard(
            index: i,
            traveller: _travellers[i],
            controllers: _controllers[i],
            errors: _errors,
            anchorFor: _anchorFor,
            isOpen: _openIndex == i,
            onToggle: () =>
                setState(() => _openIndex = _openIndex == i ? -1 : i),
            onClearError: (field) =>
                setState(() => _errors.remove('${i}_$field')),
            onGenderChanged: (g) => setState(() => _travellers[i].gender = g),
            onRelationChanged: (r) =>
                setState(() => _travellers[i].nomineeRelation = r),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        AppCard(
          child: InkWell(
            onTap: () => setState(() => _agreed = !_agreed),
            borderRadius: AppRadii.rMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'I confirm the details above are correct and I have read '
                      'the policy wording, exclusions and claim process.',
                      style: AppText.bodySm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const TermsNotice(product: 'insurer'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// Controllers for one insured traveller, kept together so the card stays a
/// stateless widget and disposal cannot be forgotten field by field.
class _TravellerControllers {
  final fullName = TextEditingController();
  final passport = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final pincode = TextEditingController();
  final nomineeName = TextEditingController(text: 'LEGAL HEIR');

  void dispose() {
    for (final c in [
      fullName,
      passport,
      mobile,
      email,
      pincode,
      nomineeName,
    ]) {
      c.dispose();
    }
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan, required this.premium});

  final InsurancePlan plan;
  final double premium;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: AppText.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plan.insurerLabel,
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.coverageTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in plan.coverageTags) MetaChip(label: tag),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InsuredCard extends StatelessWidget {
  const _InsuredCard({
    required this.index,
    required this.traveller,
    required this.controllers,
    required this.errors,
    required this.anchorFor,
    required this.isOpen,
    required this.onToggle,
    required this.onClearError,
    required this.onGenderChanged,
    required this.onRelationChanged,
  });

  final int index;
  final InsuranceTravellerInput traveller;
  final _TravellerControllers controllers;
  final Map<String, String> errors;
  final GlobalKey Function(String) anchorFor;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onClearError;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onRelationChanged;

  String? _err(String field) => errors['${index}_$field'];

  bool get _hasError => errors.keys.any((k) => k.startsWith('${index}_'));

  @override
  Widget build(BuildContext context) {
    final name = controllers.fullName.text.trim();

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
                          'Traveller ${index + 1} · ${traveller.age} yrs',
                          style: AppText.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _hasError
                              ? 'Some details need attention'
                              : name.isEmpty
                              ? 'Tap to add details'
                              : name,
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
        KeyedSubtree(
          key: anchorFor('${index}_fullName'),
          child: AppTextField(
            controller: controllers.fullName,
            label: 'Full name (as on passport)',
            required: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: _err('fullName'),
            onChanged: (_) => onClearError('fullName'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        PickerField(
          label: 'Gender',
          value: traveller.gender == 'F' ? 'Female' : 'Male',
          onTap: () async {
            final picked = await showOptionSheet<String>(
              context,
              title: 'Gender',
              options: const ['M', 'F'],
              labelOf: (v) => v == 'F' ? 'Female' : 'Male',
              selected: traveller.gender,
            );
            if (picked != null) onGenderChanged(picked);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        KeyedSubtree(
          key: anchorFor('${index}_passport'),
          child: AppTextField(
            controller: controllers.passport,
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
          key: anchorFor('${index}_mobile'),
          child: AppTextField(
            controller: controllers.mobile,
            label: 'Mobile number',
            required: true,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            errorText: _err('mobile'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onClearError('mobile'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        KeyedSubtree(
          key: anchorFor('${index}_email'),
          child: AppTextField(
            controller: controllers.email,
            label: 'Email address',
            required: true,
            keyboardType: TextInputType.emailAddress,
            errorText: _err('email'),
            onChanged: (_) => onClearError('email'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        KeyedSubtree(
          key: anchorFor('${index}_pincode'),
          child: AppTextField(
            controller: controllers.pincode,
            label: 'Pincode',
            required: true,
            keyboardType: TextInputType.number,
            maxLength: 10,
            errorText: _err('pincode'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onClearError('pincode'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Nominee', style: AppText.overline),
        const SizedBox(height: AppSpacing.sm),
        KeyedSubtree(
          key: anchorFor('${index}_nomineeName'),
          child: AppTextField(
            controller: controllers.nomineeName,
            label: 'Nominee name',
            required: true,
            textCapitalization: TextCapitalization.words,
            errorText: _err('nomineeName'),
            onChanged: (_) => onClearError('nomineeName'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PickerField(
          label: 'Relationship',
          value: traveller.nomineeRelation,
          onTap: () async {
            final picked = await showOptionSheet<String>(
              context,
              title: 'Relationship to nominee',
              options: kNomineeRelations,
              labelOf: (v) => v,
              selected: traveller.nomineeRelation,
            );
            if (picked != null) onRelationChanged(picked);
          },
        ),
      ],
    );
  }
}
