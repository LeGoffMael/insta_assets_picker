import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/main.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';

class PickerDescription {
  final String icon;
  final String label;
  final String? description;

  const PickerDescription({
    required this.icon,
    required this.label,
    this.description,
  });

  String get fullLabel => '$icon $label';
}

mixin InstaPickerInterface on Widget {
  PickerDescription get description;

  ThemeData getPickerTheme(BuildContext context) {
    return InstaAssetPicker.themeData(kDefaultColor).copyWith(
      appBarTheme: const AppBarTheme(titleTextStyle: TextStyle(fontSize: 16)),
    );
  }

  AppBar get _appBar => AppBar(title: Text(description.fullLabel));

  /// NOTE: Exception on android when playing video recorded from the camera
  /// with [ResolutionPreset.max] after FFmpeg encoding
  ResolutionPreset get cameraResolutionPreset =>
      Platform.isAndroid ? ResolutionPreset.high : ResolutionPreset.max;

  Column pickerColumn({
    String? text,
    required VoidCallback onPressed,
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              text ??
                  'The ${description.label} will push result in a new screen',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: FittedBox(
              child: Text(
                'Open the ${description.label}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      );

  Scaffold buildLayout(
    BuildContext context, {
    required VoidCallback onPressed,
  }) =>
      Scaffold(
        appBar: _appBar,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: pickerColumn(onPressed: onPressed),
        ),
      );

  Scaffold buildCustomLayout(
    BuildContext context, {
    required Widget child,
  }) =>
      Scaffold(
        appBar: _appBar,
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  void pickAssets(BuildContext context, {required int maxAssets}) =>
      InstaAssetPicker.pickAssets(
        context,
        pickerConfig: InstaAssetPickerConfig(
          title: description.fullLabel,
          closeOnComplete: true,
          pickerTheme: getPickerTheme(context),
          // skipCropOnComplete: true, // to test ffmpeg crop image
          // previewThumbnailSize: const ThumbnailSize(240, 240), // to improve thumbnails speed in crop view
        ),
        maxAssets: maxAssets,
        onCompleted: (Stream<InstaAssetsExportDetails> cropStream) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PickerCropResultScreen(cropStream: cropStream),
            ),
          );
        },
      );
}
