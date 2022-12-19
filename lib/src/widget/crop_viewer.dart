// ignore_for_file: depend_on_referenced_packages

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CropViewer extends StatefulWidget {
  const CropViewer({super.key, required this.provider, this.theme});

  final DefaultAssetPickerProvider provider;

  final ThemeData? theme;

  @override
  State<CropViewer> createState() => _CropViewerState();
}

class _CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<CropState>();
  final _cropController = InstaAssetsCropController();
  AssetEntity? _previousAsset;

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  Widget _buildIndicator() {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const CupertinoActivityIndicator(animating: true, radius: 16.0)
        : CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          );
  }

  Widget _buildCropView(AssetEntity asset, CropInternal? cropParam) => Crop(
        key: _cropKey,
        image: AssetEntityImageProvider(asset, isOriginal: true),
        placeholderWidget: Stack(
          alignment: Alignment.center,
          children: [
            ExtendedImage(
              // to match crop alignment
              alignment: _cropController.isSquare.value
                  ? Alignment.center
                  : Alignment.bottomCenter,
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width *
                  _cropController.aspectRatio,
              image: AssetEntityImageProvider(asset, isOriginal: false),
              enableMemoryCache: false,
              fit: BoxFit.cover,
            ),
            _buildIndicator(),
          ],
        ),
        maximumScale: 10,
        aspectRatio: _cropController.aspectRatio,
        disableResize: true,
        backgroundColor: widget.theme!.cardColor,
        initialParam: cropParam,
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(builder:
        (BuildContext context, DefaultAssetPickerProvider provider, __) {
      final List<AssetEntity> selected = provider.selectedAssets;
      final int effectiveIndex =
          selected.isEmpty ? 0 : selected.indexOf(selected.last);

      if (provider.previewAsset == null && selected.isEmpty) {
        return SizedBox.square(
          dimension: MediaQuery.of(context).size.width,
          child: _buildIndicator(),
        );
      }

      final asset = provider.previewAsset ?? selected[effectiveIndex];
      CropInternal? savedCropParam;

      if (asset != _previousAsset) {
        if (_previousAsset != null) {
          _cropController.onChange(
            _previousAsset,
            _cropKey.currentState,
            selected,
          );
        }
        savedCropParam = _cropController.get(asset)?.cropParam;
      }

      _previousAsset = asset;

      return SizedBox.square(
        dimension: MediaQuery.of(context).size.width,
        child: selected.length > 1
            ? _buildCropView(asset, savedCropParam)
            : ValueListenableBuilder<bool>(
                valueListenable: _cropController.isSquare,
                builder: (context, isSquare, child) => Stack(
                  children: [
                    Positioned.fill(
                      child: _buildCropView(asset, savedCropParam),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () => _cropController.isSquare.value = !isSquare,
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: widget.theme!.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Transform.rotate(
                            angle: 45 * math.pi / 180,
                            child: Icon(
                              isSquare ? Icons.unfold_more : Icons.unfold_less,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}
