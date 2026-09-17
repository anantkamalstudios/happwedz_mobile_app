import 'dart:io';
import 'package:flutter/material.dart';

import '../core/core.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class FullImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullImageViewer({super.key, required this.imageUrl});

  /// App-private folder to save into. `getExternalStorageDirectory` is
  /// Android-only — on iOS it throws, so fall back to the documents
  /// directory there (and on any Android device that reports no external
  /// storage).
  Future<Directory> _saveDirectory() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();

    final dir = Directory("${base.path}/HappyWedz");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final downloadDir = await _saveDirectory();

      final filePath =
          "${downloadDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await Dio().download(imageUrl, filePath);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image saved inside app storage"),
        ),
      );
    } catch (e) {
      debugPrint("Image download failed: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: NetworkImageWidget(url: imageUrl),
        ),
      ),
    );
  }
}
