import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:media_retriever/src/media_permissions.dart';
import 'package:media_retriever/src/media_picker_sheet.dart';

final MediaPermissions _permissions = MediaPermissionsImpl();

Future<List<XFile>> recupereMediasPlatform(
  BuildContext context, {
  required MediaKind kind,
  int? limit,
  List<String>? fileExtensions,
}) async {
  final granted = await _permissions.requestForKind(kind);
  if (!granted || !context.mounted) return <XFile>[];

  final result = await showModalBottomSheet<List<XFile>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => MediaPickerSheet(
      limit: limit,
      kind: kind,
      fileExtensions: fileExtensions,
    ),
  );

  return result ?? <XFile>[];
}
