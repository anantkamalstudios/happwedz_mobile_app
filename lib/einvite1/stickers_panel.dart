import 'package:flutter/material.dart';


class StickersPanel extends StatelessWidget {
  const StickersPanel({super.key});


  @override
  Widget build(BuildContext context) {
// List of local sticker asset filenames - place images in assets/stickers/
    final stickers = [
      'assets/stickers/heart.png',
      'assets/stickers/ring.png',
      'assets/stickers/flower.png',
    ];
    return SizedBox(
      height: 220,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, childAspectRatio: 1),
        itemCount: stickers.length,
        itemBuilder: (context, index) {
          final s = stickers[index];
          return GestureDetector(
            onTap: () {
// Return selected sticker path to editor via Navigator.pop or provider
              Navigator.pop(context, s);
            },
            child: Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset(s))),
          );
        },
      ),
    );
  }
}