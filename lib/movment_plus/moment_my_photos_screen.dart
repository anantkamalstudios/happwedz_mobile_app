/// Shows the AI face-matching results for a guest's uploaded selfie against
/// one gallery token. Matching happens server-side and is slow (see
/// `MovmentPlusApi.getMyPhotos`), so this screen leans on an explicit "this
/// can take a minute or two" message rather than a bare spinner — mirroring
/// the website's `MovmentPlusGallery` "My Photos" view.
library;

import 'package:flutter/material.dart';

import '../core/core.dart';
import 'custome_theme.dart';
import 'full_image_viewer.dart';
import 'movment_plus_api.dart';
import 'upload_selfie_screen.dart';

class MomentMyPhotos extends StatefulWidget {
  const MomentMyPhotos({super.key, required this.token});

  final String token;

  @override
  State<MomentMyPhotos> createState() => _MomentMyPhotosState();
}

class _MomentMyPhotosState extends State<MomentMyPhotos> {
  late Future<MyPhotosResult> _future;

  @override
  void initState() {
    super.initState();
    _future = MovmentPlusApi.getMyPhotos(token: widget.token);
  }

  void _retry() {
    setState(() {
      _future = MovmentPlusApi.getMyPhotos(token: widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MpTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "My Photos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<MyPhotosResult>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _StatusCard(
                        icon: Icons.hourglass_top_rounded,
                        title: "Looking for you in this gallery...",
                        body:
                            "This can take a minute or two — please keep this page open.",
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: CircularProgressIndicator(
                            color: MpTheme.primaryColor,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _StatusCard(
                        icon: Icons.error_outline_rounded,
                        title: "Something went wrong",
                        body: snapshot.error.toString(),
                        child: _retryButton("Try again", _retry),
                      );
                    }

                    final result = snapshot.data!;
                    if (result.matches.isEmpty) {
                      return _StatusCard(
                        icon: Icons.search_off_rounded,
                        title: "No photos found yet",
                        body:
                            result.message ??
                            "We could not find you in these photos yet.",
                        child: _retryButton(
                          "Try another selfie",
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MomentFindPhotos(token: widget.token),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "Found you in ${result.matches.length} photo${result.matches.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            itemCount: result.matches.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (context, index) {
                              final match = result.matches[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullImageViewer(
                                      imageUrl: match.photoUrl,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: NetworkImageWidget(
                                    url: match.photoUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _retryButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: ElevatedButton(
        style: MpTheme.pinkButton(),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: MpTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
