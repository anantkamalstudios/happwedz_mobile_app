import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final List<Uint8List>? frames; // for GIF/MP4
  const PreviewScreen({super.key, required this.bytes, this.frames});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: Column(
          children: [
            Expanded(child: Center(child: Image.memory(bytes))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async => await _shareImage(bytes),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    onPressed: (){},
                    // onPressed: () async => await _saveToGallery(context, bytes),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  // const SizedBox(width: 8),
                  //
                  // ElevatedButton.icon(
                  //   onPressed: () async => await _exportGifOrMp4(context),
                  //   icon: const Icon(Icons.movie),
                  //   label: const Text('Export GIF/MP4'),
                  // ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _shareImage(Uint8List bytes) async {
    final tmp = await getTemporaryDirectory();
    final file = File("${tmp.path}/invite.png");
    await file.writeAsBytes(bytes);

    // AUDIT FIX (deprecation): `Share.shareXFiles` is deprecated in
    // share_plus 12.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: "My HappyWedz Invite 💖",
      ),
    );
  }

  // Future<void> _saveToGallery(BuildContext context, Uint8List bytes) async {
  //   final result = await MediaStore.saveImage(
  //     bytes,
  //     fileName: "invite_${DateTime.now().millisecondsSinceEpoch}.png",
  //     msDirectory: MsDirectory.pictures,
  //     relativePath: "HappyWedz",
  //   );
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(result != null ? "Saved to Gallery 🎉" : "Failed to save"),
  //     ),
  //   );
  // }

  Future<void> _exportGifOrMp4(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("GIF/MP4 export coming soon")),
    );
  }
}
