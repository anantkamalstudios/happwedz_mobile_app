/// Result cards shown after a ShaadiAI inline feature form completes.
///
/// Ported from `ChatFeatures.jsx`'s `PersonalityQuizResult`,
/// `CultureBlenderResult`, `ConflictResolverResult` and
/// `TimelineGeneratorResult` components — structure and copy match the
/// source, restyled onto this app's design system.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../models/shaadi_ai_models.dart';

class PersonalityQuizResultCard extends StatelessWidget {
  const PersonalityQuizResultCard({super.key, required this.result});

  final PersonalityQuizResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '🎉 ${result.profileName}',
                style: AppText.sectionTitle,
              ),
            ),
          ],
        ),
        if (result.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(result.description, style: AppText.body),
        ],
        if (result.traits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: result.traits
                .map((t) => _Pill(text: t, color: AppColors.primary))
                .toList(),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _DetailRow(label: '🏛️ Venue Style:', value: result.venueStyle),
        const SizedBox(height: AppSpacing.xs),
        _DetailRow(label: '🎨 Decor Style:', value: result.decorStyle),
        if (result.mismatchAlert != null &&
            result.mismatchAlert!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _AlertBox(label: '💡 Note:', text: result.mismatchAlert!),
        ],
        if (result.recommendationsLens.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _LensBox(text: result.recommendationsLens),
        ],
      ],
    );
  }
}

class CultureBlenderResultCard extends StatelessWidget {
  const CultureBlenderResultCard({super.key, required this.result});

  final CultureBlenderResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      children: [
        Text('✨ Blended Ceremony', style: AppText.sectionTitle),
        for (final section in result.ceremonySections) ...[
          const SizedBox(height: AppSpacing.md),
          _CeremonySectionTile(section: section),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: AppSpacing.md),
        _DetailRow(label: '👗 Attire:', value: result.attireSuggestion),
        const SizedBox(height: AppSpacing.xs),
        _DetailRow(label: '🍽️ Food:', value: result.foodSuggestion),
        const SizedBox(height: AppSpacing.xs),
        _DetailRow(label: '🎵 Music:', value: result.musicSuggestion),
      ],
    );
  }
}

class _CeremonySectionTile extends StatelessWidget {
  const _CeremonySectionTile({required this.section});

  final CultureCeremonySection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pinkSurface,
        borderRadius: AppRadii.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(section.name, style: AppText.cardTitle),
              _Pill(text: section.origin, color: AppColors.info),
              Text('⏱️ ${section.durationMins} mins', style: AppText.caption),
            ],
          ),
          if (section.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(section.description, style: AppText.body),
          ],
          if (section.guestExplanation != null &&
              section.guestExplanation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '👥 ${section.guestExplanation}',
              style: AppText.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConflictResolverResultCard extends StatelessWidget {
  const ConflictResolverResultCard({super.key, required this.result});

  final ConflictResolverResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      children: [
        _AlertBox(label: '💡 Reframe:', text: result.reframe),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NeedTile(
                label: "Partner 1's Need:",
                value: result.partner1RealNeed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _NeedTile(
                label: "Partner 2's Need:",
                value: result.partner2RealNeed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Resolution Options:', style: AppText.cardTitle),
        for (final option in result.options) ...[
          const SizedBox(height: AppSpacing.sm),
          _ConflictOptionTile(option: option),
        ],
      ],
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelSm),
        const SizedBox(height: 2),
        Text(value, style: AppText.body),
      ],
    );
  }
}

class _ConflictOptionTile extends StatelessWidget {
  const _ConflictOptionTile({required this.option});

  final ConflictOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: option.aiRecommended ? AppColors.pinkSurface : AppColors.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: option.aiRecommended
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (option.aiRecommended)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _Pill(text: '✨ AI Recommended', color: AppColors.primary),
            ),
          Text(option.title, style: AppText.cardTitle),
          if (option.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(option.description, style: AppText.body),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'P1 gives up: ${option.partner1GivesUp}',
            style: AppText.caption,
          ),
          Text(
            'P2 gives up: ${option.partner2GivesUp}',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class TimelineResultCard extends StatelessWidget {
  const TimelineResultCard({super.key, required this.items});

  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _ResultCard(
        children: [
          Text('📅 Your Wedding Timeline', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text('No timeline data available.', style: AppText.body),
        ],
      );
    }

    return _ResultCard(
      children: [
        Text('📅 Your Wedding Timeline', style: AppText.sectionTitle),
        for (final item in items) ...[
          const SizedBox(height: AppSpacing.md),
          _TimelineItemTile(item: item),
        ],
      ],
    );
  }
}

class _TimelineItemTile extends StatelessWidget {
  const _TimelineItemTile({required this.item});

  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: item.warning ? AppColors.warning.withValues(alpha: 0.08) : AppColors.pinkSurface,
        borderRadius: AppRadii.rMd,
        border: item.warning
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.time, style: AppText.cardTitle),
                Text('${item.durationMins} min', style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: AppText.cardTitle),
                    ),
                    if (item.type.isNotEmpty)
                      _Pill(text: item.type, color: AppColors.info),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.notes!, style: AppText.caption),
                ],
                if (item.warning) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '⚠️ This event may be rushed - consider adjusting timing',
                    style: AppText.caption.copyWith(color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small pieces
// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        children: [
          TextSpan(text: '$label ', style: AppText.bodyStrong),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  const _AlertBox({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadii.rMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodyStrong),
          const SizedBox(height: 2),
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}

class _LensBox extends StatelessWidget {
  const _LensBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadii.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 AI Planning Lens:', style: AppText.bodyStrong),
          const SizedBox(height: 2),
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        text,
        style: AppText.labelSm.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
