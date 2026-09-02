/// Inline chat-bubble form for the "Personality Quiz" ShaadiAI feature.
///
/// Renders the same 7 fixed questions twice — once per partner — as two-option
/// picker cards rather than radio buttons, since this is meant to read as a
/// quick, fun quiz rather than a bureaucratic form.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/shaadi_ai_api.dart';
import '../../models/shaadi_ai_models.dart';

class PersonalityQuizForm extends StatefulWidget {
  const PersonalityQuizForm({
    super.key,
    required this.onComplete,
    this.recommendationsLens,
  });

  final String? recommendationsLens;
  final void Function(Object result) onComplete;

  @override
  State<PersonalityQuizForm> createState() => _PersonalityQuizFormState();
}

class _PersonalityQuizFormState extends State<PersonalityQuizForm> {
  final _api = ShaadiAiApi();

  final List<int?> _partner1Answers = List<int?>.filled(
    kPersonalityQuizQuestions.length,
    null,
  );
  final List<int?> _partner2Answers = List<int?>.filled(
    kPersonalityQuizQuestions.length,
    null,
  );

  bool _loading = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading &&
      !_partner1Answers.contains(null) &&
      !_partner2Answers.contains(null);

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await _api.submitPersonalityQuiz(
        partner1Answers: _partner1Answers,
        partner2Answers: _partner2Answers,
      );
      widget.onComplete(result);
    } on ShaadiAiException catch (e) {
      widget.onComplete(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PartnerHeader(label: 'Partner 1', icon: Icons.person_outline_rounded),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < kPersonalityQuizQuestions.length; i++) ...[
          _QuizQuestionCard(
            question: kPersonalityQuizQuestions[i],
            selected: _partner1Answers[i],
            enabled: !_loading,
            onSelected: (v) => setState(() => _partner1Answers[i] = v),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: AppSpacing.lg),
        const _PartnerHeader(label: 'Partner 2', icon: Icons.person_outline_rounded),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < kPersonalityQuizQuestions.length; i++) ...[
          _QuizQuestionCard(
            question: kPersonalityQuizQuestions[i],
            selected: _partner2Answers[i],
            enabled: !_loading,
            onSelected: (v) => setState(() => _partner2Answers[i] = v),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
        PremiumButton(
          label: 'See our compatibility',
          icon: Icons.auto_awesome_rounded,
          isLoading: _loading,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.blush,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppText.cardTitle),
      ],
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.question,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final PersonalityQuizQuestion question;
  final int? selected;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Q${question.id}: ${question.question}',
          style: AppText.bodyStrong,
        ),
        const SizedBox(height: AppSpacing.sm),
        // AUDIT FIX: `CrossAxisAlignment.stretch` on a Row asks each Expanded
        // child to fill the Row's own height — but that Row sits inside a
        // Column(mainAxisSize: min) inside a ListView, both unbounded, so
        // there is no height to stretch to. Flutter propagated an infinite
        // height constraint and crashed layout for every question, which
        // took the whole chat message down with it. `IntrinsicHeight` gives
        // the Row a real height (its tallest child) to stretch against.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _OptionCard(
                  label: question.option1,
                  selected: selected == 0,
                  enabled: enabled,
                  onTap: () => onSelected(0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OptionCard(
                  label: question.option2,
                  selected: selected == 1,
                  enabled: enabled,
                  onTap: () => onSelected(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadii.rMd,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.blush : Colors.white,
          borderRadius: AppRadii.rMd,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.bodySm.copyWith(
            color: selected ? AppColors.primaryDeep : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
