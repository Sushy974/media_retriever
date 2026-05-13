import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:media_retriever/src/web_media_picker_dialog.dart';

Future<List<XFile>> recupereMediasPlatform(
  BuildContext context, {
  required MediaKind kind,
  int? limit,
  List<String>? fileExtensions,
}) async {
  if (!context.mounted) return <XFile>[];

  final result = await showDialog<List<XFile>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => WebMediaPickerDialog(limit: limit, kind: kind),
  );

  return result ?? <XFile>[];
}
