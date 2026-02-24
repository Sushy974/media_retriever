import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:media_retriever/src/media_permissions.dart';
import 'package:media_retriever/src/media_picker_sheet.dart';

abstract interface class MediaRetrieverImpl {
  static MediaPermissions permissions = MediaPermissionsImpl();

  static Future<List<File>> recupereMedias(
    BuildContext context, {
    int? limit,
    required MediaKind kind,
  }) async {
    final granted = await permissions.requestForKind(kind);
    if (!granted || !context.mounted) return <File>[];

    final result = await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MediaPickerSheet(limit: limit, kind: kind),
    );

    return result ?? <File>[];
  }
}
