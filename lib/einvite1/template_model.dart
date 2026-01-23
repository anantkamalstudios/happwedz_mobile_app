
import 'editablefield.dart';


class EInviteTemplate {
  final String id;
  final String name;
  final String backgroundUrl;
  final String thumbnailUrl;
  final List<EditableField> editableFields;


  EInviteTemplate({
    required this.id,
    required this.name,
    required this.backgroundUrl,
    required this.thumbnailUrl,
    required this.editableFields,
  });


  factory EInviteTemplate.fromJson(Map<String, dynamic> json) {
    return EInviteTemplate(
      id: json['id'],
      name: json['name'] ?? '',
      backgroundUrl: json['backgroundUrl'] ?? json['background_url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? '',
      editableFields: (json['editableFields'] as List?)
          ?.map((e) => EditableField.fromJson(e))
          .toList() ??
          [],
    );
  }
}