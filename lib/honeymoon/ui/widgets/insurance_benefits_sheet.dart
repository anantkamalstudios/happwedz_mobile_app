/// The "All benefits" sheet for a travel-insurance plan.
///
/// A port of the website's `InsuranceBenefitsModal`: every benefit the quote
/// carries, grouped by the insurer's own category, with its coverage amount and
/// description. The plan cards can only show a handful of highlights, so this
/// is where a traveller actually compares what a policy pays out for.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../models/honeymoon_models.dart';

/// Opens the benefits sheet for [plan]. A plan with no benefits never gets
/// here — the card hides its entry point instead.
Future<void> showInsuranceBenefitsSheet(
  BuildContext context,
  InsurancePlan plan,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
    builder: (_) => _InsuranceBenefitsSheet(plan: plan),
  );
}

class _InsuranceBenefitsSheet extends StatelessWidget {
  const _InsuranceBenefitsSheet({required this.plan});

  final InsurancePlan plan;

  /// Grouped by the insurer's category, preserving the order they arrived in —
  /// insurers list the headline covers first and that ordering is meaningful.
  Map<String, List<InsuranceBenefit>> get _grouped {
    final grouped = <String, List<InsuranceBenefit>>{};
    for (final benefit in plan.benefits) {
      final key = benefit.category.trim().isEmpty
          ? 'Other'
          : benefit.category.trim();
      grouped.putIfAbsent(key, () => <InsuranceBenefit>[]).add(benefit);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final grouped = _grouped;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('All benefits', style: AppText.sectionTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.name} · ${plan.insurerLabel}',
                          style: AppText.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                ),
                children: [
                  for (final entry in grouped.entries) ...[
                    Text(entry.key, style: AppText.overline),
                    const SizedBox(height: AppSpacing.sm),
                    for (final benefit in entry.value)
                      _BenefitRow(benefit: benefit),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final InsuranceBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
            child: Icon(
              // Assistance services and insured covers are different promises;
              // the icon says which one this is at a glance.
              benefit.isAssistance
                  ? Icons.support_agent_rounded
                  : Icons.verified_user_rounded,
              size: 16,
              color: AppColors.successDark,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(benefit.name, style: AppText.bodyStrong),
                    ),
                    if (benefit.coverage.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        benefit.coverage,
                        style: AppText.labelSm.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (benefit.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(benefit.description, style: AppText.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
