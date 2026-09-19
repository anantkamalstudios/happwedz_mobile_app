/// 4-step registration wizard — ports `MatrimonialRegistration.jsx`
/// (Profile Details → Family Details → About Yourself → Phone Verification).
///
/// Every field and validation rule below is taken directly from the source's
/// `formData` / `validateStep`. What is deliberately different: the source's
/// `handleSubmit` calls `Swal.fire(...)` without ever importing `Swal` — it
/// would throw at runtime — and `verifyPhone` sets `phoneVerified: true`
/// unconditionally with a comment admitting "In a real app, you would send
/// OTP here." Neither fake path is reproduced. See MIGRATION_NOTES.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../models/matrimonial_profile.dart';
import 'matrimonial_landing_page.dart' show showMatrimonialGate;

class MatrimonialRegistrationPage extends StatefulWidget {
  const MatrimonialRegistrationPage({super.key});

  @override
  State<MatrimonialRegistrationPage> createState() => _MatrimonialRegistrationPageState();
}

class _MatrimonialRegistrationPageState extends State<MatrimonialRegistrationPage> {
  final _draft = MatrimonialRegistrationDraft();
  final _phoneController = TextEditingController();

  int _step = 1;
  Map<String, String> _errors = {};
  bool _otpRequested = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  static const _stepTitles = [
    'Profile Details',
    'Family Details',
    'About Yourself',
    'Phone Verification',
  ];

  void _goToStep(int step) {
    if (step > _step) return; // source only allows revisiting completed steps
    setState(() => _step = step);
  }

  void _next() {
    if (_step == 1) {
      final errors = _draft.validateStep1();
      setState(() => _errors = errors);
      if (errors.isNotEmpty) return;
    }
    setState(() {
      _step += 1;
      _errors = {};
    });
  }

  void _back() {
    setState(() {
      _step -= 1;
      _errors = {};
    });
  }

  void _sendOtp() {
    final error = MatrimonialRegistrationDraft.validatePhone(_phoneController.text);
    if (error != null) {
      setState(() => _errors = {'phone': error});
      return;
    }
    setState(() {
      _draft.phone = _phoneController.text;
      _errors = {};
      _otpRequested = true;
    });
    showMatrimonialGate(context, "OTP verification isn't available yet.");
  }

  void _completeRegistration() {
    final errors = _draft.validateStep1();
    if (errors.isNotEmpty) {
      setState(() {
        _step = 1;
        _errors = errors;
      });
      return;
    }
    showMatrimonialGate(context, "Registration isn't available yet — please check back soon.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Matrimonial Registration'),
      body: Column(
        children: [
          _StepTabs(currentStep: _step, titles: _stepTitles, onTap: _goToStep),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Hi! You are joining the Best Matchmaking Experience.',
                  style: AppText.sectionTitle.copyWith(color: AppColors.primary),
                ),
                AppSpacing.h20,
                switch (_step) {
                  1 => _ProfileDetailsStep(draft: _draft, errors: _errors, onChanged: () => setState(() {})),
                  2 => _FamilyDetailsStep(draft: _draft, onChanged: () => setState(() {})),
                  3 => _AboutYourselfStep(draft: _draft, onChanged: () => setState(() {})),
                  _ => _PhoneVerificationStep(
                      controller: _phoneController,
                      errors: _errors,
                      otpRequested: _otpRequested,
                      onSendOtp: _sendOtp,
                      onComplete: _completeRegistration,
                    ),
                },
              ],
            ),
          ),
          if (_step < 4)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: PremiumButton.outlined(
                        label: 'Back',
                        onPressed: _step > 1 ? _back : null,
                      ),
                    ),
                    AppSpacing.w12,
                    Expanded(
                      child: PremiumButton(label: 'Next', onPressed: _next),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepTabs extends StatelessWidget {
  const _StepTabs({required this.currentStep, required this.titles, required this.onTap});

  final int currentStep;
  final List<String> titles;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(titles.length, (i) {
            final step = i + 1;
            final active = step == currentStep;
            final reachable = step <= currentStep;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(titles[i]),
                selected: active,
                onSelected: reachable ? (_) => onTap(step) : null,
                labelStyle: AppText.labelSm.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                shape: const StadiumBorder(),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Profile Details
// ---------------------------------------------------------------------------

class _ProfileDetailsStep extends StatelessWidget {
  const _ProfileDetailsStep({required this.draft, required this.errors, required this.onChanged});

  final MatrimonialRegistrationDraft draft;
  final Map<String, String> errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final castes = kCastesByReligion[draft.religion] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledDropdown(
          label: 'Creating Profile For',
          required: true,
          value: draft.profileFor.isEmpty ? null : draft.profileFor,
          items: kProfileForOptions,
          errorText: errors['profileFor'],
          onChanged: (v) {
            draft.profileFor = v ?? '';
            onChanged();
          },
        ),
        AppSpacing.h16,
        _LabeledDropdown(
          label: 'Profile Type',
          required: true,
          value: draft.profileType.isEmpty ? null : draft.profileType,
          items: kProfileTypeOptions,
          errorText: errors['profileType'],
          onChanged: (v) {
            draft.profileType = v ?? '';
            onChanged();
          },
        ),
        AppSpacing.h16,
        AppTextField(
          label: draft.nameLabel,
          required: true,
          errorText: errors['name'],
          onChanged: (v) => draft.name = v,
        ),
        AppSpacing.h8,
        Row(
          children: [
            Switch(
              value: draft.showName,
              activeThumbColor: AppColors.primary,
              onChanged: (v) {
                draft.showName = v;
                onChanged();
              },
            ),
            Text('Show to All', style: AppText.bodySm),
          ],
        ),
        AppSpacing.h16,
        _DateField(
          label: 'Date of Birth',
          required: true,
          value: draft.dob,
          errorText: errors['dob'],
          onChanged: (d) {
            draft.dob = d;
            onChanged();
          },
        ),
        AppSpacing.h16,
        _LabeledDropdown(
          label: 'Mother Tongue',
          value: draft.motherTongue.isEmpty ? null : draft.motherTongue,
          items: kMotherTongues,
          onChanged: (v) {
            draft.motherTongue = v ?? '';
            onChanged();
          },
        ),
        AppSpacing.h16,
        _LabeledDropdown(
          label: 'Religion',
          value: draft.religion.isEmpty ? null : draft.religion,
          items: kReligions,
          onChanged: (v) {
            draft.religion = v ?? '';
            draft.caste = '';
            onChanged();
          },
        ),
        AppSpacing.h16,
        _LabeledDropdown(
          label: 'Caste',
          value: draft.caste.isEmpty ? null : draft.caste,
          items: castes,
          onChanged: castes.isEmpty
              ? null
              : (v) {
                  draft.caste = v ?? '';
                  onChanged();
                },
        ),
        AppSpacing.h8,
        CheckboxListTile(
          value: draft.casteNoBar,
          onChanged: (v) {
            draft.casteNoBar = v ?? false;
            onChanged();
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: Text('Caste no bar (I am open to marry people of all castes)', style: AppText.bodySm),
        ),
        AppSpacing.h16,
        Text('Are you manglik?', style: AppText.formLabel),
        AppSpacing.h8,
        Wrap(
          spacing: AppSpacing.sm,
          children: Manglik.values.map((m) {
            return ChoiceChip(
              label: Text(m.label),
              selected: draft.manglik == m,
              onSelected: (_) {
                draft.manglik = m;
                onChanged();
              },
              selectedColor: AppColors.primary,
              labelStyle: AppText.labelSm.copyWith(
                color: draft.manglik == m ? Colors.white : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Family Details
// ---------------------------------------------------------------------------

class _FamilyDetailsStep extends StatelessWidget {
  const _FamilyDetailsStep({required this.draft, required this.onChanged});

  final MatrimonialRegistrationDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledDropdown(
          label: 'Family Type',
          value: draft.familyType.isEmpty ? null : draft.familyType,
          items: kFamilyTypes,
          onChanged: (v) {
            draft.familyType = v ?? '';
            onChanged();
          },
        ),
        AppSpacing.h24,
        Text('Brothers', style: AppText.cardTitle),
        AppSpacing.h8,
        _CountSelector(
          label: 'How many brothers?',
          value: draft.brothers,
          onChanged: (v) {
            draft.brothers = v;
            draft.marriedBrothers = draft.marriedBrothers.clamp(0, v);
            draft.unmarriedBrothers = draft.unmarriedBrothers.clamp(0, v);
            onChanged();
          },
        ),
        if (draft.brothers > 0) ...[
          AppSpacing.h12,
          _CountSelector(
            label: 'How many married?',
            value: draft.marriedBrothers,
            max: draft.brothers,
            onChanged: (v) {
              draft.marriedBrothers = v;
              onChanged();
            },
          ),
          AppSpacing.h12,
          _CountSelector(
            label: 'How many unmarried?',
            value: draft.unmarriedBrothers,
            max: draft.brothers,
            onChanged: (v) {
              draft.unmarriedBrothers = v;
              onChanged();
            },
          ),
        ],
        AppSpacing.h24,
        Text('Sisters', style: AppText.cardTitle),
        AppSpacing.h8,
        _CountSelector(
          label: 'How many sisters?',
          value: draft.sisters,
          onChanged: (v) {
            draft.sisters = v;
            draft.marriedSisters = draft.marriedSisters.clamp(0, v);
            draft.unmarriedSisters = draft.unmarriedSisters.clamp(0, v);
            onChanged();
          },
        ),
        if (draft.sisters > 0) ...[
          AppSpacing.h12,
          _CountSelector(
            label: 'How many married?',
            value: draft.marriedSisters,
            max: draft.sisters,
            onChanged: (v) {
              draft.marriedSisters = v;
              onChanged();
            },
          ),
          AppSpacing.h12,
          _CountSelector(
            label: 'How many unmarried?',
            value: draft.unmarriedSisters,
            max: draft.sisters,
            onChanged: (v) {
              draft.unmarriedSisters = v;
              onChanged();
            },
          ),
        ],
        AppSpacing.h24,
        AppTextField(
          label: "Father's Occupation",
          hint: "Enter father's occupation",
          onChanged: (v) => draft.fatherOccupation = v,
        ),
        AppSpacing.h16,
        AppTextField(
          label: "Mother's Occupation",
          hint: "Enter mother's occupation",
          onChanged: (v) => draft.motherOccupation = v,
        ),
      ],
    );
  }
}

class _CountSelector extends StatelessWidget {
  const _CountSelector({required this.label, required this.value, required this.onChanged, this.max = 3});

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [0, 1, 2, 3].where((n) => n <= (max < 3 ? max : 3)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.formLabel),
        AppSpacing.h8,
        Wrap(
          spacing: AppSpacing.sm,
          children: options.map((n) {
            final selected = value == n;
            return ChoiceChip(
              label: Text(n == 3 ? '3+' : '$n'),
              selected: selected,
              onSelected: (_) => onChanged(n),
              selectedColor: AppColors.primary,
              labelStyle: AppText.labelSm.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — About Yourself
// ---------------------------------------------------------------------------

class _AboutYourselfStep extends StatelessWidget {
  const _AboutYourselfStep({required this.draft, required this.onChanged});

  final MatrimonialRegistrationDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Here is your chance to make your profile stand out!', style: AppText.cardTitle),
        AppSpacing.h4,
        Text(
          "Write about yourself, your family, your expectations from partner, etc.",
          style: AppText.bodySm,
        ),
        AppSpacing.h12,
        AppTextField(
          maxLines: 6,
          hint:
              "Tell about yourself, your family background, education, career, hobbies, and what you're looking for in a partner...",
          onChanged: (v) => draft.aboutYourself = v,
        ),
        AppSpacing.h20,
        AppTextField(
          label: 'Hobbies & Interests',
          maxLines: 4,
          hint: 'Reading, traveling, cooking, sports, music, etc.',
          onChanged: (v) => draft.hobbies = v,
        ),
        AppSpacing.h16,
        AppTextField(
          label: 'Partner Expectations',
          maxLines: 4,
          hint: 'What are you looking for in your ideal partner?',
          onChanged: (v) => draft.partnerExpectations = v,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Phone Verification
// ---------------------------------------------------------------------------

class _PhoneVerificationStep extends StatelessWidget {
  const _PhoneVerificationStep({
    required this.controller,
    required this.errors,
    required this.otpRequested,
    required this.onSendOtp,
    required this.onComplete,
  });

  final TextEditingController controller;
  final Map<String, String> errors;
  final bool otpRequested;
  final VoidCallback onSendOtp;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.phone_outlined, color: AppColors.primary, size: 48),
        AppSpacing.h16,
        Text(
          otpRequested ? 'Phone verification isn\'t available yet' : 'Phone Verification',
          style: AppText.sectionTitle,
          textAlign: TextAlign.center,
        ),
        AppSpacing.h8,
        Text(
          otpRequested
              ? "We couldn't send an OTP because this feature isn't connected yet. You can still finish filling in the form."
              : "We'll send an OTP to verify your mobile number",
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
        AppSpacing.h20,
        AppTextField(
          label: 'Mobile Number',
          required: true,
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          hint: 'Enter 10 digit mobile number',
          prefix: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
            child: Text('+91', style: AppText.body),
          ),
          errorText: errors['phone'],
        ),
        AppSpacing.h20,
        PremiumButton(label: 'Send OTP', onPressed: onSendOtp),
        if (otpRequested) ...[
          AppSpacing.h20,
          PremiumButton.outlined(label: 'Complete Registration', onPressed: onComplete),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small fields
// ---------------------------------------------------------------------------

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.required = false,
    this.errorText,
  });

  final String label;
  final List<String> items;
  final String? value;
  final bool required;
  final String? errorText;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppText.formLabel,
            children: required ? [TextSpan(text: ' *', style: AppText.formLabel.copyWith(color: AppColors.error))] : null,
          ),
        ),
        AppSpacing.h8,
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppText.body)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: onChanged == null ? AppColors.background : Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
            errorText: errorText,
            hintText: 'Select',
            border: OutlineInputBorder(
              borderRadius: AppRadii.rMd,
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.rMd,
              borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onChanged,
    this.value,
    this.required = false,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final bool required;
  final String? errorText;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return AppTextField(
      label: label,
      required: required,
      readOnly: true,
      hint: 'Select date',
      controller: TextEditingController(text: text),
      prefixIcon: Icons.calendar_today_outlined,
      errorText: errorText,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 25),
          firstDate: DateTime(now.year - 100),
          lastDate: now,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
