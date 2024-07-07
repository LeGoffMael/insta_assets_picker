import 'dart:math';

import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

class InstaAssetCropTransform extends StatelessWidget {
  const InstaAssetCropTransform({
    super.key,
    required this.asset,
    required this.cropParam,
    required this.targetAspectRatio,
    required this.child,
  });

  InstaAssetCropTransform.fromCropData(
    InstaAssetsCropData cropData, {
    super.key,
    required this.targetAspectRatio,
    required this.child,
  })  : asset = cropData.asset,
        cropParam = cropData.cropParam;

  final AssetEntity asset;
  final CropInternal? cropParam;
  final double targetAspectRatio;

  final Widget child;

  /// Returns a desired dimension of [layout] that respect [r] aspect ratio
  Size computeSizeWithRatio(Size layout, double r) {
    if (layout.aspectRatio == r) {
      return layout;
    }

    if (layout.aspectRatio > r) {
      return Size(layout.height * r, layout.height);
    }

    if (layout.aspectRatio < r) {
      return Size(layout.width, layout.width / r);
    }

    assert(false, 'An error occured while computing the aspectRatio');
    return Size.zero;
  }

  @override
  Widget build(BuildContext context) {
    final scale = cropParam?.scale ?? 1;
    final view = cropParam?.view ?? Rect.zero;
    final ratio = cropParam?.ratio ?? targetAspectRatio;

    final srcRatio = asset.size.aspectRatio;

    return LayoutBuilder(builder: (_, constraints) {
      final size = constraints.biggest;
      final layout = computeSizeWithRatio(size, srcRatio);
      final scaleLayout =
          max(size.width / layout.width, size.height / layout.height);

      final src = Rect.fromLTWH(0.0, 0.0, layout.width, layout.height);
      final dst = Rect.fromLTWH(
        view.left * layout.width * scale * ratio,
        view.top * layout.height * scale * ratio,
        layout.width * scale * ratio,
        layout.height * scale * ratio,
      );

      // Calculate the scale factors
      final double scaleX = dst.width / src.width;
      final double scaleY = dst.height / src.height;

      // Calculate the translation
      final double translateX = (dst.left - src.left);
      final double translateY = (dst.top - src.top);

      return ClipRRect(
        child: Transform.scale(
          scale: scaleLayout,
          // to start from top left
          origin: Offset(0, -layout.height / 2),
          child: Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.scale(
              scale: max(scaleX, scaleY),
              // to start from top left
              origin: Offset(-layout.width / 2, -layout.height / 2),
              child: Center(
                child: AspectRatio(aspectRatio: srcRatio, child: child),
              ),
            ),
          ),
        ),
      );
    });
  }
}
