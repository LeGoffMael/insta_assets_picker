import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

/// Uses [InstaAssetsCropSingleton] to keep crop parameters in memory until the picker is disposed
/// Similar to [Singleton] class from `wechat_assets_picker` package
class InstaAssetsCropSingleton {
  const InstaAssetsCropSingleton._();

  static List<InstaAssetsCrop> cropParameters = [];
}

class InstaAssetsExportDetails {
  final List<File> croppedFiles;
  final List<AssetEntity> selectedAssets;
  final double aspectRatio;

  /// The [progress] param represents progress indicator between `0.0` and `1.0`.
  final double progress;

  const InstaAssetsExportDetails({
    required this.croppedFiles,
    required this.selectedAssets,
    required this.aspectRatio,
    required this.progress,
  });
}

class InstaAssetsCrop {
  final AssetEntity asset;
  final CropInternal? cropParam;

  // export crop params
  final double scale;
  final Rect? area;

  const InstaAssetsCrop({
    required this.asset,
    required this.cropParam,
    this.scale = 1.0,
    this.area,
  });

  static InstaAssetsCrop fromState({
    required AssetEntity asset,
    required CropState? cropState,
  }) {
    return InstaAssetsCrop(
      asset: asset,
      cropParam: cropState?.internalParameters,
      scale: cropState?.scale ?? 1.0,
      area: cropState?.area,
    );
  }

  InstaAssetsCrop copyWith({AssetEntity? asset, CropState? cropState}) {
    return InstaAssetsCrop(
      asset: asset ?? this.asset,
      cropParam: cropState?.internalParameters ?? cropParam,
      scale: cropState?.scale ?? scale,
      area: cropState?.area ?? area,
    );
  }
}

class InstaAssetsCropController {
  final ValueNotifier<bool> isCropViewReady = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSquare = ValueNotifier<bool>(true);
  final ValueNotifier<AssetEntity?> previewAsset =
      ValueNotifier<AssetEntity?>(null);

  dispose() {
    clear();
    isCropViewReady.dispose();
    isSquare.dispose();
    previewAsset.dispose();
  }

  double get aspectRatio => isSquare.value ? 1 : 4 / 5;

  void clear() {
    InstaAssetsCropSingleton.cropParameters = [];
    previewAsset.value = null;
  }

  void onChange(
    AssetEntity? saveAsset,
    CropState? saveCropState,
    List<AssetEntity> selectedAssets,
  ) {
    final List<InstaAssetsCrop> newList = [];

    for (final asset in selectedAssets) {
      final savedCropAsset = get(asset);

      if (asset == saveAsset && saveAsset != null) {
        newList.add(InstaAssetsCrop.fromState(
          asset: saveAsset,
          cropState: saveCropState,
        ));
      } else if (savedCropAsset == null) {
        newList.add(InstaAssetsCrop.fromState(asset: asset, cropState: null));
      } else {
        newList.add(savedCropAsset);
      }
    }

    InstaAssetsCropSingleton.cropParameters = newList;
  }

  InstaAssetsCrop? get(AssetEntity asset) {
    if (InstaAssetsCropSingleton.cropParameters.isEmpty) return null;
    final index = InstaAssetsCropSingleton.cropParameters
        .indexWhere((e) => e.asset == asset);
    if (index == -1) return null;
    return InstaAssetsCropSingleton.cropParameters[index];
  }

  Stream<InstaAssetsExportDetails> exportCropFiles(
    List<AssetEntity> selectedAssets,
  ) async* {
    List<File> croppedFiles = [];
    InstaAssetsExportDetails makeDetail(double p) => InstaAssetsExportDetails(
          croppedFiles: croppedFiles,
          selectedAssets: selectedAssets,
          aspectRatio: aspectRatio,
          progress: p,
        );
    yield makeDetail(0);
    final list = InstaAssetsCropSingleton.cropParameters;

    final step = 1 / list.length;

    for (var i = 0; i < list.length; i++) {
      final file = await list[i].asset.file;

      final scale = list[i].scale;
      final area = list[i].area;

      if (file == null) {
        throw 'error file is null';
      }

      if (area == null) {
        croppedFiles.add(file);
        break;
      }

      final sampledFile = await ImageCrop.sampleImage(
        file: file,
        preferredSize: (1024 / scale).round(),
      );

      final croppedFile =
          await ImageCrop.cropImage(file: sampledFile, area: area);

      croppedFiles.add(croppedFile);
      yield makeDetail((i + 1) * step);
    }

    yield makeDetail(1);
  }
}
