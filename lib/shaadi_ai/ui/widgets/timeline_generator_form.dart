/// Inline chat-bubble form for the "Timeline Generator" ShaadiAI feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/shaadi_ai_api.dart';
import '../../models/shaadi_ai_models.dart';

class TimelineGeneratorForm extends StatefulWidget {
  const TimelineGeneratorForm({
    super.key,
    required this.onComplete,
    this.recommendationsLens,
  });

  final String? recommendationsLens;
  final void Function(Object result) onComplete;

  @override
  State<TimelineGeneratorForm> createState() => _TimelineGeneratorFormState();
}

class _TimelineGeneratorFormState extends State<TimelineGeneratorForm> {
  final _api = ShaadiAiApi();

  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  late final TextEditingController _startTimeController;
  final Set<String> _selectedEvents = {};
  final _travelMinsController = TextEditingController(text: '0');
  final _constraintsController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimeController = TextEditingController(text: _formatTime(_startTime));
  }

  @override
  void dispose() {
    _api.dispose();
    _startTimeController.dispose();
    _travelMinsController.dispose();
    _constraintsController.dispose();
    super.dispose();
  }

  /// `HH:mm`, matching the fixed 24-hour format the endpoint expects — not
  /// the localized AM/PM text the time picker itself displays.
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<String> get _orderedSelectedEvents => [
    for (final event in kTimelineEvents)
      if (_selectedEvents.contains(event)) event,
  ];

  int get _travelMins =>
      (int.tryParse(_travelMinsController.text.trim()) ?? 0).clamp(0, 120);

  bool get _canSubmit => !_loading && _selectedEvents.isNotEmpty;

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked == null || !mounted) return;
    setState(() {
      _startTime = picked;
      _startTimeController.text = _formatTime(picked);
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final constraints = _constraintsController.text.trim();
      final result = await _api.submitTimelineGenerator(
        startTime: _formatTime(_startTime),
        selectedEvents: _orderedSelectedEvents,
        travelMins: _travelMins,
        constraints: constraints.isEmpty ? null : constraints,
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
        AppTextField(
          controller: _startTimeController,
          label: 'Start Time',
          readOnly: true,
          enabled: !_loading,
          suffixIcon: Icons.access_time_rounded,
          onTap: _loading ? null : _pickStartTime,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Which events are you including?', style: AppText.formLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final event in kTimelineEvents)
              _EventChip(
                label: event,
                selected: _selectedEvents.contains(event),
                enabled: !_loading,
                onTap: () => setState(() {
                  if (!_selectedEvents.remove(event)) _selectedEvents.add(event);
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _travelMinsController,
          label: 'Travel time between venues (minutes)',
          keyboardType: TextInputType.number,
          enabled: !_loading,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _constraintsController,
          label: 'Any other constraints?',
          hint: 'Optional',
          maxLines: 3,
          minLines: 2,
          enabled: !_loading,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: 'Build our timeline',
          icon: Icons.schedule_rounded,
          isLoading: _loading,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
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
            Icon(
              selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              size: 15,
              color: selected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
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
