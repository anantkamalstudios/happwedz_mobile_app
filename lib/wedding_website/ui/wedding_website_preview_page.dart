/// Owner's preview of one of their own wedding websites — the same template
/// rendering the public view uses, fetched through the authenticated
/// `GET wedding-websites/:id` endpoint so a draft can be previewed before
/// publishing (`src/components/pages/WeddingWebsiteView.jsx`'s live code,
/// from line ~469 in the source — everything above that is dead/commented).
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/core.dart';
import '../data/wedding_website_api.dart';
import '../models/wedding_website_models.dart';
import 'templates/wedding_template_view.dart';

class WeddingWebsitePreviewPage extends StatefulWidget {
  const WeddingWebsitePreviewPage({super.key, required this.id});

  final String id;

  @override
  State<WeddingWebsitePreviewPage> createState() => _WeddingWebsitePreviewPageState();
}

class _WeddingWebsitePreviewPageState extends State<WeddingWebsitePreviewPage> {
  final _api = WeddingWebsiteApi();

  bool _loading = true;
  bool _publishing = false;
  Object? _error;
  WeddingWebsiteDetail? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchWebsite(widget.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final result = await _api.publishWebsite(widget.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      AppSnackbar.success(context, 'Your wedding website is now live and ready to share!');
      final share = await ConfirmPopup.show(
        context,
        title: 'Published!',
        message: 'Share it now?',
        confirmLabel: 'Share Now',
        cancelLabel: 'Later',
      );
      if (share && mounted) {
        await SharePlus.instance.share(ShareParams(text: result.publicUrl));
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: 'Preview',
        actions: [
          if (data != null)
            IconButton(
              tooltip: data.isPublished ? 'Share' : 'Publish first to share',
              icon: const Icon(Icons.share_rounded),
              onPressed: data.isPublished
                  ? () => SharePlus.instance.share(
                      ShareParams(text: WeddingWebsiteApi.publicUrlFor(data.websiteUrl)),
                    )
                  : null,
            ),
        ],
      ),
      floatingActionButton: (data != null && !data.isPublished)
          ? FloatingActionButton.extended(
              onPressed: _publishing ? null : _publish,
              backgroundColor: AppColors.primary,
              icon: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.public_rounded, color: Colors.white),
              label: const Text('Publish', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: AsyncView(
        isLoading: _loading,
        error: _error,
        onRetry: _load,
        child: data == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(child: WeddingTemplateView(data: data)),
      ),
    );
  }
}
