/// Inline chat-bubble form for the "Conflict Resolver" ShaadiAI feature.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/shaadi_ai_api.dart';
import '../../models/shaadi_ai_models.dart';

class ConflictResolverForm extends StatefulWidget {
  const ConflictResolverForm({
    super.key,
    required this.onComplete,
    this.recommendationsLens,
  });

  final String? recommendationsLens;
  final void Function(Object result) onComplete;

  @override
  State<ConflictResolverForm> createState() => _ConflictResolverFormState();
}

class _ConflictResolverFormState extends State<ConflictResolverForm> {
  final _api = ShaadiAiApi();
  final _partner1Controller = TextEditingController();
  final _partner2Controller = TextEditingController();

  String? _topic;
  bool _loading = false;

  @override
  void dispose() {
    _api.dispose();
    _partner1Controller.dispose();
    _partner2Controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading &&
      _topic != null &&
      _partner1Controller.text.trim().isNotEmpty &&
      _partner2Controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await _api.submitConflictResolver(
        topic: _topic!,
        partner1Input: _partner1Controller.text.trim(),
        partner2Input: _partner2Controller.text.trim(),
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
        Text("What's the disagreement about?", style: AppText.formLabel),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _topic,
          isExpanded: true,
          borderRadius: AppRadii.rMd,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          hint: Text(
            'Select a topic',
            style: AppText.body.copyWith(color: AppColors.textTertiary),
          ),
          items: [
            for (final topic in kConflictTopics)
              DropdownMenuItem(
                value: topic,
                child: Text(topic, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _loading ? null : (v) => setState(() => _topic = v),
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _partner1Controller,
          label: "Partner 1's perspective",
          required: true,
          maxLines: 4,
          minLines: 3,
          enabled: !_loading,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _partner2Controller,
          label: "Partner 2's perspective",
          required: true,
          maxLines: 4,
          minLines: 3,
          enabled: !_loading,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: 'Find common ground',
          icon: Icons.handshake_outlined,
          isLoading: _loading,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
