import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/utils.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:insta_assets_picker_demo/widgets/insta_picker_interface.dart';

class CameraPicker extends StatefulWidget with InstaPickerInterface {
  const CameraPicker({super.key});

  @override
  State<CameraPicker> createState() => _CameraPickerState();

  @override
  PickerDescription get description => const PickerDescription(
        icon: '📷',
        label: 'Camera Picker',
        description: 'Picker with a camera button.\n'
            'The camera logic is handled by the `camera` package.',
      );
}

class _CameraPickerState extends State<CameraPicker> {
  late List<CameraDescription> cameras;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    final int preferredIndex = cameras.indexWhere(
      (CameraDescription e) => e.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      cameras[max(preferredIndex, 0)],
      widget.cameraResolutionPreset,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  /// Needs a [BuildContext] that is coming from the picker
  Future<void> _pickFromCamera(BuildContext context) async {
    Feedback.forTap(context);
    final XFile? cameraFile =
        await Navigator.of(context, rootNavigator: true).push<XFile?>(
      MaterialPageRoute(
        builder: (context) => CameraView(
          controller: _controller,
          initializeControllerFuture: _initializeControllerFuture,
        ),
      ),
    );

    if (!context.mounted || cameraFile == null) return;

    AssetEntity? entity;
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        final File file = File(cameraFile.path);
        final bool isVideo = isVideoFile(file);
        final String title = getFileNameWithExtension(file);

        if (isVideo) {
          entity = await PhotoManager.editor.saveVideo(file, title: title);
        } else {
          entity = await PhotoManager.editor
              .saveImageWithPath(file.path, title: title);
        }
      } else {
        debugPrint(
            'Permission is not fully granted to save the captured file.');
      }
    } catch (e) {
      debugPrint('Exception $e');
    } finally {
      if (context.mounted) {
        await InstaAssetPicker.refreshAndSelectEntity(context, entity);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.buildLayout(
        context,
        onPressed: () => InstaAssetPicker.pickAssets(
          context,
          pickerConfig: InstaAssetPickerConfig(
            title: widget.description.fullLabel,
            pickerTheme: widget.getPickerTheme(context),
            actionsBuilder: (
              BuildContext context,
              ThemeData pickerTheme,
              double height,
              VoidCallback unselectAll,
            ) =>
                [
              InstaPickerCircleIconButton.unselectAll(
                onTap: unselectAll,
                theme: pickerTheme,
                size: height,
              ),
              const SizedBox(width: 8),
              InstaPickerCircleIconButton(
                onTap: () => _pickFromCamera(context),
                theme: pickerTheme,
                icon: const Icon(Icons.camera_alt),
                size: height,
              ),
            ],
            specialItemBuilder: (BuildContext context, _, __) {
              // return a button that open the camera
              return ElevatedButton(
                onPressed: () => _pickFromCamera(context),
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                ),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Text(
                    InstaAssetPicker.defaultTextDelegate(context)
                        .sActionUseCameraHint,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            // since the list is revert, use prepend to be at the top
            specialItemPosition: SpecialItemPosition.prepend,
          ),
          maxAssets: 4,
          onCompleted: (cropStream) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PickerCropResultScreen(cropStream: cropStream),
              ),
            );
          },
        ),
      );
}

/// Widget based on camera package example : https://github.com/flutter/packages/blob/main/packages/camera/camera/example/lib/main.dart
class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController controller;
  final Future<void> initializeControllerFuture;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        if (file != null) {
          debugPrint('Picture saved to ${file.path}');
        }
        Navigator.pop(context, file);
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((XFile? file) {
      if (mounted) {
        setState(() {});
        if (file != null) {
          debugPrint('Video recorded to ${file.path}');
        }
        Navigator.pop(context, file);
      }
    });
  }

  Future<void> startVideoRecording() async {
    // Ensure that the camera is initialized.
    await widget.initializeControllerFuture;

    if (!widget.controller.value.isInitialized) {
      debugPrint('Error: select a camera first.');
      return;
    }

    if (widget.controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await widget.controller.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!widget.controller.value.isRecordingVideo) {
      return null;
    }

    try {
      return widget.controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<XFile?> takePicture() async {
    // Ensure that the camera is initialized.
    await widget.initializeControllerFuture;

    if (!widget.controller.value.isInitialized) {
      debugPrint('Error: select a camera first.');
      return null;
    }

    if (widget.controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await widget.controller.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    final errorMsg = 'Error: ${e.code}\n${e.description}';
    debugPrint(errorMsg);
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: widget.controller.value.isInitialized &&
                  !widget.controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          color: widget.controller.value.isRecordingVideo ? Colors.red : null,
          onPressed: widget.controller.value.isInitialized &&
                  !widget.controller.value.isRecordingVideo
              ? onVideoRecordButtonPressed
              : onStopButtonPressed,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera example')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: widget.controller.value.isRecordingVideo
                        ? Colors.redAccent
                        : Colors.grey,
                    width: 3.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: FutureBuilder<void>(
                    future: widget.initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio:
                                1 / widget.controller.value.aspectRatio,
                            child: CameraPreview(widget.controller),
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ),
            ),
            _captureControlRowWidget(),
          ],
        ),
      ),
    );
  }
}
