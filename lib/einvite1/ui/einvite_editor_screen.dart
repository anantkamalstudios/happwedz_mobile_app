/// The e-invite card editor — port of the website's card editor
/// (`EinviteEditorPage`, route `/einvites/editor/:id`), laid out for a phone.
///
/// Same behaviour as the web, on purpose, so a card moves between the two
/// without surprises:
///   * opens a template *or* the customer's saved copy by id;
///   * refuses a saved copy owned by another account;
///   * the customer edits each field's text and size (A− / A+ scale by 0.92 /
///     1.08, clamped to 4–400) — positions, fonts and colours stay as the
///     designer set them, which is what keeps the layout intact;
///   * the first save of a template creates the customer's own copy
///     (`POST cards/instances`); later saves update it
///     (`PUT cards/:id/instance`);
///   * "Save & share" saves if needed, then offers the guest link.
///
/// Replaces the previous editor, which placed design-version-2 fields as raw
/// pixels (every field piled into the top-left corner) and could only save
/// drafts to this phone.
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/core.dart';
import '../../main.dart' show requireAuthentication;
import '../data/einvite_api.dart';
import '../data/einvite_design.dart';
import 'einvite_page_view.dart';
import 'einvite_share_sheet.dart';

class EinviteEditorScreen extends StatefulWidget {
  const EinviteEditorScreen({super.key, required this.cardId, this.api});

  /// A template id/slug, or the id of the customer's saved copy.
  final String cardId;

  /// Injected in tests.
  final EinviteApi? api;

  @override
  State<EinviteEditorScreen> createState() => _EinviteEditorScreenState();
}

class _EinviteEditorScreenState extends State<EinviteEditorScreen> {
  late final EinviteApi _api = widget.api ?? EinviteApi();

  final TextEditingController _name = TextEditingController();
  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, GlobalKey> _fieldKeys = {};

  Map<String, dynamic>? _card;
  List<EinvitePage> _pages = const [];
  String _userId = '';

  bool _loading = true;
  String? _error;
  int _pageIndex = 0;
  String? _focusedFieldId;
  bool _saving = false;
  bool _dirty = false;

  /// True while pages are being rendered to images: hides the selection
  /// outline so it is never baked into an exported card.
  bool _exporting = false;

  bool get _isTemplate => _card?['isTemplate'] == true;

  /// Port of the web's `T` — a design sold rather than free.
  bool get _isPaid {
    final pricing = _card?['pricing'];
    return pricing is Map && pricing['isPaid'] == true;
  }

  /// Port of the web's `M`: a template is usable when it is free; a saved
  /// copy when it has not been marked locked.
  bool get _isUnlocked =>
      _isTemplate ? !_isPaid : _card?['isUnlocked'] != false;

  EinvitePage get _page => _pages[_pageIndex];

  String get _cardName {
    final typed = _name.text.trim();
    if (typed.isNotEmpty) return typed;
    final saved = _card?['name'];
    return saved is String ? saved : '';
  }

  String get _status {
    if (_saving) return 'Saving...';
    if (_dirty) return 'Unsaved changes';
    if (_isTemplate) return 'Not saved yet';
    return 'All changes saved';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = await _api.currentUserId();
      final card = await _api.getCard(widget.cardId);

      final owner = card['ownerUserId'];
      if (card['isTemplate'] == false &&
          owner != null &&
          '$owner'.isNotEmpty &&
          userId.isNotEmpty &&
          '$owner' != userId) {
        throw EinviteApiException(
          'This invitation belongs to another account.',
        );
      }

      final pages = getCardPages(card);
      if (pages.isEmpty) {
        throw EinviteApiException('This invitation has no pages.');
      }

      if (!mounted) return;
      _bindFields(pages);
      setState(() {
        _userId = userId;
        _card = card;
        _pages = pages;
        _name.text = card['name'] is String ? card['name'] as String : '';
        _pageIndex = 0;
        _focusedFieldId = null;
        _dirty = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is EinviteApiException
            ? e.message
            : 'Failed to load the invitation.';
        _loading = false;
      });
    }
  }

  /// One text controller, focus node and scroll anchor per field, across
  /// every page, so switching pages keeps what was typed.
  void _bindFields(List<EinvitePage> pages) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _fieldKeys.clear();

    for (final page in pages) {
      for (final field in page.fields) {
        _controllers[field.id] = TextEditingController(text: field.defaultText);
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus && _focusedFieldId != field.id && mounted) {
            setState(() => _focusedFieldId = field.id);
          }
        });
        _focusNodes[field.id] = node;
        _fieldKeys[field.id] = GlobalKey();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------------------

  void _onTextChanged(EinviteField field, String text) {
    setState(() {
      field.defaultText = text;
      _dirty = true;
    });
  }

  /// Port of the web's `resizeField`: scale, round to one decimal, clamp.
  void _resize(EinviteField field, double factor) {
    final next = (field.fontSize * factor * 10).round() / 10;
    setState(() {
      field.fontSize = next.clamp(4, 400).toDouble();
      _dirty = true;
    });
  }

  /// Tapping text on the card jumps to its input, as on the website.
  void _focusField(EinviteField field) {
    setState(() => _focusedFieldId = field.id);
    _focusNodes[field.id]?.requestFocus();
    final anchor = _fieldKeys[field.id]?.currentContext;
    if (anchor != null) {
      Scrollable.ensureVisible(
        anchor,
        duration: AppMotion.normal,
        alignment: 0.3,
      );
    }
  }

  void _showPage(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _pageIndex = index;
      _focusedFieldId = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Saving and sharing
  // ---------------------------------------------------------------------------

  /// Port of the web's `save`. Returns the saved card, or null on failure.
  Future<Map<String, dynamic>?> _save() async {
    final card = _card;
    if (card == null || _saving) return null;

    if (_userId.isEmpty) {
      // A guest can design freely; saving needs an account. Sign-in opens on
      // top of the editor, so every edit is still here afterwards.
      final signedIn = await requireAuthentication(
        context,
        reason: 'Sign in to save your invitation.',
      );
      if (!signedIn || !mounted) return null;
      _userId = await _api.currentUserId();
      if (!mounted || _userId.isEmpty) return null;
    }

    setState(() => _saving = true);
    try {
      final Map<String, dynamic> saved;
      if (_isTemplate) {
        saved = await _api.createInstance(
          name: _cardName,
          pages: _pages,
          originalTemplateId: '${card['id']}',
          ownerUserId: _userId,
        );
      } else {
        saved = await _api.updateInstance(
          '${card['id']}',
          name: _cardName,
          pages: _pages,
        );
        // Keep addressing the same card if the reply omits its id.
        saved['id'] ??= card['id'];
      }

      if (!mounted) return saved;
      final wasTemplate = _isTemplate;
      setState(() {
        // Replaced, as the web does: from here on the card is the customer's
        // own copy, so the next save updates it instead of copying again.
        _card = saved;
        _dirty = false;
      });
      AppSnackbar.success(
        context,
        wasTemplate ? 'Saved to Your Cards' : 'Invitation saved',
      );
      return saved;
    } on EinviteApiException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Port of the web's `saveAndShare`, including the paid-design check the
  /// website makes before sharing.
  Future<void> _saveAndShare() async {
    final saved = (_dirty || _isTemplate) ? await _save() : _card;
    if (!mounted || saved == null || saved['id'] == null) return;

    if (!_isUnlocked) {
      _explainLocked();
      return;
    }

    await showEinviteShareSheet(
      context,
      cardId: '${saved['id']}',
      cardName: _cardName,
      exportImages: () => _exportPages(all: true),
    );
  }

  Future<void> _shareImage() async {
    if (!_isUnlocked) {
      _explainLocked();
      return;
    }

    var all = true;
    if (_pages.length > 1) {
      final choice = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop_portrait_rounded),
                title: const Text('This page'),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined),
                title: Text('All ${_pages.length} pages'),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      all = choice;
    }

    try {
      final images = await _exportPages(all: all);
      if (images.isEmpty || !mounted) return;
      await shareEinviteImages(images, _cardName);
    } catch (e) {
      debugPrint('[EinviteEditor] image export failed: $e');
      if (mounted) {
        AppSnackbar.error(context, "Couldn't create the image. Please try again.");
      }
    }
  }

  void _explainLocked() {
    AppSnackbar.info(
      context,
      'This is a premium design. Unlock it on happywedz.com to share it.',
    );
  }

  /// Renders pages to PNG at the 1000-px design width.
  ///
  /// Each page is shown in turn and captured once its background and fonts
  /// have loaded, then the page the customer was on is restored.
  Future<List<Uint8List>> _exportPages({required bool all}) async {
    final original = _pageIndex;
    final indices = all
        ? List<int>.generate(_pages.length, (i) => i)
        : <int>[_pageIndex];

    setState(() => _exporting = true);
    final images = <Uint8List>[];
    try {
      for (final index in indices) {
        if (index != _pageIndex) setState(() => _pageIndex = index);
        images.add(await _capturePage(index));
      }
    } finally {
      if (mounted) {
        setState(() {
          _pageIndex = original;
          _exporting = false;
        });
      }
    }
    return images;
  }

  Future<Uint8List> _capturePage(int index) async {
    final background = _pages[index].backgroundUrl;
    if (background.isNotEmpty) {
      try {
        await precacheImage(NetworkImage(background), context);
      } catch (_) {
        // Export without it; the backdrop colour still gives a clean card.
      }
    }
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}

    // One frame to lay out the page, one to paint the cached image.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.size.width == 0) {
      throw StateError('card canvas not laid out');
    }
    final ratio = (kDesignWidth / boundary.size.width).clamp(1.0, 6.0);
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('png encoding failed');
    return data.buffer.asUint8List();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your latest changes are not saved yet. Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ready = !_loading && _error == null && _pages.isNotEmpty;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Edit invitation', style: AppText.pageTitle),
        ),
        body: _loading
            ? const AppLoader()
            : _error != null
                ? ErrorState(
                    title: "Can't open this invitation",
                    message: _error,
                    onRetry: _load,
                  )
                : _buildEditor(),
        bottomNavigationBar: ready ? _buildActions() : null,
      ),
    );
  }

  Widget _buildEditor() {
    final page = _page;
    final multiPage = _pages.length > 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        TextField(
          controller: _name,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Invitation name',
            counterText: '',
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _status,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ConstrainedBox(
            // A card wider than this only makes the text panel scroll further
            // away on tablets; the design scales, so nothing is lost.
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: _canvasKey,
                child: EinvitePageView(
                  page: page,
                  selectedFieldId: _exporting ? null : _focusedFieldId,
                  onFieldTap: _focusField,
                ),
              ),
            ),
          ),
        ),
        if (multiPage) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed:
                    _pageIndex == 0 ? null : () => _showPage(_pageIndex - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                'Page ${_pageIndex + 1} of ${_pages.length}',
                style: AppText.labelSm,
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: _pageIndex == _pages.length - 1
                    ? null
                    : () => _showPage(_pageIndex + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap any text on the card to edit it.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
        if (!_isUnlocked) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: AppRadii.rMd,
            ),
            child: Text(
              'This is a premium design. You can edit and save it here; '
              'unlock it on happywedz.com to share it.',
              style: AppText.caption,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildFieldPanel(page, multiPage),
      ],
    );
  }

  Widget _buildFieldPanel(EinvitePage page, bool multiPage) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            multiPage
                ? 'Page ${_pageIndex + 1} of ${_pages.length}'
                : 'Your details',
            style: AppText.cardTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Change the text below. The card updates as you type.',
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (page.fields.isEmpty)
            Text(
              'This page has no text to edit.',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final field in page.fields) _buildFieldEditor(field),
        ],
      ),
    );
  }

  Widget _buildFieldEditor(EinviteField field) {
    final focused = field.id == _focusedFieldId;

    return Padding(
      key: _fieldKeys[field.id],
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelSm.copyWith(
                    color: focused ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              _SizeButton(
                label: 'A−',
                tooltip: 'Smaller text for ${field.label}',
                onTap: () => _resize(field, 0.92),
              ),
              const SizedBox(width: AppSpacing.xs),
              _SizeButton(
                label: 'A+',
                tooltip: 'Larger text for ${field.label}',
                onTap: () => _resize(field, 1.08),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controllers[field.id],
            focusNode: _focusNodes[field.id],
            maxLength: field.maxLength,
            minLines: 1,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              hintText: field.label,
            ),
            onChanged: (text) => _onTextChanged(field, text),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canSave = !_saving && (_dirty || _isTemplate);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PremiumButton(
                label: 'Image',
                variant: PremiumButtonVariant.outlined,
                size: PremiumButtonSize.medium,
                enabled: !_saving && !_exporting,
                onPressed: _shareImage,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: PremiumButton(
                label: 'Save',
                variant: PremiumButtonVariant.outlined,
                size: PremiumButtonSize.medium,
                enabled: canSave,
                isLoading: _saving,
                onPressed: _save,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: PremiumButton(
                label: 'Save & share',
                size: PremiumButtonSize.medium,
                enabled: !_saving,
                onPressed: _saveAndShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadii.rSm,
          ),
          child: Text(label, style: AppText.labelSm),
        ),
      ),
    );
  }
}
