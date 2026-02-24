import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    required this.assets,
    required this.selectedIds,
    required this.onTap,
    super.key,
  });

  final List<AssetEntity> assets;
  final Set<String> selectedIds;
  final ValueChanged<AssetEntity> onTap;

  static const int _crossAxisCount = 3;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final entity = assets[index];
        return _GridCell(
          entity: entity,
          isSelected: selectedIds.contains(entity.id),
          onTap: () => onTap(entity),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.entity,
    required this.isSelected,
    required this.onTap,
  });

  final AssetEntity entity;
  final bool isSelected;
  final VoidCallback onTap;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return _GridCellBody(
      entity: entity,
      isSelected: isSelected,
      onTap: onTap,
      formatDuration: _formatDuration,
    );
  }
}

class _GridCellBody extends StatefulWidget {
  const _GridCellBody({
    required this.entity,
    required this.isSelected,
    required this.onTap,
    required this.formatDuration,
  });

  final AssetEntity entity;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(Duration d) formatDuration;

  @override
  State<_GridCellBody> createState() => _GridCellBodyState();
}

class _GridCellBodyState extends State<_GridCellBody> {
  late Future<Uint8List?> _thumbFuture;

  @override
  void initState() {
    super.initState();
    _thumbFuture = _createThumbFuture(widget.entity);
  }

  @override
  void didUpdateWidget(covariant _GridCellBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.id != widget.entity.id) {
      _thumbFuture = _createThumbFuture(widget.entity);
    }
  }

  Future<Uint8List?> _createThumbFuture(AssetEntity entity) {
    return entity.thumbnailDataWithOption(
      const ThumbnailOption(size: ThumbnailSize.square(256)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.entity.type == AssetType.video;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: FutureBuilder<Uint8List?>(
              future: _thumbFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                }
                return const ColoredBox(
                  color: Colors.grey,
                  child: Center(child: Icon(Icons.photo)),
                );
              },
            ),
          ),
          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
            ),
          if (isVideo)
            Positioned(
              right: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    widget.formatDuration(widget.entity.videoDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          AnimatedOpacity(
            opacity: widget.isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
