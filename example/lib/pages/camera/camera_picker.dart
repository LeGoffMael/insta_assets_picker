import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/helpers.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:path/path.dart' as path;

class CameraPicker extends StatefulWidget with InstaPickerInterface {
  const CameraPicker({super.key, required this.camera});

  final CameraDescription camera;

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
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<XFile?> onTakePicture(BuildContext context) async {
    return await Navigator.of(context, rootNavigator: true).push<XFile?>(
      MaterialPageRoute(
        builder: (context) => CameraView(
          controller: _controller,
          initializeControllerFuture: _initializeControllerFuture,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.buildLayout(
        context,
        onPressed: () => InstaAssetPicker.pickAssets(
          context,
          title: 'Select images or take picture',
          maxAssets: 4,
          pickerTheme: widget.getPickerTheme(context),
          specialItemBuilder: (context, _, __) {
            // return a button that open the camera
            return ElevatedButton(
              onPressed: () async {
                Feedback.forTap(context);
                final XFile? image = await onTakePicture(context);
                if (!context.mounted || image == null) return;

                final AssetEntity? entity =
                    await PhotoManager.editor.saveImageWithPath(
                  image.path,
                  title: path.basename(image.path),
                );

                if (entity == null) return;

                if (context.mounted) {
                  await InstaAssetPicker.refreshAndSelectEntity(
                    context,
                    entity,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
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

/// Widget based on Flutter docs : https://docs.flutter.dev/cookbook/plugins/picture-using-camera
class CameraView extends StatelessWidget {
  const CameraView({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController controller;
  final Future<void> initializeControllerFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Ensure that the camera is initialized.
            await initializeControllerFuture;
            // Attempt to take a picture and get the image's file where it was saved.
            final image = await controller.takePicture();

            if (!context.mounted) return;
            Navigator.pop(context, image);
          } catch (e) {
            debugPrint(e.toString());
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}