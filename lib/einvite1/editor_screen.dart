

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wedz/einvite1/template_model.dart';
import 'package:uuid/uuid.dart';

import 'draftscreen.dart';
import 'editablefield.dart';
import 'preview_screen.dart';


import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';

import 'editablefield.dart';
import 'preview_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final EInviteTemplate template;
  final List<EditableField>? initialFields;

  const EditorScreen({super.key, required this.template,  this.initialFields});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final GlobalKey repaintKey = GlobalKey();
  EditableField? selectedField;

  late List<EditableField> fields;

  @override
  void initState() {
    super.initState();

    if (widget.initialFields != null) {
      fields = widget.initialFields!;
    } else {
      fields = widget.template.editableFields.map((e) {
        return EditableField(
          x: e.x,
          y: e.y,
          id: e.id,
          color: e.color,
          label: e.label,
          fontSize: e.fontSize,
          fontFamily: e.fontFamily,
          text: e.text,
          rotation: e.rotation,
          scale: e.scale,
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.template.backgroundUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(onPressed: saveDraft, icon: const Icon(Icons.save_alt)),
          IconButton(onPressed: exportAsImage, icon: const Icon(Icons.download)),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addTextField,
        child: const Icon(Icons.text_fields),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: AspectRatio(
            aspectRatio: 3 / 5,
            child: RepaintBoundary(
              key: repaintKey,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(bg, fit: BoxFit.cover),
                  ),

                  ...fields.map((f) => _buildTextWidget(f)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // BUILD MOVABLE TEXT FIELD
  Widget _buildTextWidget(EditableField f) {
    return Positioned(
      left: f.x,
      top: f.y,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            f.x += d.delta.dx;
            f.y += d.delta.dy;
          });
        },
        onTap: () => openEditSheet(f),
        onDoubleTap: () => openEditSheet(f),

        child: Transform.rotate(
          angle: f.rotation,
          child: Transform.scale(
            scale: f.scale,
            child: Text(
              f.text,
              style: TextStyle(
                fontSize: f.fontSize,
                fontFamily: f.fontFamily,
                color: _hexToColor(f.color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ADD NEW TEXT FIELD
  void addTextField() {
    final id = const Uuid().v4();
    final newField = EditableField(
      id: id,
      x: 40,
      y: 40,
      label: "New Text",
      text: "New Text",
      fontSize: 30,
      fontFamily: "Arial",
      color: "#000000",
      rotation: 0,
      scale: 1,
    );

    setState(() => fields.add(newField));
    Future.delayed(const Duration(milliseconds: 200), () {
      openEditSheet(newField);
    });
  }

  // COLOR STRING TO COLOR
  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }

  // BOTTOM EDIT SHEET
  void openEditSheet(EditableField f) {
    TextEditingController controller = TextEditingController(text: f.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // TEXT INPUT
                      TextField(
                        controller: controller,
                        onChanged: (v) {
                          setSheet(() => f.text = v);
                          setState(() {});
                        },
                        decoration: InputDecoration(labelText: f.label),
                      ),

                      const SizedBox(height: 12),

                      // Font Size
                      Row(
                        children: [
                          const Text("Font Size"),
                          Expanded(
                            child: Slider(
                              value: f.fontSize,
                              min: 10,
                              max: 120,
                              onChanged: (v) {
                                setSheet(() => f.fontSize = v);
                                setState(() {});
                              },
                            ),
                          ),
                          Text(f.fontSize.toStringAsFixed(0)),
                        ],
                      ),

                      // Scale
                      Row(
                        children: [
                          const Text("Scale"),
                          Expanded(
                            child: Slider(
                              value: f.scale,
                              min: 0.5,
                              max: 3,
                              onChanged: (v) {
                                setSheet(() => f.scale = v);
                                setState(() {});
                              },
                            ),
                          ),
                          Text(f.scale.toStringAsFixed(2)),
                        ],
                      ),

                      // Rotation
                      Row(
                        children: [
                          const Text("Rotate"),
                          Expanded(
                            child: Slider(
                              value: f.rotation,
                              min: -3.14,
                              max: 3.14,
                              onChanged: (v) {
                                setSheet(() => f.rotation = v);
                                setState(() {});
                              },
                            ),
                          ),
                          Text("${(f.rotation * 57.29).toStringAsFixed(0)}°"),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // COLOR PICKER
                      ElevatedButton.icon(
                        onPressed: () async {
                          Color selected = _hexToColor(f.color);

                          await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text("Pick Color"),
                              content: ColorPicker(
                                pickerColor: selected,
                                onColorChanged: (c) {
                                  selected = c;
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Done")),
                              ],
                            ),
                          );

                          setSheet(() {
                            f.color = "#${selected.value.toRadixString(16).padLeft(8, '0')}";
                          });
                          setState(() {});
                        },
                        icon: const Icon(Icons.color_lens),
                        label: const Text("Text Color"),
                      ),

                      const SizedBox(height: 12),

                      // DELETE BUTTON
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => fields.remove(f));
                        },
                        icon: const Icon(Icons.delete),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        label: const Text("Delete"),
                      ),

                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // EXPORT IMAGE
  Future<void> exportAsImage() async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(bytes: bytes)),
    );
  }
  Future<String?> generateThumbnail() async {
    final boundary = repaintKey.currentContext?.findRenderObject()
    as RenderRepaintBoundary?;

    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 0.2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return base64Encode(byteData!.buffer.asUint8List());
  }

  Future<void> saveDraft() async {
    final thumbnail = await generateThumbnail();

    final draft = DraftModel(
      templateName: widget.template.name,
      backgroundUrl: widget.template.backgroundUrl,
      fields: fields.map((f) => EditableField(
        id: f.id,
        x: f.x,
        y: f.y,
        label: f.label,
        text: f.text,
        fontSize: f.fontSize,
        fontFamily: f.fontFamily,
        color: f.color,
        rotation: f.rotation,
        scale: f.scale,
      )).toList(),
      thumbnail: thumbnail,
    );

    ref.read(draftsProvider.notifier).addDraft(draft);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft Saved")),
    );
  }

}
