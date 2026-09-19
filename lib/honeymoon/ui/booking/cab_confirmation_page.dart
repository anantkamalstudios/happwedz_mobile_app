/// The car-rental success view — `CabBookingPage.jsx` once a booking exists.
///
/// Built from the booking the server returns: the booking detail that
/// `payment/verify` echoes (`bookingDetails[0]`, or the reconciled one from
/// "Check payment status"), falling back to the create-booking response and
/// finally to the quote — the same precedence as the web.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/cab_models.dart';
import '../../models/honeymoon_models.dart';
import '../bookings/my_trips_page.dart';
import '../honeymoon_home_page.dart' show openHoneymoonService;
import '../widgets/honeymoon_widgets.dart';
import 'booking_widgets.dart' show DetailRow;

class CabConfirmationPage extends StatelessWidget {
  const CabConfirmationPage({
    super.key,
    required this.api,
    required this.booking,
    required this.quote,
    required this.query,
    this.detail,
    this.paymentRef = '',
    this.paid = true,
  });

  final HoneymoonApi api;

  /// `POST tripjack-cabs/book`'s answer.
  final CabCreatedBooking booking;

  /// The post-payment order view, when the server sent one.
  final CabBookingDetail? detail;

  /// Razorpay's payment id, as verify reports it.
  final String paymentRef;
  final bool paid;
  final CabQuote quote;
  final CabSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final vehicle = firstNonEmpty([
      d?.vehicleClass,
      booking.vehicleClass,
      quote.label,
      quote.vehicleName,
    ]);
    final passenger = firstNonEmpty([d?.passengerName, booking.passengerName]);
    final pickup = d?.pickupDate ?? booking.pickupDate ?? query.pickupAt;
    final source = firstNonEmpty([
      d?.source,
      booking.source,
      query.originLabel,
    ]);
    final destination = firstNonEmpty([
      d?.destination,
      booking.destination,
      query.destinationLabel,
    ]);
    final distance = firstNonEmpty([d?.distance, booking.distance]);
    final bookingStatus = firstNonEmpty([d?.status, booking.status]);
    final paymentStatus = firstNonEmpty([
      d?.paymentStatus,
      paid ? 'SUCCESS' : '',
      booking.paymentStatus,
    ]);
    final total = d?.grossAmount ?? booking.totalPrice;
    final tracking = firstNonEmpty([d?.trackingLink, booking.trackingLink]);
    final helpline = d?.helpline ?? '';
    final rideStatus = (d?.rideStatus ?? '').replaceAll('_', ' ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) openHoneymoonService(context, HoneymoonService.carRental);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: paid ? 'Booking confirmed' : 'Booking created',
          elevated: true,
          onBack: () =>
              openHoneymoonService(context, HoneymoonService.carRental),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: paid ? AppColors.successDark : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              paid ? 'Booking confirmed' : 'Booking created',
              style: AppText.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    'Booking ID: ${booking.id}',
                    style: AppText.bodySm,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy booking ID',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: booking.id));
                    AppSnackbar.success(context, 'Booking ID copied');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DetailRow(label: 'Vehicle', value: vehicle),
                  DetailRow(
                    label: 'Passenger',
                    value: passenger.isEmpty ? '—' : passenger,
                  ),
                  DetailRow(label: 'Pick-up', value: formatCabDateTime(pickup)),
                  DetailRow(label: 'Route', value: '$source → $destination'),
                  if (distance.isNotEmpty)
                    DetailRow(label: 'Distance', value: distance),
                  DetailRow(
                    label: 'Booking status',
                    value: bookingStatus.isEmpty ? '—' : bookingStatus,
                  ),
                  DetailRow(
                    label: 'Payment status',
                    value: paymentStatus.isEmpty ? '—' : paymentStatus,
                  ),
                  if (paymentRef.isNotEmpty)
                    DetailRow(label: 'Payment reference', value: paymentRef),
                  if (rideStatus.isNotEmpty)
                    DetailRow(label: 'Ride status', value: rideStatus),
                  const Divider(
                    height: AppSpacing.lg,
                    color: AppColors.divider,
                  ),
                  DetailRow(
                    label: 'Total paid',
                    value: formatPrice(total > 0 ? total : quote.price),
                  ),
                ],
              ),
            ),
            if (helpline.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                helpline,
                style: AppText.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
            if (tracking.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              PremiumButton.outlined(
                label: 'Track your ride',
                icon: Icons.near_me_rounded,
                onPressed: () async {
                  final uri = Uri.tryParse(tracking);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (context.mounted) {
                      AppSnackbar.error(
                        context,
                        'Could not open the tracking link.',
                      );
                    }
                  }
                },
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PremiumButton(
              label: 'View my bookings',
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.popUntil((route) => route.isFirst);
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => MyTripsPage(
                      api: api,
                      initialProduct: TravelProduct.cab,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton.outlined(
              label: 'Book another cab',
              onPressed: () =>
                  openHoneymoonService(context, HoneymoonService.carRental),
            ),
          ],
        ),
      ),
    );
  }
}
