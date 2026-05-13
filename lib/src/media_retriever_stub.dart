import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_retriever/src/media_kind.dart';

Future<List<XFile>> recupereMediasPlatform(
  BuildContext context, {
  required MediaKind kind,
  int? limit,
  List<String>? fileExtensions,
}) {
  throw UnsupportedError('Platform not supported');
}
