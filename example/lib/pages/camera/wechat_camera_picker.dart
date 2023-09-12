import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/helpers.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class WeChatCameraPicker extends StatelessWidget with InstaPickerInterface {
  const WeChatCameraPicker({super.key});

  Future<AssetEntity?> _pickFromCamera(BuildContext context) =>
      CameraPicker.pickFromCamera(
        context,
        locale: Localizations.maybeLocaleOf(context),
        pickerConfig: CameraPickerConfig(theme: Theme.of(context)),
      );

  @override
  PickerDescription get description => const PickerDescription(
        icon: '📸',
        label: 'WeChat Camera Picker',
        description: 'Picker with a camera button.\n'
            'The camera logic is handled by the `wechat_camera_picker` package.',
      );

  @override
  Widget build(BuildContext context) => buildLayout(
        context,
        onPressed: () => InstaAssetPicker.pickAssets(
          context,
          title: 'Select images or take picture',
          maxAssets: 4,
          pickerTheme: getPickerTheme(context),
          specialItemBuilder: (context, _, __) {
            // return a button that open the camera
            return ElevatedButton(
              onPressed: () async {
                Feedback.forTap(context);
                final AssetEntity? entity = await _pickFromCamera(context);
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
