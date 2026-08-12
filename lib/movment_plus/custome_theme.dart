
import 'package:flutter/material.dart';

class MpTheme {
  static const Color pink = Color(0xFFFF69B4);
  static Color primaryColor = Color(0xFFC31162);
  static const Color lightPink = Color(0xFFFFB6C1);
  static const Color cardPink = Color(0xFFFFEFF5);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [pink, lightPink, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.3, 0.6],
  );

  static BoxDecoration premiumCard({Border? border}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [cardPink, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(0),
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 6),
        )
      ],
    );
  }

  static ButtonStyle pinkButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}