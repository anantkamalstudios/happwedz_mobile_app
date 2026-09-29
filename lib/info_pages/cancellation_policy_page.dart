// Native port of the website's /cancellation page (CancellationPolicy.jsx,
// live chunk CancellationPolicy-CmU4R9kl.js — identical text).

import 'package:flutter/material.dart';

import 'package:happy_wedz/core/core.dart';

import 'info_page_widgets.dart';

class CancellationPolicyPage extends StatelessWidget {
  const CancellationPolicyPage({super.key});

  static const String title = 'Cancellation Policy';
  static const String subtitle =
      'Understanding how cancellations and refunds work on Happywedz.';

  // Bootstrap text-success / text-warning / text-danger.
  static const Color _success = Color(0xFF198754);
  static const Color _warning = Color(0xFFB58100);
  static const Color _danger = Color(0xFFDC3545);

  @override
  Widget build(BuildContext context) {
    final muted = AppText.body.copyWith(color: AppColors.textSecondary);
    return InfoPageScaffold(
      title: title,
      subtitle: subtitle,
      children: [
        // Intro card
        AppCard(
          child: Text.rich(
            TextSpan(
              style: AppText.bodyLg.copyWith(color: AppColors.textSecondary),
              children: const [
                TextSpan(text: '"Because '),
                TextSpan(
                  text: 'Happywedz',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' is a platform and not a service provider, '
                      'cancellations and refunds depend entirely on the '
                      'individual vendor’s policies."',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        AppSpacing.h16,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heading(
                Icons.description_outlined,
                AppColors.primary,
                '1. Platform-Level Terms',
              ),
              for (final t in const [
                'Happywedz does not charge users for vendor bookings unless explicitly stated.',
                'Happywedz does not issue refunds for vendor-related payments.',
                'Refund requests must be directed to the vendor you booked.',
              ])
                _bullet(t),
              _divider(),
              _heading(
                Icons.storefront_outlined,
                _success,
                '2. Vendor-Level Policies',
              ),
              Text(
                'Vendors may define their own cancellation and refund rules. '
                'Common examples include:',
                style: muted,
              ),
              AppSpacing.h12,
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadii.rSm,
                ),
                child: Column(
                  children: [
                    _refundRow('Cancellation 60+ days before event',
                        'Partial or full refund', _success),
                    _refundRow('Cancellation 30–60 days before event',
                        'Limited refund', _warning),
                    _refundRow('Cancellation 0–30 days before event',
                        'No refund', _danger),
                    _refundRow('Customized / pre-production services',
                        'Non-refundable', _danger),
                    _refundRow('Advance booking fees', 'Often non-refundable',
                        _danger,
                        last: true),
                  ],
                ),
              ),
              _divider(),
              _heading(
                Icons.payments_outlined,
                _warning,
                '3. Payment Disputes',
              ),
              Text('Happywedz is not responsible for:', style: muted),
              AppSpacing.h12,
              for (final t in const [
                'Payment disputes',
                'Chargebacks',
                'Failed vendor commitments',
                'Refund delays',
              ])
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.rXs,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded, color: _danger, size: 18),
                      AppSpacing.w8,
                      Expanded(child: Text(t, style: AppText.body)),
                    ],
                  ),
                ),
              AppSpacing.h8,
              Text(
                'Users and vendors must resolve disputes directly. Happywedz '
                'may assist with communication at its discretion but is not '
                'obligated to mediate.',
                style: AppText.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              _divider(),
              _heading(Icons.block_rounded, _danger, '4. Vendor Cancellation'),
              Text('If a vendor cancels a booking, users should:', style: muted),
              AppSpacing.h12,
              for (final (i, t) in const [
                'Contact the vendor directly for a refund',
                'Review the vendor’s cancellation terms',
                'Report the issue to Happywedz for review',
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadii.rPill,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppText.labelSm.copyWith(color: Colors.white),
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(child: Text(t, style: AppText.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.h16,
        // Important notice (bootstrap alert-warning)
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3CD),
            borderRadius: AppRadii.rSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_rounded,
                size: 20,
                color: Color(0xFF664D03),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notice',
                      style: AppText.bodyStrong.copyWith(
                        color: const Color(0xFF664D03),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.h4,
                    Text(
                      'Happywedz acts only as an intermediary platform. Users '
                      'are advised to review vendor cancellation and refund '
                      'policies carefully before booking.',
                      style: AppText.bodySm.copyWith(
                        color: const Color(0xFF664D03),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _heading(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          AppSpacing.w12,
          Expanded(child: Text(text, style: AppText.sectionTitle)),
        ],
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: AppText.body.copyWith(color: AppColors.primary)),
          AppSpacing.w8,
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }

  static Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Divider(height: 1, color: AppColors.divider),
      );

  static Widget _refundRow(
    String label,
    String outcome,
    Color color, {
    bool last = false,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: last ? 0 : AppSpacing.sm,
      ),
      margin: EdgeInsets.only(bottom: last ? 0 : AppSpacing.sm),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
      // Wrap instead of Row(spaceBetween) so both labels fit at 320 px.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xxs,
        children: [
          Text(label, style: AppText.body),
          Text(
            outcome,
            style: AppText.bodyStrong.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
