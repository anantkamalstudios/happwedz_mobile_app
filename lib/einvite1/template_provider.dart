
import 'package:happy_wedz/einvite1/template_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'einvities_api.dart';

final einviteApiProvider = Provider((ref) => EInviteAPI());


final templateListProvider = FutureProvider<List<EInviteTemplate>>((ref) async {
  final api = ref.read(einviteApiProvider);
  return api.fetchTemplates();
});