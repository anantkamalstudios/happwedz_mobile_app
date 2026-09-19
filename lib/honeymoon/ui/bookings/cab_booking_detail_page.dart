/// One cab booking from My Trips — `userDashboard/cabBookings/CabBookingDetail.jsx`.
///
/// ```
/// GET tripjack-cabs/invoice/:id/details   (by the invoice row's own id)
///   journey    pickup · dropoff · pickup time · distance
///   passenger  name · email · phone
///   pricing    base fare · taxes · total
///   status     booking · payment · booked on
///   invoice    number · Download Invoice PDF (GET tripjack-cabs/invoice/:orderId)
/// ```
///
/// The web has no cab cancellation, amendment or refund request, so neither
/// does this page.
library;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/cab_models.dart';
import '../booking/booking_widgets.dart' show DetailRow;
import '../widgets/honeymoon_widgets.dart' show formatPrice;

class CabBookingDetailPage extends StatefulWidget {
  const CabBookingDetailPage({
    super.key,
    this.api,
    required this.invoiceId,
    this.orderId = '',
  });

  /// Shared with the honeymoon screens when opened from My Trips; null when
  /// opened from the profile's My Bookings, in which case the page owns (and
  /// closes) its own client.
  final HoneymoonApi? api;

  /// The invoice row's `id` — what the details endpoint is keyed by.
  final String invoiceId;

  /// The row's Razorpay `orderId`, for the PDF while the detail loads (the
  /// detail's own `orderId` wins once it is in).
  final String orderId;

  @override
  State<CabBookingDetailPage> createState() => _CabBookingDetailPageState();
}

class _CabBookingDetailPageState extends State<CabBookingDetailPage> {
  late final HoneymoonApi _api = widget.api ?? HoneymoonApi();
  CabInvoiceDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.fetchCabInvoiceDetail(widget.invoiceId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message.isNotEmpty
            ? e.message
            : 'Could not load booking details';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load booking details';
      });
    }
  }

  Future<void> _downloadInvoice(CabInvoiceDetail d) async {
    final orderId = d.orderId.isNotEmpty ? d.orderId : widget.orderId;
    if (orderId.isEmpty || _downloading) return;
    setState(() => _downloading = true);
    try {
      final path = await _api.downloadCabInvoice(
        orderId,
        invoiceNumber: d.invoiceNumber,
      );
      await OpenFilex.open(path);
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.message.isNotEmpty ? e.message : 'Failed to download invoice',
        );
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Failed to download invoice');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  static String _when(DateTime? d) => d == null ? '—' : formatCabDateTime(d);
  static String _or(String v) => v.isEmpty ? '—' : v;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Booking Details', elevated: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: AppLoader());

    final d = _detail;
    if (_error != null || d == null) {
      return ErrorState(
        title: 'Error Loading Booking',
        message: _error ?? 'Booking not found',
        onRetry: _load,
      );
    }

    final orderId = d.orderId.isNotEmpty ? d.orderId : widget.orderId;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.local_taxi_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableText(
                  'Booking ID: ${_or(d.displayId)}',
                  style: AppText.bodyStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Journey Details',
            children: [
              DetailRow(
                label: 'Pickup Location',
                value: _or(d.pickupLocation),
                icon: Icons.trip_origin_rounded,
              ),
              DetailRow(
                label: 'Dropoff Location',
                value: _or(d.dropoffLocation),
                icon: Icons.place_rounded,
              ),
              DetailRow(
                label: 'Pickup Time',
                value: _when(d.pickupTime),
                icon: Icons.schedule_rounded,
              ),
              if (d.distance.isNotEmpty)
                DetailRow(label: 'Distance', value: d.distance),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Passenger Details',
            children: [
              DetailRow(
                label: 'Name',
                value: _or(d.passengerName),
                icon: Icons.person_outline_rounded,
              ),
              DetailRow(
                label: 'Email',
                value: _or(d.passengerEmail),
                icon: Icons.mail_outline_rounded,
              ),
              DetailRow(
                label: 'Phone',
                value: _or(d.passengerPhone),
                icon: Icons.phone_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Pricing',
            children: [
              DetailRow(label: 'Base Fare', value: formatPrice(d.baseFare)),
              DetailRow(label: 'Taxes', value: formatPrice(d.taxes)),
              const Divider(height: AppSpacing.lg, color: AppColors.divider),
              DetailRow(label: 'Total', value: formatPrice(d.total)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Status',
            children: [
              DetailRow(label: 'Booking Status', value: _or(d.bookingStatus)),
              DetailRow(label: 'Payment Status', value: _or(d.paymentStatus)),
              DetailRow(label: 'Booked On', value: _when(d.createdAt)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Invoice',
            children: [
              DetailRow(label: 'Invoice Number', value: _or(d.invoiceNumber)),
              if (orderId.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                PremiumButton(
                  label: _downloading
                      ? 'Downloading...'
                      : 'Download Invoice PDF',
                  icon: Icons.download_rounded,
                  isLoading: _downloading,
                  onPressed: () => _downloadInvoice(d),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}
