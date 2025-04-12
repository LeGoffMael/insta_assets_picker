import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:insta_assets_picker_demo/widgets/insta_picker_interface.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class WeChatCameraPicker extends StatelessWidget with InstaPickerInterface {
  const WeChatCameraPicker({super.key});

  @override
  PickerDescription get description => const PickerDescription(
        icon: '📸',
        label: 'WeChat Camera Picker',
        description: 'Picker with a camera button.\n'
            'The camera logic is handled by the `wechat_camera_picker` package.',
      );

  /// Needs a [BuildContext] that is coming from the picker
  Future<void> _pickFromWeChatCamera(BuildContext context) async {
    Feedback.forTap(context);
    final AssetEntity? entity = await CameraPicker.pickFromCamera(
      context,
      locale: Localizations.maybeLocaleOf(context),
      pickerConfig: CameraPickerConfig(
        theme: Theme.of(context),
        resolutionPreset: cameraResolutionPreset,
        // to allow video recording
        enableRecording: true,
      ),
    );
    if (entity == null) return;

    if (context.mounted) {
      await InstaAssetPicker.refreshAndSelectEntity(context, entity);
    }
  }

  @override
  Widget build(BuildContext context) => buildLayout(
        context,
        onPressed: () => InstaAssetPicker.pickAssets(
          context,
          pickerConfig: InstaAssetPickerConfig(
            title: description.fullLabel,
            pickerTheme: getPickerTheme(context),
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
                onTap: () => _pickFromWeChatCamera(context),
                theme: pickerTheme,
                icon: const Icon(Icons.camera_alt),
                size: height,
              ),
            ],
            specialItemBuilder: (context, _, __) {
              // return a button that open the camera
              return ElevatedButton(
                onPressed: () => _pickFromWeChatCamera(context),
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
