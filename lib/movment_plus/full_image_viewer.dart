import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FullImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullImageViewer({super.key, required this.imageUrl});

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final dir = await getExternalStorageDirectory();
      final downloadDir = Directory("${dir!.path}/HappyWedz");

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath =
          "${downloadDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await Dio().download(imageUrl, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image saved inside app storage"),
        ),
      );
    } catch (e) {
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
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
