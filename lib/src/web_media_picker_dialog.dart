import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:path/path.dart' as p;

class WebMediaPickerDialog extends StatefulWidget {
  const WebMediaPickerDialog({
    super.key,
    this.limit,
    this.kind = MediaKind.any,
  });

  final int? limit;
  final MediaKind kind;

  @override
  State<WebMediaPickerDialog> createState() => _WebMediaPickerDialogState();
}

class _WebMediaPickerDialogState extends State<WebMediaPickerDialog> {
  final List<_SelectedFile> _selectedFiles = [];
  bool _isDragging = false;

  static const _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tif',
    'tiff',
    'avif',
    'svg',
  ];

  static const _videoExtensions = [
    'mp4',
    'm4v',
    'mov',
    'avi',
    'mkv',
    'flv',
    'wmv',
    'webm',
    'mpeg',
    'mpg',
    '3gp',
  ];

  List<String> get _allowedExtensions {
    switch (widget.kind) {
      case MediaKind.photo:
        return _imageExtensions;
      case MediaKind.video:
        return _videoExtensions;
      case MediaKind.any:
        return [..._imageExtensions, ..._videoExtensions];
    }
  }

  bool _isAllowedFile(String name) {
    final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
    return _allowedExtensions.contains(ext);
  }

  bool _isImageFile(String name) {
    final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
    return _imageExtensions.contains(ext);
  }

  bool get _isLimitReached =>
      widget.limit != null && _selectedFiles.length >= widget.limit!;

  Future<void> _browseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null) return;

    for (final pf in result.files) {
      if (pf.bytes == null) continue;
      if (_isLimitReached) break;
      _addFile(
        XFile.fromData(pf.bytes!, name: pf.name),
        pf.bytes!,
      );
    }
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    for (final xfile in details.files) {
      if (_isLimitReached) break;
      if (!_isAllowedFile(xfile.name)) continue;
      await _addDroppedFile(xfile);
    }
  }

  Future<void> _addDroppedFile(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    _addFile(xfile, bytes);
  }

  void _addFile(XFile xfile, Uint8List bytes) {
    setState(() {
      _selectedFiles.add(_SelectedFile(xfile: xfile, bytes: bytes));
    });
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _validate() {
    Navigator.of(context).pop(
      _selectedFiles.map((sf) => sf.xfile).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter des médias',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDropZone(theme),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLimitReached ? null : _browseFiles,
                icon: const Icon(Icons.folder_open),
                label: const Text('Parcourir les fichiers'),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFileCount(theme),
                const SizedBox(height: 8),
                Flexible(child: _buildSelectedFilesGrid()),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedFiles.isEmpty ? null : _validate,
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone(ThemeData theme) {
    return DropTarget(
      onDragDone: _onDrop,
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging
                ? theme.colorScheme.primary
                : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _isDragging
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: _isDragging
                    ? theme.colorScheme.primary
                    : Colors.grey.shade500,
              ),
              const SizedBox(height: 8),
              Text(
                'Glissez-déposez vos fichiers ici',
                style: TextStyle(
                  color: _isDragging
                      ? theme.colorScheme.primary
                      : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _kindLabel,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _kindLabel {
    switch (widget.kind) {
      case MediaKind.photo:
        return 'Images uniquement';
      case MediaKind.video:
        return 'Vidéos uniquement';
      case MediaKind.any:
        return 'Images et vidéos';
    }
  }

  Widget _buildFileCount(ThemeData theme) {
    final count = _selectedFiles.length;
    final limitText = widget.limit != null ? ' / ${widget.limit}' : '';
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$count$limitText fichier${count > 1 ? 's' : ''}'
        ' sélectionné${count > 1 ? 's' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSelectedFilesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final sf = _selectedFiles[index];
        final isImage = _isImageFile(sf.xfile.name);

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage
                  ? Image.memory(
                      sf.bytes,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam,
                            size: 32,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              sf.xfile.name,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeFile(index),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedFile {
  const _SelectedFile({required this.xfile, required this.bytes});
  final XFile xfile;
  final Uint8List bytes;
}
