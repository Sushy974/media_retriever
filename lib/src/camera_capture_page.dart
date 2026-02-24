import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:media_retriever/src/media_kind.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({
    super.key,
    this.kind = MediaKind.any,
  });

  final MediaKind kind;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  bool _photoMode = true;
  bool _initializing = true;
  bool _capturing = false;
  bool _recording = false;
  bool _switchingCamera = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photoMode = widget.kind != MediaKind.video;
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw StateError('Aucune caméra disponible sur cet appareil.');
      }
      if (_cameraIndex >= _cameras.length) _cameraIndex = 0;

      final oldController = _controller;
      if (mounted) {
        // IMPORTANT (iOS):
        // On retire le preview avant de disposer l'ancien controller pour
        // éviter un freeze de rendu lors du switch de caméra.
        setState(() => _controller = null);
      }
      await oldController?.dispose();

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: !_photoMode,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });

      debugPrint(
        '[media_retriever][camera] initialized index=$_cameraIndex '
        'lens=${controller.description.lensDirection.name}',
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initializing = false;
        });
      }
      debugPrint('[media_retriever][camera] init error: $e');
    }
  }

  Future<bool> _ensureMicrophonePermissionIfNeeded() async {
    if (_photoMode) return true;
    if (Platform.isIOS) {
      // Laisser iOS gérer le prompt via l'initialisation audio / enregistrement.
      return true;
    }

    final statusBefore = await Permission.microphone.status;
    // #region agent log
    debugPrint(
      '[media_retriever][permissions] microphone(status before) '
      '${statusBefore.name}',
    );
    // #endregion
    final mic = await Permission.microphone.request();
    // #region agent log
    debugPrint(
      '[media_retriever][permissions] microphone(request result) ${mic.name}',
    );
    // #endregion

    if (mic.isGranted) return true;
    if (mic.isPermanentlyDenied && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Autoriser le micro'),
            content: const Text(
              'Pour enregistrer une vidéo avec le son, active Microphone '
              'pour Zibmarket dans les réglages.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                },
                child: const Text('Ouvrir les réglages'),
              ),
            ],
          );
        },
      );
    }
    return false;
  }

  int? _preferredCameraIndex(CameraLensDirection direction) {
    final candidates = <int>[];
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == direction) {
        candidates.add(i);
      }
    }
    if (candidates.isEmpty) return null;

    if (direction == CameraLensDirection.back) {
      // iOS peut exposer plusieurs caméras "back" (wide/ultra-wide/tele).
      // On choisit la "wide" par défaut et on ignore ultra-wide/tele.
      for (final i in candidates) {
        final name = _cameras[i].name.toLowerCase();
        final isWide = name.contains('wide');
        final isUltra = name.contains('ultra');
        final isTele = name.contains('tele');
        if (isWide && !isUltra && !isTele) return i;
      }
    }

    return candidates.first;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    if (_recording || _initializing || _switchingCamera) return;
    _switchingCamera = true;
    debugPrint('[media_retriever][camera] switch requested');

    final current = _cameras[_cameraIndex].lensDirection;
    final target = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final nextIndex = _preferredCameraIndex(target);
    if (nextIndex == null) {
      _switchingCamera = false;
      return;
    }
    _cameraIndex = nextIndex;

    await _initCamera();
    _switchingCamera = false;
  }

  Future<void> _onCapturePressed() async {
    final controller = _controller;
    if (controller == null) return;
    if (_initializing || _capturing) return;

    setState(() {
      _capturing = true;
      _error = null;
    });

    try {
      if (_photoMode) {
        if (controller.value.isTakingPicture) return;
        final xfile = await controller.takePicture();
        debugPrint(
          '[media_retriever][camera] photo captured path=${xfile.path}',
        );
        await Gal.putImage(xfile.path);
        if (!mounted) return;
        Navigator.of(context).pop(<File>[File(xfile.path)]);
        return;
      }

      final micOk = await _ensureMicrophonePermissionIfNeeded();
      if (!micOk) return;

      if (!_recording) {
        await controller.startVideoRecording();
        debugPrint('[media_retriever][camera] video recording started');
        if (mounted) {
          setState(() {
            _recording = true;
            _capturing = false;
          });
        }
        return;
      }

      final xfile = await controller.stopVideoRecording();
      debugPrint(
        '[media_retriever][camera] video captured path=${xfile.path}',
      );
      await Gal.putVideo(xfile.path);
      if (!mounted) return;
      Navigator.of(context).pop(<File>[File(xfile.path)]);
    } on Object catch (e) {
      debugPrint('[media_retriever][camera] capture error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _capturing = false;
          _recording = false;
        });
      }
    } finally {
      if (mounted && !_recording) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _initializing || controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // IMPORTANT:
                        // On évite tout "stretch".
                        // L'utilisateur veut un rendu réaliste, sans crop, qui
                        // s'adapte à la largeur du téléphone.
                        final orientation = MediaQuery.of(context).orientation;
                        // `controller.value.aspectRatio` est souvent exprimé
                        // en orientation "landscape" (w/h). En portrait, il
                        // faut inverser pour éviter un rendu écrasé.
                        final previewRatio = orientation == Orientation.portrait
                            ? 1 / controller.value.aspectRatio
                            : controller.value.aspectRatio;
                        return Center(
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: AspectRatio(
                              aspectRatio: previewRatio,
                              child: CameraPreview(
                                controller,
                                key: ValueKey(controller.description.name),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                onPressed: _switchCamera,
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
            ),
            if (widget.kind == MediaKind.any)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Photo'),
                        icon: Icon(Icons.photo_camera),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Vidéo'),
                        icon: Icon(Icons.videocam),
                      ),
                    ],
                    selected: {_photoMode},
                    onSelectionChanged: (selected) {
                      if (_recording) return;
                      setState(() {
                        _photoMode = selected.first;
                      });
                    },
                  ),
                ),
              ),
            if (_recording)
              const Positioned(
                left: 16,
                bottom: 120,
                child: Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'REC',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  IconButton(
                    onPressed: (_initializing || _capturing)
                        ? null
                        : _onCapturePressed,
                    iconSize: 72,
                    icon: Icon(
                      _photoMode
                          ? Icons.radio_button_checked
                          : (_recording
                              ? Icons.stop_circle
                              : Icons.fiber_manual_record),
                      color: _photoMode
                          ? Colors.white
                          : (_recording ? Colors.white : Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
