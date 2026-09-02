/// Inline chat-bubble form for the "Culture Blender" ShaadiAI feature.
///
/// Priority sliders exist in the React source but are never wired up — the
/// data layer already sends the fixed [kCulturePrioritiesConstant] for both
/// partners, so this form only collects the three fields the backend actually
/// varies on: each partner's culture and the ceremony type.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/shaadi_ai_api.dart';
import '../../models/shaadi_ai_models.dart';

class CultureBlenderForm extends StatefulWidget {
  const CultureBlenderForm({
    super.key,
    required this.onComplete,
    this.recommendationsLens,
  });

  final String? recommendationsLens;
  final void Function(Object result) onComplete;

  @override
  State<CultureBlenderForm> createState() => _CultureBlenderFormState();
}

class _CultureBlenderFormState extends State<CultureBlenderForm> {
  final _api = ShaadiAiApi();

  String? _culture1;
  String? _culture2;
  String? _ceremonyType;
  bool _loading = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading && _culture1 != null && _culture2 != null && _ceremonyType != null;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await _api.submitCultureBlender(
        culture1: _culture1!,
        culture2: _culture2!,
        ceremonyType: _ceremonyType!,
        recommendationsLens: widget.recommendationsLens,
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
        _CultureDropdown(
          label: 'Your Culture',
          value: _culture1,
          enabled: !_loading,
          onChanged: (v) => setState(() => _culture1 = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _CultureDropdown(
          label: "Partner's Culture",
          value: _culture2,
          enabled: !_loading,
          onChanged: (v) => setState(() => _culture2 = v),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ceremony Type', style: AppText.formLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in kCeremonyTypes)
              _SelectableChip(
                label: type,
                selected: _ceremonyType == type,
                enabled: !_loading,
                onTap: () => setState(() => _ceremonyType = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: 'Blend our traditions',
          icon: Icons.auto_awesome_rounded,
          isLoading: _loading,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _CultureDropdown extends StatelessWidget {
  const _CultureDropdown({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.formLabel),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          borderRadius: AppRadii.rMd,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          hint: Text(
            'Select a culture',
            style: AppText.body.copyWith(color: AppColors.textTertiary),
          ),
          items: [
            for (final culture in kCultureOptions)
              DropdownMenuItem(
                value: culture,
                child: Text(culture, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? onChanged : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
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
      borderRadius: AppRadii.rPill,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppText.labelSm.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
