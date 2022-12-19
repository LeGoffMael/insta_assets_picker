import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

class InstaAssets {
  final AssetEntity asset;
  final CropInternal? cropParam;

  const InstaAssets({required this.asset, required this.cropParam});

  static InstaAssets fromState({
    required AssetEntity asset,
    required CropState? cropState,
  }) {
    return InstaAssets(
      asset: asset,
      cropParam: cropState?.internalParameters,
    );
  }

  InstaAssets copyWith({AssetEntity? asset, CropState? cropState}) {
    return InstaAssets(
      asset: asset ?? this.asset,
      cropParam: cropState?.internalParameters ?? cropParam,
    );
  }
}

class InstaAssetsCropController {
  List<InstaAssets> list = [];
  final ValueNotifier<bool> isSquare = ValueNotifier<bool>(true);

  dispose() {
    isSquare.dispose();
  }

  double get aspectRatio => isSquare.value ? 1 : 4 / 5;

  void onChange(
    AssetEntity? saveAsset,
    CropState? saveCropState,
    List<AssetEntity> selectedAssets,
  ) {
    final List<InstaAssets> newList = [];

    for (final asset in selectedAssets) {
      final savedCropAsset = get(asset);

      if (asset == saveAsset && saveAsset != null) {
        newList.add(InstaAssets.fromState(
          asset: saveAsset,
          cropState: saveCropState,
        ));
      } else if (savedCropAsset == null) {
        newList.add(InstaAssets.fromState(asset: asset, cropState: null));
      } else {
        newList.add(savedCropAsset);
      }

      print(
          'onChange inside $asset, area=${savedCropAsset?.cropParam?.area} view=${savedCropAsset?.cropParam?.view} scale=${savedCropAsset?.cropParam?.scale} ratio=${savedCropAsset?.cropParam?.ratio}');
    }

    list = newList;
  }

  InstaAssets? get(AssetEntity asset) {
    if (list.isEmpty) return null;
    final index = list.indexWhere((e) => e.asset == asset);
    if (index == -1) return null;
    return list[index];
  }

  // TODO
  List<AssetEntity>? cropAll() {
    return null;
  }
}
