/// Edit profile — ports `dashboard/EditProfile.jsx`'s tabbed field editor.
///
/// The source pre-fills every field with a hardcoded fake person ("Priya
/// Sharma", `priya.sharma@example.com`, a stock Unsplash headshot) and shows
/// a hardcoded "Profile 75% complete" bar. Neither is reproduced: this form
/// starts completely blank, and the fake completion bar is dropped outright
/// (same category as the dashboard's `Math.random()` stats — a number with
/// nothing real behind it). "Save Changes" shows an honest gated message
/// instead of pretending to persist anything. See MIGRATION_NOTES.md.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/core.dart';
import '../../models/matrimonial_profile.dart';
import '../matrimonial_landing_page.dart' show showMatrimonialGate;

class MatrimonialEditProfilePage extends StatefulWidget {
  const MatrimonialEditProfilePage({super.key});

  @override
  State<MatrimonialEditProfilePage> createState() => _MatrimonialEditProfilePageState();
}

class _MatrimonialEditProfilePageState extends State<MatrimonialEditProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);
  final _fields = MatrimonialEditProfileFields();
  final _picker = ImagePicker();
  File? _avatar;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _avatar = File(x.path));
  }

  void _save() {
    showMatrimonialGate(context, "Saving isn't available yet — please check back soon.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Edit Profile'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.pinkSurface,
                    backgroundImage: _avatar == null ? null : FileImage(_avatar!),
                    child: _avatar == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
                AppSpacing.h8,
                TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Change Photo'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Basic Details'),
              Tab(text: 'Religious Background'),
              Tab(text: 'Professional Details'),
              Tab(text: 'Personal Info'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _basicDetailsTab(),
                _religiousBackgroundTab(),
                _professionalDetailsTab(),
                _personalInfoTab(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: PremiumButton(label: 'Save Changes', onPressed: _save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppTextField(label: 'Full Name', onChanged: (v) => _fields.name = v),
        AppSpacing.h16,
        AppTextField(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _fields.email = v,
        ),
        AppSpacing.h16,
        AppTextField(
          label: 'Phone',
          keyboardType: TextInputType.phone,
          onChanged: (v) => _fields.phone = v,
        ),
        AppSpacing.h16,
        _EditDateField(onChanged: (d) => _fields.dob = d),
        AppSpacing.h16,
        _EditDropdown(
          label: 'Height',
          items: kHeights,
          onChanged: (v) => setState(() => _fields.height = v ?? ''),
        ),
        AppSpacing.h16,
        AppTextField(label: 'Location', onChanged: (v) => _fields.location = v),
      ],
    );
  }

  Widget _religiousBackgroundTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _EditDropdown(
          label: 'Religion',
          items: kReligions,
          onChanged: (v) => setState(() => _fields.religion = v ?? ''),
        ),
        AppSpacing.h16,
        _EditDropdown(
          label: 'Caste',
          items: kCasteFilterOptions.where((c) => c != 'Any').toList(),
          onChanged: (v) => setState(() => _fields.caste = v ?? ''),
        ),
        AppSpacing.h16,
        _EditDropdown(
          label: 'Mother Tongue',
          items: kMotherTongues,
          onChanged: (v) => setState(() => _fields.motherTongue = v ?? ''),
        ),
      ],
    );
  }

  Widget _professionalDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _EditDropdown(
          label: 'Education',
          items: kEducations,
          onChanged: (v) => setState(() => _fields.education = v ?? ''),
        ),
        AppSpacing.h16,
        AppTextField(label: 'Profession', onChanged: (v) => _fields.profession = v),
        AppSpacing.h16,
        _EditDropdown(
          label: 'Annual Income',
          items: kIncomes,
          onChanged: (v) => setState(() => _fields.income = v ?? ''),
        ),
      ],
    );
  }

  Widget _personalInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppTextField(label: 'About Me', maxLines: 4, onChanged: (v) => _fields.about = v),
        AppSpacing.h16,
        AppTextField(label: 'Hobbies & Interests', onChanged: (v) => _fields.hobbies = v),
      ],
    );
  }
}

class _EditDropdown extends StatelessWidget {
  const _EditDropdown({required this.label, required this.items, required this.onChanged});

  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.formLabel),
        AppSpacing.h8,
        DropdownButtonFormField<String>(
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppText.body))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            hintText: 'Select',
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
            border: OutlineInputBorder(borderRadius: AppRadii.rMd, borderSide: const BorderSide(color: AppColors.divider)),
          ),
        ),
      ],
    );
  }
}

class _EditDateField extends StatefulWidget {
  const _EditDateField({required this.onChanged});

  final ValueChanged<DateTime?> onChanged;

  @override
  State<_EditDateField> createState() => _EditDateFieldState();
}

class _EditDateFieldState extends State<_EditDateField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Date of Birth',
      readOnly: true,
      controller: _controller,
      prefixIcon: Icons.calendar_today_outlined,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 25),
          firstDate: DateTime(now.year - 100),
          lastDate: now,
        );
        if (picked != null) {
          setState(() {
            _controller.text =
                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          });
          widget.onChanged(picked);
        }
      },
    );
  }
}
