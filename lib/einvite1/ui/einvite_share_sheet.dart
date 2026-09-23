/// "Share your invitation" — port of the website's `EinviteSharePage`
/// actions: WhatsApp, email and copy-link all carry the public guest link
/// (`/einvites/view/:id`), with the web's own message wording, plus the card
/// itself as an image.
///
/// Guests open the link on the website, which renders the saved card — the
/// app does not need its own guest view.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../data/einvite_api.dart';

/// Renders the card's pages to PNGs on demand (the editor owns the canvas).
typedef EinviteImageExporter = Future<List<Uint8List>> Function();

/// Hands rendered card pages to the system share sheet — on a phone that is
/// both "download" (save to Photos/Files) and "send" (WhatsApp etc.).
Future<void> shareEinviteImages(List<Uint8List> images, String cardName) {
  final base = _fileBase(cardName);
  return SharePlus.instance.share(
    ShareParams(
      files: [
        for (var i = 0; i < images.length; i++)
          XFile.fromData(
            images[i],
            mimeType: 'image/png',
            name: images.length == 1 ? '$base.png' : '$base-${i + 1}.png',
          ),
      ],
      text: cardName,
    ),
  );
}

String _fileBase(String name) {
  final cleaned = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return cleaned.isEmpty ? 'invitation' : cleaned;
}

Future<void> showEinviteShareSheet(
  BuildContext context, {
  required String cardId,
  required String cardName,
  EinviteImageExporter? exportImages,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (_) => EinviteShareSheet(
      cardId: cardId,
      cardName: cardName,
      exportImages: exportImages,
    ),
  );
}

class EinviteShareSheet extends StatefulWidget {
  const EinviteShareSheet({
    super.key,
    required this.cardId,
    required this.cardName,
    this.exportImages,
  });

  final String cardId;
  final String cardName;
  final EinviteImageExporter? exportImages;

  @override
  State<EinviteShareSheet> createState() => _EinviteShareSheetState();
}

class _EinviteShareSheetState extends State<EinviteShareSheet> {
  bool _exporting = false;

  String get _url => einviteViewUrl(widget.cardId);

  Future<void> _whatsApp() async {
    final message = "You're invited! View our wedding invitation: $_url";
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    final opened = await _launch(uri);
    if (!opened && mounted) {
      // No WhatsApp: fall back to whatever the phone can share with.
      await SharePlus.instance.share(ShareParams(text: message));
    }
  }

  Future<void> _email() async {
    final subject =
        widget.cardName.trim().isEmpty ? 'Wedding Invitation' : widget.cardName;
    final body =
        "You're invited to our wedding! View the invitation here: $_url";
    final uri = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    final opened = await _launch(uri);
    if (!opened && mounted) {
      AppSnackbar.error(context, 'No email app is set up on this phone.');
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) AppSnackbar.success(context, 'Link copied');
  }

  Future<void> _shareLink() async {
    await SharePlus.instance.share(
      ShareParams(
        text: "You're invited! View our wedding invitation: $_url",
        subject: widget.cardName,
      ),
    );
  }

  Future<void> _shareImage() async {
    final export = widget.exportImages;
    if (export == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final images = await export();
      if (images.isEmpty) throw StateError('no pages rendered');
      await shareEinviteImages(images, widget.cardName);
    } catch (e) {
      debugPrint('[EinviteShareSheet] image export failed: $e');
      if (mounted) {
        AppSnackbar.error(
          context,
          "Couldn't create the image. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadii.rPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Share your invitation', style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Guests open this link to see your card.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadii.rMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ShareTile(
              icon: Icons.chat_rounded,
              label: 'Share on WhatsApp',
              onTap: _whatsApp,
            ),
            _ShareTile(
              icon: Icons.email_outlined,
              label: 'Share by email',
              onTap: _email,
            ),
            _ShareTile(
              icon: Icons.ios_share_rounded,
              label: 'Share link with other apps',
              onTap: _shareLink,
            ),
            if (widget.exportImages != null)
              _ShareTile(
                icon: Icons.image_outlined,
                label: _exporting ? 'Preparing image…' : 'Share as image',
                onTap: _exporting ? null : _shareImage,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.blush,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppText.bodyLg),
      trailing: const Icon(Icons.chevron_right_rounded),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}
