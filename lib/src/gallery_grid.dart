import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    required this.assets,
    required this.selectedIds,
    required this.onTap,
    this.shrinkWrap = false,
    super.key,
  });

  final List<AssetEntity> assets;

  /// Liste ordonnée des IDs sélectionnés (ordre = ordre de sélection
  /// utilisateur). L'index dans cette liste donne le numéro affiché sur
  /// la vignette (1, 2, 3…).
  final List<String> selectedIds;
  final ValueChanged<AssetEntity> onTap;
  final bool shrinkWrap;

  static const int _crossAxisCount = 3;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final entity = assets[index];
        final position = selectedIds.indexOf(entity.id);
        return _GridCell(
          entity: entity,
          numeroSelection: position >= 0 ? position + 1 : null,
          onTap: () => onTap(entity),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.entity,
    required this.numeroSelection,
    required this.onTap,
  });

  final AssetEntity entity;

  /// Position 1-indexée dans la liste de sélection,
  /// ou `null` si non sélectionné.
  final int? numeroSelection;
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
      numeroSelection: numeroSelection,
      onTap: onTap,
      formatDuration: _formatDuration,
    );
  }
}

class _GridCellBody extends StatefulWidget {
  const _GridCellBody({
    required this.entity,
    required this.numeroSelection,
    required this.onTap,
    required this.formatDuration,
  });

  final AssetEntity entity;
  final int? numeroSelection;
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
    final isSelected = widget.numeroSelection != null;
    final theme = Theme.of(context);

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
          // Voile assombri sur les vignettes sélectionnées.
          AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: const ColoredBox(color: Colors.black38),
          ),
          // Badge numéro de sélection en haut à droite.
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isSelected
                  ? Container(
                      key: ValueKey<int>(widget.numeroSelection!),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.numeroSelection}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey<String>('unselected'),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
