/// The screen every Honeymoon booking funnel ends on.
///
/// One screen serves all four products because the traveller's questions are
/// the same whichever they bought: *did it work, what is my reference, what
/// happens next, and where do I find it again*. Only the wording and the
/// summary rows differ, so those are passed in.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../models/booking_models.dart';
import '../widgets/honeymoon_widgets.dart';
import 'booking_widgets.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({
    super.key,
    required this.outcome,
    required this.summaryTitle,
    this.summarySubtitle = '',
    this.details = const [],
    this.nextSteps = const [],
    this.onViewBookings,
    this.onDone,
  });

  final BookingOutcome outcome;

  /// The headline of the summary card — the route, the hotel, the plan.
  final String summaryTitle;
  final String summarySubtitle;

  /// Label/value rows describing what was booked.
  final List<DetailRow> details;

  /// What happens next, in the order it happens.
  final List<({String title, String body})> nextSteps;

  final VoidCallback? onViewBookings;

  /// Where "Done" goes. Defaults to popping back to the honeymoon home.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final held = outcome.onHold;
    final pending = outcome.isAwaitingSupplier;

    return PopScope(
      // A confirmed booking must not be left by swiping back into a dead
      // checkout — the only ways out are the two explicit actions below.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: held ? 'Fare held' : 'Booking confirmed',
          showBack: false,
          actions: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _leave(context),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _Hero(outcome: outcome),
              const SizedBox(height: AppSpacing.lg),

              if (held)
                const InfoBanner(
                  tone: InfoTone.warning,
                  icon: Icons.hourglass_bottom_rounded,
                  message:
                      'This fare is held, not ticketed. Complete the payment '
                      'before the airline\'s deadline or the seats are released.',
                )
              else if (pending)
                const InfoBanner(
                  tone: InfoTone.info,
                  message:
                      'Your payment went through and we are waiting on the '
                      'final confirmation from our travel partner. You will get '
                      'an email as soon as it lands.',
                ),
              if (held || pending) const SizedBox(height: AppSpacing.lg),

              _ReferenceCard(reference: outcome.reference),
              const SizedBox(height: AppSpacing.lg),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summaryTitle,
                      style: AppText.sectionTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (summarySubtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(summarySubtitle, style: AppText.cardSubtitle),
                    ],
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: AppSpacing.lg),
                      ...details,
                    ],
                    if (outcome.amountPaid > 0) ...[
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Amount paid', style: AppText.body),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatPrice(outcome.amountPaid),
                            style: AppText.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (nextSteps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _NextSteps(steps: nextSteps),
              ],

              const SizedBox(height: AppSpacing.xl),
              if (onViewBookings != null) ...[
                PremiumButton(
                  label: 'View my trips',
                  icon: Icons.confirmation_number_outlined,
                  onPressed: onViewBookings,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PremiumButton.outlined(
                label: 'Done',
                onPressed: () => _leave(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _leave(BuildContext context) {
    if (onDone != null) {
      onDone!();
      return;
    }
    // Unwind the whole checkout: the traveller should land back where they
    // started, not in the middle of a form they can no longer submit.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.outcome});

  final BookingOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final held = outcome.onHold;
    final pending = outcome.isAwaitingSupplier;

    final (icon, tint, headline, body) = held
        ? (
            Icons.lock_clock_rounded,
            AppColors.warning,
            'Your fare is held',
            'We have blocked these seats for you.',
          )
        : pending
        ? (
            Icons.schedule_rounded,
            AppColors.info,
            'Payment received',
            'We are confirming your booking with our partner.',
          )
        : (
            Icons.check_circle_rounded,
            AppColors.successDark,
            'You are all set',
            'Your ${outcome.product.label.toLowerCase()} is confirmed.',
          );

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: tint),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(headline, style: AppText.displaySm, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          outcome.message.isNotEmpty ? outcome.message : body,
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The booking reference, sized to be read out loud and tappable to copy —
/// this is the one string a traveller will need again.
class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    if (reference.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Booking reference', style: AppText.caption),
                const SizedBox(height: AppSpacing.xxs),
                SelectableText(
                  reference,
                  style: AppText.sectionTitle.copyWith(letterSpacing: 0.4),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Copy reference',
            icon: const Icon(Icons.copy_rounded, size: 19),
            color: AppColors.primary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reference));
              if (context.mounted) {
                AppSnackbar.success(context, 'Reference copied');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NextSteps extends StatelessWidget {
  const _NextSteps({required this.steps});

  final List<({String title, String body})> steps;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('What happens next', style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.blush,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (i != steps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.divider,
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(steps[i].title, style: AppText.bodyStrong),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(steps[i].body, style: AppText.bodySm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
