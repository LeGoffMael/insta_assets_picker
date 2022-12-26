// ignore_for_file: depend_on_referenced_packages

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:insta_assets_picker/src/widget/circle_icon_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CropViewer extends StatefulWidget {
  const CropViewer({
    super.key,
    required this.provider,
    required this.textDelegate,
    required this.controller,
    required this.loaderWidget,
    this.opacity = 1.0,
    this.theme,
  });

  final DefaultAssetPickerProvider provider;

  final AssetPickerTextDelegate textDelegate;

  final InstaAssetsCropController controller;

  final Widget loaderWidget;

  final double opacity;

  final ThemeData? theme;

  @override
  State<CropViewer> createState() => CropViewerState();
}

class CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<CropState>();
  AssetEntity? _previousAsset;
  final ValueNotifier<bool> _isLoadingError = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isLoadingError.dispose();
    super.dispose();
  }

  void saveCurrentCropChanges() {
    widget.controller.onChange(
      _previousAsset,
      _cropKey.currentState,
      widget.provider.selectedAssets,
    );
  }

  Widget _buildCropView(AssetEntity asset, CropInternal? cropParam) => Opacity(
        opacity: widget.controller.isCropViewReady.value ? widget.opacity : 1.0,
        child: Crop(
          key: _cropKey,
          image: AssetEntityImageProvider(asset, isOriginal: true),
          placeholderWidget: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingError,
            builder: (context, isLoadingError, child) => Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: widget.opacity,
                  child: ExtendedImage(
                    // to match crop alignment
                    alignment: widget.controller.isSquare.value
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width *
                        widget.controller.aspectRatio,
                    image: AssetEntityImageProvider(asset, isOriginal: false),
                    enableMemoryCache: false,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                    child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: widget.theme?.cardColor.withOpacity(0.4)),
                )),
                isLoadingError
                    ? Text(widget.textDelegate.loadFailed)
                    : widget.loaderWidget,
              ],
            ),
          ),
          onImageError: (exception, stackTrace) {
            widget.provider.unSelectAsset(asset);
            AssetEntityImageProvider(asset).evict();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _isLoadingError.value = true;
              widget.controller.isCropViewReady.value = true;
            });
          },
          onLoading: (isReady) => WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.controller.isCropViewReady.value = isReady),
          maximumScale: 10,
          aspectRatio: widget.controller.aspectRatio,
          disableResize: true,
          backgroundColor: widget.theme!.cardColor,
          initialParam: cropParam,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AssetEntity?>(
      valueListenable: widget.controller.previewAsset,
      builder: (_, previewAsset, __) =>
          Selector<DefaultAssetPickerProvider, List<AssetEntity>>(
              selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets,
              builder: (_, List<AssetEntity> selected, __) {
                _isLoadingError.value = false;
                final int effectiveIndex =
                    selected.isEmpty ? 0 : selected.indexOf(selected.last);

                if (previewAsset == null && selected.isEmpty) {
                  return SizedBox.square(
                    dimension: MediaQuery.of(context).size.width,
                    child: widget.loaderWidget,
                  );
                }

                final asset = previewAsset ?? selected[effectiveIndex];
                final savedCropParam = widget.controller.get(asset)?.cropParam;

                if (asset != _previousAsset && _previousAsset != null) {
                  saveCurrentCropChanges();
                }

                _previousAsset = asset;

                return SizedBox.square(
                  dimension: MediaQuery.of(context).size.width,
                  child: selected.length > 1
                      ? _buildCropView(asset, savedCropParam)
                      : ValueListenableBuilder<bool>(
                          valueListenable: widget.controller.isSquare,
                          builder: (context, isSquare, child) => Stack(
                            children: [
                              Positioned.fill(
                                child: _buildCropView(asset, savedCropParam),
                              ),
                              Positioned(
                                left: 0,
                                bottom: 12,
                                child: CircleIconButton(
                                  onTap: () {
                                    if (widget
                                        .controller.isCropViewReady.value) {
                                      widget.controller.isSquare.value =
                                          !isSquare;
                                    }
                                  },
                                  theme: widget.theme,
                                  icon: Transform.rotate(
                                    angle: 45 * math.pi / 180,
                                    child: Icon(
                                      isSquare
                                          ? Icons.unfold_more
                                          : Icons.unfold_less,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                );
              }),
    );
  }
}
