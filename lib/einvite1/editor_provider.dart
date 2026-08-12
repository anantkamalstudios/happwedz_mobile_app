import 'package:flutter_riverpod/legacy.dart';
import 'package:happy_wedz/einvite1/template_model.dart';


class EditorState {
  final EInviteTemplate template;
  EditorState(this.template);
}


final editorProvider = StateProvider<EditorState?>((ref) => null);