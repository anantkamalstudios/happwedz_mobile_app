/// Guest-facing published wedding website — no login required.
///
/// Ports `src/components/pages/WeddingPublicView.jsx`: fetch by slug via
/// `GET weddingwebsite/wedding/:websiteUrl` and render the matching template.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/core.dart';
import '../data/wedding_website_api.dart';
import '../models/wedding_website_models.dart';
import 'templates/wedding_template_view.dart';

class WeddingPublicViewPage extends StatefulWidget {
  const WeddingPublicViewPage({super.key, required this.websiteUrl});

  final String websiteUrl;

  @override
  State<WeddingPublicViewPage> createState() => _WeddingPublicViewPageState();
}

class _WeddingPublicViewPageState extends State<WeddingPublicViewPage> {
  final _api = WeddingWebsiteApi();

  bool _loading = true;
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
      final data = await _api.fetchPublicWebsite(widget.websiteUrl);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: (_data != null)
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: 'Join us in celebrating our special day! '
                      '${WeddingWebsiteApi.publicUrlFor(widget.websiteUrl)}',
                ),
              ),
              child: const Icon(Icons.share_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: AsyncView(
          isLoading: _loading,
          error: _error,
          errorTitle: 'Website Not Found',
          errorMessage: "This wedding website is not available or hasn't been published yet.",
          onRetry: _load,
          child: _data == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(child: WeddingTemplateView(data: _data!)),
        ),
      ),
    );
  }
}
