/// Create/edit form — ports `src/components/pages/WeddingWebsiteForm.jsx`.
///
/// One screen with plain sections and image pickers, since the source's
/// drag-drop editor, rich text and image cropper have no mobile equivalent
/// (see MIGRATION_NOTES.md's Wedding Websites section). The exact field
/// names sent to the API are unchanged — see `buildFormData` in the source
/// and `WeddingWebsiteApi._buildMultipartParts`.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/core.dart';
import '../data/wedding_website_api.dart';
import '../models/wedding_website_models.dart';

class WeddingWebsiteFormPage extends StatefulWidget {
  const WeddingWebsiteFormPage({super.key, required this.template, this.editId});

  final WeddingWebsiteTemplate template;

  /// When set, this screen edits an existing record instead of creating one.
  final String? editId;

  @override
  State<WeddingWebsiteFormPage> createState() => _WeddingWebsiteFormPageState();
}

class _WeddingWebsiteFormPageState extends State<WeddingWebsiteFormPage> {
  final _api = WeddingWebsiteApi();
  final _picker = ImagePicker();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _timeFormat = DateFormat('HH:mm');

  bool _initializing = true;
  bool _saving = false;
  Object? _loadError;

  late WeddingWebsiteTemplate _template = widget.template;
  final _weddingDate = TextEditingController();

  final _brideName = TextEditingController();
  final _brideDesc = TextEditingController();
  DraftImage _brideImage = const DraftImage();

  final _groomName = TextEditingController();
  final _groomDesc = TextEditingController();
  DraftImage _groomImage = const DraftImage();

  final List<DraftImage> _sliderImages = [];
  final List<DraftImage> _galleryImages = [];

  final List<_LoveStoryItem> _loveStory = [];
  final List<_PartyItem> _weddingParty = [];
  final List<_WhenWhereItem> _whenWhere = [];

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    _weddingDate.dispose();
    _brideName.dispose();
    _brideDesc.dispose();
    _groomName.dispose();
    _groomDesc.dispose();
    for (final e in _loveStory) {
      e.dispose();
    }
    for (final e in _weddingParty) {
      e.dispose();
    }
    for (final e in _whenWhere) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isEdit) {
      setState(() => _initializing = false);
      return;
    }
    try {
      final detail = await _api.fetchWebsite(widget.editId!);
      final draft = WeddingWebsiteDraft.fromDetail(detail);
      if (!mounted) return;
      setState(() {
        _template = draft.template;
        _weddingDate.text = draft.weddingDate;
        _brideName.text = draft.brideName;
        _brideDesc.text = draft.brideDescription;
        _brideImage = draft.brideImage;
        _groomName.text = draft.groomName;
        _groomDesc.text = draft.groomDescription;
        _groomImage = draft.groomImage;
        _sliderImages
          ..clear()
          ..addAll(draft.sliderImages);
        _galleryImages
          ..clear()
          ..addAll(draft.galleryImages);
        _loveStory
          ..clear()
          ..addAll(draft.loveStory.map(_LoveStoryItem.from));
        _weddingParty
          ..clear()
          ..addAll(draft.weddingParty.map(_PartyItem.from));
        _whenWhere
          ..clear()
          ..addAll(draft.whenWhere.map(_WhenWhereItem.from));
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _initializing = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Pickers
  // ---------------------------------------------------------------------------

  Future<File?> _pickOne() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return x == null ? null : File(x.path);
  }

  Future<List<File>> _pickMany() async {
    final xs = await _picker.pickMultiImage(imageQuality: 85);
    return xs.map((x) => File(x.path)).toList();
  }

  Future<void> _pickWeddingDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_weddingDate.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _weddingDate.text = _dateFormat.format(picked));
  }

  Future<void> _pickEntryDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => controller.text = _dateFormat.format(picked));
  }

  Future<void> _pickEntryTime(TextEditingController controller) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() => controller.text = _timeFormat.format(dt));
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_weddingDate.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Please choose a wedding date.');
      return;
    }

    final draft = WeddingWebsiteDraft(
      template: _template,
      weddingDate: _weddingDate.text.trim(),
      brideName: _brideName.text.trim(),
      brideDescription: _brideDesc.text.trim(),
      brideImage: _brideImage,
      groomName: _groomName.text.trim(),
      groomDescription: _groomDesc.text.trim(),
      groomImage: _groomImage,
      sliderImages: List.of(_sliderImages),
      galleryImages: List.of(_galleryImages),
      loveStory: _loveStory.map((e) => e.toDraft()).toList(),
      weddingParty: _weddingParty.map((e) => e.toDraft()).toList(),
      whenWhere: _whenWhere.map((e) => e.toDraft()).toList(),
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _api.updateWebsite(widget.editId!, draft);
        if (mounted) AppSnackbar.success(context, 'Wedding website updated successfully!');
      } else {
        await _api.createWebsite(draft);
        if (mounted) AppSnackbar.success(context, 'Wedding website created successfully!');
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: _isEdit ? 'Edit Wedding Website' : 'Create Wedding Website'),
      body: _initializing
          ? const AppLoader()
          : _loadError != null
          ? ErrorState(error: _loadError, onRetry: _load)
          : _buildForm(),
      bottomNavigationBar: _initializing || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PremiumButton(
                  label: _isEdit ? 'Update Website' : 'Create Website',
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.palette_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Template: ${_template.label}', style: AppText.bodyStrong)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionHeader(title: 'Wedding date', padding: EdgeInsets.only(bottom: AppSpacing.sm)),
        AppTextField(
          controller: _weddingDate,
          hint: 'Select date',
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _pickWeddingDate,
          required: true,
        ),

        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Bride', padding: EdgeInsets.only(bottom: AppSpacing.sm)),
        _personSection(
          name: _brideName,
          description: _brideDesc,
          image: _brideImage,
          onPick: () async {
            final f = await _pickOne();
            if (f != null) setState(() => _brideImage = DraftImage.picked(f));
          },
        ),

        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Groom', padding: EdgeInsets.only(bottom: AppSpacing.sm)),
        _personSection(
          name: _groomName,
          description: _groomDesc,
          image: _groomImage,
          onPick: () async {
            final f = await _pickOne();
            if (f != null) setState(() => _groomImage = DraftImage.picked(f));
          },
        ),

        const SizedBox(height: AppSpacing.xl),
        _imageGridSection(
          title: 'Slider images',
          images: _sliderImages,
          onAdd: () async {
            final files = await _pickMany();
            setState(() => _sliderImages.addAll(files.map(DraftImage.picked)));
          },
          onRemove: (i) => setState(() => _sliderImages.removeAt(i)),
        ),

        const SizedBox(height: AppSpacing.xl),
        _entryListSection<_LoveStoryItem>(
          headerKey: const Key('wedding_website_form_love_story_header'),
          title: 'Our love story',
          items: _loveStory,
          onAdd: () => setState(() => _loveStory.add(_LoveStoryItem.empty())),
          onRemove: (i) => setState(() {
            _loveStory[i].dispose();
            _loveStory.removeAt(i);
          }),
          itemBuilder: (item) => Column(
            children: [
              AppTextField(controller: item.title, label: 'Title'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: item.date,
                label: 'Date',
                readOnly: true,
                prefixIcon: Icons.event_outlined,
                onTap: () => _pickEntryDate(item.date),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: item.description, label: 'Description', maxLines: 3),
              const SizedBox(height: AppSpacing.sm),
              _entryImagePicker(
                image: item.image,
                onPick: () async {
                  final f = await _pickOne();
                  if (f != null) setState(() => item.image = DraftImage.picked(f));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        _entryListSection<_PartyItem>(
          headerKey: const Key('wedding_website_form_wedding_party_header'),
          title: 'Wedding party',
          items: _weddingParty,
          onAdd: () => setState(() => _weddingParty.add(_PartyItem.empty())),
          onRemove: (i) => setState(() {
            _weddingParty[i].dispose();
            _weddingParty.removeAt(i);
          }),
          itemBuilder: (item) => Column(
            children: [
              AppTextField(controller: item.name, label: 'Name'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: item.relation, label: 'Relation'),
              const SizedBox(height: AppSpacing.sm),
              _entryImagePicker(
                image: item.image,
                onPick: () async {
                  final f = await _pickOne();
                  if (f != null) setState(() => item.image = DraftImage.picked(f));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        _entryListSection<_WhenWhereItem>(
          headerKey: const Key('wedding_website_form_when_where_header'),
          title: 'When & where',
          items: _whenWhere,
          onAdd: () => setState(() => _whenWhere.add(_WhenWhereItem.empty())),
          onRemove: (i) => setState(() {
            _whenWhere[i].dispose();
            _whenWhere.removeAt(i);
          }),
          itemBuilder: (item) => Column(
            children: [
              AppTextField(controller: item.title, label: 'Title (e.g. Ceremony)'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: item.location, label: 'Location'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: item.date,
                      label: 'Date',
                      readOnly: true,
                      prefixIcon: Icons.event_outlined,
                      onTap: () => _pickEntryDate(item.date),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: item.time,
                      label: 'Time',
                      readOnly: true,
                      prefixIcon: Icons.schedule_outlined,
                      onTap: () => _pickEntryTime(item.time),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: item.description, label: 'Description', maxLines: 3),
              const SizedBox(height: AppSpacing.sm),
              _entryImagePicker(
                image: item.image,
                onPick: () async {
                  final f = await _pickOne();
                  if (f != null) setState(() => item.image = DraftImage.picked(f));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        _imageGridSection(
          title: 'Gallery',
          images: _galleryImages,
          onAdd: () async {
            final files = await _pickMany();
            setState(() => _galleryImages.addAll(files.map(DraftImage.picked)));
          },
          onRemove: (i) => setState(() => _galleryImages.removeAt(i)),
        ),
      ],
    );
  }

  Widget _personSection({
    required TextEditingController name,
    required TextEditingController description,
    required DraftImage image,
    required VoidCallback onPick,
  }) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Pressable(
                onTap: onPick,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pinkSurface,
                    image: image.file != null
                        ? DecorationImage(image: FileImage(image.file!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: image.file == null && (image.existingUrl ?? '').isEmpty
                      ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary)
                      : image.file == null
                      ? ClipOval(child: NetworkImageWidget(url: image.existingUrl, width: 64, height: 64))
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Tap the photo to add or change it', style: AppText.caption),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: name, label: 'Name'),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: description, label: 'About', maxLines: 3),
        ],
      ),
    );
  }

  Widget _entryImagePicker({required DraftImage image, required VoidCallback onPick}) {
    return Row(
      children: [
        Pressable(
          onTap: onPick,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: AppRadii.rSm,
              color: AppColors.background,
              border: Border.all(color: AppColors.divider),
              image: image.file != null
                  ? DecorationImage(image: FileImage(image.file!), fit: BoxFit.cover)
                  : null,
            ),
            child: image.file == null && (image.existingUrl ?? '').isEmpty
                ? const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textTertiary, size: 20)
                : image.file == null
                ? ClipRRect(
                    borderRadius: AppRadii.rSm,
                    child: NetworkImageWidget(url: image.existingUrl, width: 56, height: 56),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('Photo (optional)', style: AppText.caption),
      ],
    );
  }

  Widget _imageGridSection({
    required String title,
    required List<DraftImage> images,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          actionLabel: 'Add',
          onAction: onAdd,
        ),
        if (images.isEmpty)
          Text('No images added yet.', style: AppText.caption)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < images.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.rSm,
                        color: AppColors.background,
                        image: images[i].file != null
                            ? DecorationImage(image: FileImage(images[i].file!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: images[i].file == null
                          ? ClipRRect(
                              borderRadius: AppRadii.rSm,
                              child: NetworkImageWidget(url: images[i].existingUrl, width: 84, height: 84),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Pressable(
                        onTap: () => onRemove(i),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Widget _entryListSection<T>({
    required String title,
    required List<T> items,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
    required Widget Function(T item) itemBuilder,
    Key? headerKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          key: headerKey,
          title: title,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          actionLabel: 'Add',
          onAction: onAdd,
        ),
        for (var i = 0; i < items.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Pressable(
                    onTap: () => onRemove(i),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  ),
                ),
                itemBuilder(items[i]),
              ],
            ),
          ),
        if (items.isEmpty) Text('Nothing added yet.', style: AppText.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Per-entry controller bundles
// ---------------------------------------------------------------------------

class _LoveStoryItem {
  _LoveStoryItem({String title = '', String date = '', String description = '', DraftImage? image})
    : title = TextEditingController(text: title),
      date = TextEditingController(text: date),
      description = TextEditingController(text: description),
      image = image ?? const DraftImage();

  final TextEditingController title;
  final TextEditingController date;
  final TextEditingController description;
  DraftImage image;

  factory _LoveStoryItem.empty() => _LoveStoryItem();

  factory _LoveStoryItem.from(LoveStoryDraft d) =>
      _LoveStoryItem(title: d.title, date: d.date, description: d.description, image: d.image);

  LoveStoryDraft toDraft() =>
      LoveStoryDraft(title: title.text.trim(), date: date.text.trim(), description: description.text.trim(), image: image);

  void dispose() {
    title.dispose();
    date.dispose();
    description.dispose();
  }
}

class _PartyItem {
  _PartyItem({String name = '', String relation = '', DraftImage? image})
    : name = TextEditingController(text: name),
      relation = TextEditingController(text: relation),
      image = image ?? const DraftImage();

  final TextEditingController name;
  final TextEditingController relation;
  DraftImage image;

  factory _PartyItem.empty() => _PartyItem();

  factory _PartyItem.from(WeddingPartyDraft d) => _PartyItem(name: d.name, relation: d.relation, image: d.image);

  WeddingPartyDraft toDraft() =>
      WeddingPartyDraft(name: name.text.trim(), relation: relation.text.trim(), image: image);

  void dispose() {
    name.dispose();
    relation.dispose();
  }
}

class _WhenWhereItem {
  _WhenWhereItem({
    String title = '',
    String location = '',
    String description = '',
    String date = '',
    String time = '',
    DraftImage? image,
  }) : title = TextEditingController(text: title),
       location = TextEditingController(text: location),
       description = TextEditingController(text: description),
       date = TextEditingController(text: date),
       time = TextEditingController(text: time),
       image = image ?? const DraftImage();

  final TextEditingController title;
  final TextEditingController location;
  final TextEditingController description;
  final TextEditingController date;
  final TextEditingController time;
  DraftImage image;

  factory _WhenWhereItem.empty() => _WhenWhereItem();

  factory _WhenWhereItem.from(WhenWhereDraft d) => _WhenWhereItem(
    title: d.title,
    location: d.location,
    description: d.description,
    date: d.date,
    time: d.time,
    image: d.image,
  );

  WhenWhereDraft toDraft() => WhenWhereDraft(
    title: title.text.trim(),
    location: location.text.trim(),
    description: description.text.trim(),
    date: date.text.trim(),
    time: time.text.trim(),
    image: image,
  );

  void dispose() {
    title.dispose();
    location.dispose();
    description.dispose();
    date.dispose();
    time.dispose();
  }
}
