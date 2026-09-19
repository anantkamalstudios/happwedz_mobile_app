/// One insurance policy — the web's `InsuranceBookingDetailsPage.jsx`
/// (`/honeymoon/insurance/booking/:bookingId`) with its
/// `InsuranceCancellationModal.jsx`.
///
/// ```
/// load      POST tripsafe/booking-details → InsuranceBookingDetails
/// hero      "Booking Confirmed" (SUCCESS) or "Booking <status>", id, created
/// plan      label, cover · region, insurer and partners, amount, travel
///           dates, region, active from, four benefits + "View all"
/// people    name, age · gender, email, mobile, passport, pincode,
///           policy id, nominee
/// summary   status, total paid, email, contact
/// actions   Download Policy Receipt (SUCCESS) · Book another plan ·
///           Cancel this booking (SUCCESS, plan + product known)
/// cancel    pick travellers → Step 1 raise → Step 2 confirm with the
///           amendment id (pre-filled, editable) → reload
/// ```
///
/// Opened straight after booking ([justBooked]) and from My Trips.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/honeymoon_models.dart';
import '../../models/insurance_models.dart';
import '../booking/booking_widgets.dart';
import '../widgets/honeymoon_widgets.dart';
import '../honeymoon_home_page.dart' show openInsuranceSearch;
import '../widgets/insurance_benefits_sheet.dart';

class InsuranceBookingDetailPage extends StatefulWidget {
  const InsuranceBookingDetailPage({
    super.key,
    required this.api,
    required this.bookingId,
    this.justBooked = false,
  });

  final HoneymoonApi api;
  final String bookingId;

  /// Reached from the booking form: Back returns to the start rather than to
  /// a spent form.
  final bool justBooked;

  @override
  State<InsuranceBookingDetailPage> createState() =>
      _InsuranceBookingDetailPageState();
}

class _InsuranceBookingDetailPageState
    extends State<InsuranceBookingDetailPage> {
  InsuranceBookingDetails? _details;
  bool _loading = true;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await widget.api.fetchInsuranceBooking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message.isEmpty
            ? 'Could not load booking details'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to fetch booking details';
      });
    }
  }

  Future<void> _downloadPolicy() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final path = await widget.api.downloadInsurancePolicy(widget.bookingId);
      final opened = await OpenFilex.open(path);
      if (!mounted) return;
      if (opened.type != ResultType.done) {
        AppSnackbar.success(context, 'Saved to your device as a PDF.');
      }
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.message.isEmpty
              ? 'Unable to download insurance policy receipt'
              : e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Unable to download insurance policy receipt',
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // void _bookAnother() =>
  //     Navigator.of(context).popUntil((route) => route.isFirst);
  /// The web sends you to `/honeymoon/insurance`; popping to the first route
  /// left the Honeymoon section altogether.
  void _bookAnother() => openInsuranceSearch(context);

  Future<void> _cancel() async {
    final details = _details;
    if (details == null) return;
    final done = await AppBottomSheet.show<bool>(
      context,
      title: 'Cancel insurance booking',
      isDismissible: false,
      child: _CancellationSheet(api: widget.api, details: details),
    );
    if (done == true && mounted) await _load();
  }

  /// A plan-shaped view of the booked product, for the benefits sheet.
  InsurancePlan _asPlan(InsuranceBookingDetails d) => InsurancePlan(
    planId: d.planId,
    productId: d.productId,
    name: d.planLabel,
    insurer: d.insurer,
    coverageAmount: d.coverageAmount,
    regionName: d.regionName,
    price: d.amount,
    partners: d.partners,
    benefits: d.benefits,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.justBooked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _bookAnother();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          elevated: true,
          title: 'Insurance booking',
          onBack: widget.justBooked ? _bookAnother : null,
        ),
        body: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoader(),
                    const SizedBox(height: AppSpacing.md),
                    Text('Loading booking details...', style: AppText.bodySm),
                  ],
                ),
              )
            : _error != null || _details == null
            ? ErrorState(
                title: 'Booking not found',
                message: _error ?? 'Booking not found',
                onRetry: _load,
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _body(_details!),
              ),
      ),
    );
  }

  Widget _body(InsuranceBookingDetails d) {
    final success = d.isSuccess;
    final status = insuranceStatusOf(d.orderStatus);
    final preview = d.benefits.take(4).map((b) => b.name).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        AppCard(
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: success ? AppColors.successDark : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Booking ${success ? 'Confirmed' : (d.orderStatus.isEmpty ? '—' : d.orderStatus)}',
                      style: AppText.sectionTitle,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Booking ID: ${d.bookingId.isEmpty ? widget.bookingId : d.bookingId}',
                            style: AppText.bodySm,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: d.bookingId.isEmpty
                                    ? widget.bookingId
                                    : d.bookingId,
                              ),
                            );
                            AppSnackbar.info(context, 'Booking ID copied.');
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: AppSpacing.xs),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (d.createdOn != null)
                      Text(
                        formatTripDateTime(d.createdOn),
                        style: AppText.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Plan details',
          icon: Icons.shield_outlined,
          children: [
            Text(d.planLabel, style: AppText.cardTitle),
            Text(
              [
                d.coverageAmount,
                d.regionName,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (d.insurer.isNotEmpty) MetaChip(label: d.insurer),
                for (final p in d.partners) MetaChip(label: p),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              d.amount > 0 ? formatHoneymoonAmount(d.amount) : '—',
              style: AppText.price,
            ),
            const SizedBox(height: AppSpacing.sm),
            DetailRow(
              label: 'Travel dates',
              value:
                  '${d.startDate == null ? '—' : formatTripDate(d.startDate)} – '
                  '${d.endDate == null ? '—' : formatTripDate(d.endDate)}',
            ),
            DetailRow(
              label: 'Region',
              value: d.regionName.isEmpty ? '—' : d.regionName,
            ),
            if (d.activeFrom != null)
              DetailRow(
                label: 'Active from',
                value: formatTripDate(d.activeFrom),
              ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final name in preview)
                Text('• $name', style: AppText.bodySm),
            ],
            if (d.benefits.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: PremiumButton.text(
                  label: 'View all ${d.benefits.length} benefits',
                  size: PremiumButtonSize.small,
                  onPressed: () =>
                      showInsuranceBenefitsSheet(context, _asPlan(d)),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Travellers',
          icon: Icons.people_outline_rounded,
          children: [
            for (var i = 0; i < d.travellers.length; i++) ...[
              if (i > 0)
                const Divider(height: AppSpacing.xl, color: AppColors.divider),
              _TravellerBlock(traveller: d.travellers[i]),
            ],
            if (d.travellers.isEmpty) Text('—', style: AppText.bodySm),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Order summary',
          icon: Icons.receipt_long_outlined,
          children: [
            Row(
              children: [
                Expanded(child: Text('Status', style: AppText.caption)),
                _StatusPill(status: status, raw: d.orderStatus),
              ],
            ),
            DetailRow(
              label: 'Total paid',
              value: d.amount > 0 ? formatHoneymoonAmount(d.amount) : '—',
            ),
            if (d.emails.isNotEmpty)
              DetailRow(label: 'Email', value: d.emails.first),
            if (d.contacts.isNotEmpty)
              DetailRow(label: 'Contact', value: d.contacts.first),
            const SizedBox(height: AppSpacing.md),
            if (success)
              PremiumButton(
                label: _downloading
                    ? 'Preparing PDF...'
                    : 'Download Policy Receipt',
                icon: Icons.download_rounded,
                isLoading: _downloading,
                onPressed: _downloadPolicy,
              ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton.outlined(
              label: 'Book another plan',
              onPressed: _bookAnother,
            ),
            if (d.canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              PremiumButton.outlined(
                label: 'Cancel this booking',
                icon: Icons.block_rounded,
                onPressed: _cancel,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// `₹1,234.56` — the details page prints paise, as the web's does.
String formatHoneymoonAmount(double v) {
  final fixed = v.toStringAsFixed(2);
  final whole = formatPrice(double.parse(fixed.split('.').first), symbol: '');
  final paise = fixed.split('.').last;
  return paise == '00' ? '₹$whole' : '₹$whole.$paise';
}

class _TravellerBlock extends StatelessWidget {
  const _TravellerBlock({required this.traveller});

  final InsuredTraveller traveller;

  @override
  Widget build(BuildContext context) {
    final t = traveller;
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: AppText.bodySm)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.name.isEmpty ? '—' : t.name, style: AppText.bodyStrong),
        Text(
          [
            if (t.age > 0) '${t.age} yrs',
            if (t.gender.isNotEmpty) t.gender,
          ].join(' · '),
          style: AppText.caption,
        ),
        line(Icons.mail_outline_rounded, t.email.isEmpty ? '—' : t.email),
        line(Icons.phone_outlined, t.mobile.isEmpty ? '—' : t.mobile),
        line(
          Icons.badge_outlined,
          'Passport: ${t.passport.isEmpty ? '—' : t.passport}',
        ),
        line(
          Icons.place_outlined,
          'Pincode: ${t.pincode.isEmpty ? '—' : t.pincode}',
        ),
        if (t.policyId.isNotEmpty)
          line(Icons.shield_outlined, 'Policy ID: ${t.policyId}'),
        if (t.nominee.isNotEmpty)
          line(Icons.people_outline_rounded, 'Nominee: ${t.nominee}'),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.raw});

  final InsuranceStatus status;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.key) {
      InsuranceStatusKey.confirmed => AppColors.successDark,
      InsuranceStatusKey.pending => AppColors.warning,
      InsuranceStatusKey.cancelled ||
      InsuranceStatusKey.failed => AppColors.error,
      InsuranceStatusKey.unknown => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        raw.isEmpty ? status.label : raw,
        style: AppText.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cancellation — InsuranceCancellationModal.jsx
// ---------------------------------------------------------------------------

enum _CancelStep { choose, confirm, done }

/// "Cancellation is a two-step process: raise amendment, then confirm
/// cancellation." Pops `true` once confirmed.
class _CancellationSheet extends StatefulWidget {
  const _CancellationSheet({required this.api, required this.details});

  final HoneymoonApi api;
  final InsuranceBookingDetails details;

  @override
  State<_CancellationSheet> createState() => _CancellationSheetState();
}

class _CancellationSheetState extends State<_CancellationSheet> {
  _CancelStep _step = _CancelStep.choose;
  late final Set<String> _selected = {
    for (final t in widget.details.travellers) t.id,
  };
  final _amendmentId = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amendmentId.dispose();
    super.dispose();
  }

  List<String> get _ids => _selected.isNotEmpty
      ? _selected.toList()
      : [for (final t in widget.details.travellers) t.id];

  Map<String, dynamic> get _payload =>
      HoneymoonApi.buildInsuranceCancellationPayload(
        bookingId: widget.details.bookingId,
        planId: widget.details.planId,
        productId: widget.details.productId,
        travellerIds: _ids,
      );

  bool get _allSelected =>
      widget.details.travellers.every((t) => _selected.contains(t.id));

  Future<void> _raise() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await widget.api.raiseInsuranceCancellation(_payload);
      if (!mounted) return;
      setState(() {
        _amendmentId.text = id;
        _step = _CancelStep.confirm;
      });
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = e.message.isEmpty ? 'Raise amendment failed' : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final id = _amendmentId.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter amendment ID from the raise step');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.confirmInsuranceCancellation(
        payload: _payload,
        amendmentId: id,
      );
      if (!mounted) return;
      setState(() => _step = _CancelStep.done);
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message.isEmpty
              ? 'Confirm cancellation failed'
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.details;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_step == _CancelStep.choose) ...[
          InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.warning_amber_rounded,
            message:
                'Cancellation is a two-step process: raise amendment, then '
                'confirm cancellation. Booking ID: ${d.bookingId}',
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Select travellers to cancel', style: AppText.caption),
          for (final t in d.travellers)
            CheckboxListTile.adaptive(
              value: _selected.contains(t.id),
              onChanged: (_) => setState(() {
                if (!_selected.remove(t.id)) _selected.add(t.id);
              }),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                '${t.name} (ID ${t.id})'
                '${t.policyId.isEmpty ? '' : ' · Policy ${t.policyId}'}',
                style: AppText.bodySm,
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() {
                if (_allSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll([for (final t in d.travellers) t.id]);
                }
              }),
              child: Text(_allSelected ? 'Deselect all' : 'Select all'),
            ),
          ),
        ],
        if (_step == _CancelStep.confirm) ...[
          Text('Step 2 of 2', style: AppText.labelSm),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Amendment raised. Confirm cancellation with the amendment ID '
            'below.',
            style: AppText.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _amendmentId,
            label: 'Amendment ID',
            hint: 'e.g. 170000743562',
          ),
        ],
        if (_step == _CancelStep.done) ...[
          const Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: AppColors.successDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cancellation confirmed',
            style: AppText.cardTitle,
            textAlign: TextAlign.center,
          ),
          Text(
            'Booking ${d.bookingId} has been cancelled.',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _error!,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        switch (_step) {
          _CancelStep.choose => Row(
            children: [
              Expanded(
                child: PremiumButton.outlined(
                  label: 'Close',
                  size: PremiumButtonSize.medium,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumButton(
                  label: _loading ? 'Raising…' : 'Step 1: Raise cancellation',
                  size: PremiumButtonSize.medium,
                  isLoading: _loading,
                  onPressed: _loading || _ids.isEmpty ? null : _raise,
                ),
              ),
            ],
          ),
          _CancelStep.confirm => Row(
            children: [
              Expanded(
                child: PremiumButton.outlined(
                  label: 'Back',
                  size: PremiumButtonSize.medium,
                  onPressed: _loading
                      ? null
                      : () => setState(() => _step = _CancelStep.choose),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumButton(
                  label: _loading
                      ? 'Confirming…'
                      : 'Step 2: Confirm cancellation',
                  size: PremiumButtonSize.medium,
                  isLoading: _loading,
                  onPressed: _loading ? null : _confirm,
                ),
              ),
            ],
          ),
          _CancelStep.done => PremiumButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context, true),
          ),
        },
      ],
    );
  }
}
