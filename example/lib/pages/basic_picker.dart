import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:insta_assets_picker_demo/widgets/insta_picker_interface.dart';

class BasicPicker extends StatelessWidget with InstaPickerInterface {
  const BasicPicker({super.key});

  @override
  PickerDescription get description =>
      const PickerDescription(icon: '🖼️', label: 'Basic Picker');

  @override
  Widget build(BuildContext context) => buildLayout(
        context,
        onPressed: () => InstaAssetPicker.pickAssets(
          context,
          title: description.fullLabel,
          maxAssets: 10,
          pickerTheme: getPickerTheme(context),
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
