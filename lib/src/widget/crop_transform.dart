import 'dart:math';

import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart' as insta_crop_view;
import 'package:insta_assets_picker/insta_assets_picker.dart';

class InstaAssetCropTransform extends StatelessWidget {
  const InstaAssetCropTransform({
    super.key,
    required this.asset,
    required this.cropParam,
    required this.child,
  });

  final AssetEntity asset;
  final insta_crop_view.CropInternal? cropParam;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (cropParam == null) return child;

    final scale = cropParam!.scale;
    final view = cropParam!.view;
    final area = cropParam!.area;
    final aspectRatio = area.size.aspectRatio;

    return LayoutBuilder(builder: (_, constraints) {
      final maxSize = constraints.biggest;
      final size = maxSize.aspectRatio == aspectRatio
          ? maxSize
          : Size(maxSize.height * aspectRatio, maxSize.height);

      final ratio = max(
        size.width / asset.size.width,
        size.height / asset.size.height,
      );

      print(ratio);

      return SizedBox.fromSize(
        size: size,
        child: insta_crop_view.CropTransform(
          ratio: ratio,
          scale: scale,
          view: view,
          childSize: asset.size,
          getRect: (s) => Offset.zero & s,
          child: child,
        ),
      );
    });
  }
}
