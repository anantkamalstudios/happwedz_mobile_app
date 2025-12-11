import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:happy_wedz/einvite1/editor_screen.dart';
import 'package:happy_wedz/einvite1/template_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editablefield.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Drafts')),
      body: drafts.isEmpty
          ? const Center(child: Text("No drafts saved yet"))
          : ListView.builder(
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final d = drafts[index];

          return ListTile(
            leading: d.thumbnail != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(d.thumbnail!),
                width: 60,
                height: 90,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              width: 60,
              height: 90,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image),
            ),
            title: Text(d.templateName),
            subtitle: Text("${d.fields.length} fields"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DraftEditorScreen(draft: d),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class DraftsNotifier extends StateNotifier<List<DraftModel>> {
  DraftsNotifier() : super([]) {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("drafts") ?? [];

    state = data
        .map((e) => DraftModel.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> persistDrafts() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = state.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList("drafts", jsonList);
  }

  Future<void> addDraft(DraftModel draft) async {
    state = [...state, draft];
    await persistDrafts();
  }

  Future<void> updateDraft(int index, DraftModel draft) async {
    final list = [...state];
    list[index] = draft;
    state = list;

    await persistDrafts();
  }

  Future<void> deleteDraft(int index) async {
    final list = [...state];
    list.removeAt(index);
    state = list;

    await persistDrafts();
  }
}

final draftsProvider =
StateNotifierProvider<DraftsNotifier, List<DraftModel>>((ref) {
  return DraftsNotifier();
});


class DraftModel {
  final String templateName;
  final String backgroundUrl;
  final List<EditableField> fields;
  final String? thumbnail; // Base64 thumbnail image

  DraftModel({
    required this.templateName,
    required this.backgroundUrl,
    required this.fields,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
    "templateName": templateName,
    "backgroundUrl": backgroundUrl,
    "thumbnail": thumbnail,
    "fields": fields.map((f) => f.toJson()).toList(),
  };

  factory DraftModel.fromJson(Map<String, dynamic> json) {
    return DraftModel(
      templateName: json["templateName"],
      backgroundUrl: json["backgroundUrl"],
      thumbnail: json["thumbnail"],
      fields: (json["fields"] as List)
          .map((e) => EditableField.fromJson(e))
          .toList(),
    );
  }
}


class DraftEditorScreen extends ConsumerStatefulWidget {
  final DraftModel draft;

  const DraftEditorScreen({super.key, required this.draft});

  @override
  ConsumerState<DraftEditorScreen> createState() => _DraftEditorScreenState();
}

class _DraftEditorScreenState extends ConsumerState<DraftEditorScreen> {
  late List<EditableField> fields;

  @override
  void initState() {
    super.initState();

    // Restore all fields from draft
    fields = widget.draft.fields.map((e) => EditableField(
      id: e.id,
      x: e.x,
      y: e.y,
      label: e.label,
      text: e.text,
      fontSize: e.fontSize,
      fontFamily: e.fontFamily,
      color: e.color,
      rotation: e.rotation,
      scale: e.scale,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Build fake template for EditorScreen
    final template = EInviteTemplate(
      name: widget.draft.templateName,
      backgroundUrl: widget.draft.backgroundUrl,
      editableFields: [], id: '', thumbnailUrl: '', // we will override with restored fields
    );

    return EditorScreen(
      template: template,
      initialFields: fields,   // <-- You must add this param in EditorScreen
    );
  }
}
