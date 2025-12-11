import 'package:flutter/material.dart';

import 'editablefield.dart';


class EditableTextWidget extends StatelessWidget {
  final EditableField field;
  final VoidCallback? onTap;


  const EditableTextWidget({super.key, required this.field, this.onTap});


  @override
  Widget build(BuildContext context) {
// Map fontFamily names to declared fonts in pubspec
    return Transform(
      transform: Matrix4.identity()
        ..translate(0.0, 0.0)
        ..rotateZ(field.rotation)
        ..scale(field.scale),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          field.text,
          style: TextStyle(
            fontSize: field.fontSize,
            fontFamily: field.fontFamily,
            color: _hexToColor(field.color),
            shadows: [const Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))],
          ),
        ),
      ),
    );
  }


  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    final v = int.parse(h.length == 6 ? 'FF\$h' : h, radix: 16);
    return Color(v);
  }
}