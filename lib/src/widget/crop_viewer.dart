// ignore_for_file: depend_on_referenced_packages

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
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
  final ValueNotifier<bool> _isSquare = ValueNotifier<bool>(true);

  double get aspectRatio => _isSquare.value ? 1 : 4 / 5;

  @override
  void dispose() {
    _isSquare.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(builder:
        (BuildContext context, DefaultAssetPickerProvider provider, __) {
      final List<AssetEntity> selected = provider.selectedAssets;
      final int effectiveIndex =
          selected.isEmpty ? 0 : selected.indexOf(selected.last);

      print('preview = ${provider.previewAsset}');

      if (provider.previewAsset == null && selected.isEmpty) {
        // TODO : crop view
        return SizedBox.square(dimension: MediaQuery.of(context).size.width);
      }

      final asset = provider.previewAsset ?? selected[effectiveIndex];
      return SizedBox.square(
        dimension: MediaQuery.of(context).size.width,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isSquare,
          builder: (context, isSquare, child) => Stack(
            children: [
              Positioned.fill(
                child: Crop(
                  key: _cropKey,
                  image: AssetEntityImageProvider(asset, isOriginal: true),
                  placeholderWidget: Stack(
                    alignment: Alignment.center,
                    children: [
                      ExtendedImage(
                        // to match crop alignment
                        alignment: isSquare
                            ? Alignment.center
                            : Alignment.bottomCenter,
                        height: MediaQuery.of(context).size.width - 1,
                        width: (MediaQuery.of(context).size.width - 1) *
                            aspectRatio,
                        image:
                            AssetEntityImageProvider(asset, isOriginal: false),
                        enableMemoryCache: false,
                        fit: BoxFit.cover,
                      ),
                      _buildIndicator(),
                    ],
                  ),
                  maximumScale: 10,
                  aspectRatio: aspectRatio,
                  disableResize: true,
                  backgroundColor: widget.theme!.cardColor,
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () => _isSquare.value = !isSquare,
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
                          isSquare ? Icons.unfold_more : Icons.unfold_less),
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
