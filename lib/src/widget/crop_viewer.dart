import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CropViewer extends StatefulWidget {
  const CropViewer({
    super.key,
    required this.provider,
    required this.textDelegate,
    required this.controller,
    required this.loaderWidget,
    required this.height,
    this.opacity = 1.0,
    this.theme,
  });

  final DefaultAssetPickerProvider provider;

  final AssetPickerTextDelegate textDelegate;

  final InstaAssetsCropController controller;

  final Widget loaderWidget;

  final double opacity;

  final double height;

  final ThemeData? theme;

  @override
  State<CropViewer> createState() => CropViewerState();
}

class CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<CropState>();
  AssetEntity? _previousAsset;
  final ValueNotifier<bool> _isLoadingError = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isVideoPlayer = ValueNotifier<bool>(false);

  @override
  void dispose() {
    // save current crop position on dispose (#25)
    saveCurrentCropChanges();
    _isLoadingError.dispose();
    _isVideoPlayer.dispose();
    super.dispose();
  }

  /// Save the crop parameters state in [InstaAssetsCropController]
  /// to retrieve it if the asset is opened again
  /// and apply them at the exportation
  void saveCurrentCropChanges() {
    widget.controller.onChange(
      _previousAsset,
      _cropKey.currentState,
      widget.provider.selectedAssets,
    );
  }

  /// Returns the [Crop] widget
  Widget _buildCropView(AssetEntity asset, CropInternal? cropParam) => Opacity(
        opacity: widget.controller.isCropViewReady.value ? widget.opacity : 1.0,
        child: Crop(
          key: _cropKey,
          image: AssetEntityImageProvider(
            asset,
            thumbnailSize: ThumbnailSize.square(widget.height.toInt()),
            isOriginal: asset.type == AssetType.image,
          ),
          placeholderWidget: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingError,
            builder: (context, isLoadingError, child) => Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: widget.opacity,
                  child: ExtendedImage(
                    // to match crop alignment
                    alignment: widget.controller.aspectRatio == 1.0
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    height: widget.height,
                    width: widget.height * widget.controller.aspectRatio,
                    image: AssetEntityImageProvider(asset, isOriginal: false),
                    enableMemoryCache: false,
                    fit: BoxFit.cover,
                  ),
                ),
                // show backdrop when image is loading or if an error occured
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
          // if the image could not be loaded (i.e unsupported format like RAW)
          // unselect it and clear cache, also show the error widget
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
          backgroundColor: widget.theme!.canvasColor,
          initialParam: cropParam,
        ),
      );

  Widget _buildVideoPlayer(AssetEntity asset, CropInternal? cropParam) =>
      InstaAssetsCropVideoPlayer(
        asset: asset,
        cropParam: _cropKey.currentState?.internalParameters ?? cropParam,
        textDelegate: widget.textDelegate,
        aspectRatio: widget.controller.aspectRatio,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: widget.height,
      width: width,
      child: ValueListenableBuilder<AssetEntity?>(
        valueListenable: widget.controller.previewAsset,
        builder: (_, previewAsset, __) => Selector<DefaultAssetPickerProvider,
                List<AssetEntity>>(
            selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets,
            builder: (_, List<AssetEntity> selected, __) {
              _isLoadingError.value = false;
              final int effectiveIndex =
                  selected.isEmpty ? 0 : selected.indexOf(selected.last);

              // if no asset is selected yet, returns the loader
              if (previewAsset == null && selected.isEmpty) {
                return widget.loaderWidget;
              }

              final asset = previewAsset ?? selected[effectiveIndex];
              final savedCropParam = widget.controller.get(asset)?.cropParam;

              // if the selected asset changed, save the previous crop parameters state
              if (asset != _previousAsset && _previousAsset != null) {
                _isLoadingError.value = false;
                _isVideoPlayer.value = false;
                saveCurrentCropChanges();
              }

              _previousAsset = asset;

              return ValueListenableBuilder<bool>(
                valueListenable: _isVideoPlayer,
                builder: (context, isVideoPlayer, _) {
                  // hide crop button if video player or if an asset is selected or if there is only one crop
                  final hideCropButton = isVideoPlayer ||
                      selected.length > 1 ||
                      widget.controller.cropDelegate.cropRatios.length <= 1;

                  return ValueListenableBuilder<int>(
                    valueListenable: widget.controller.cropRatioIndex,
                    builder: (context, _, __) => Stack(
                      children: [
                        isVideoPlayer
                            ? Positioned.fill(
                                child: _buildVideoPlayer(asset, savedCropParam),
                              )
                            : Positioned.fill(
                                child: _buildCropView(asset, savedCropParam),
                              ),

                        // Build crop aspect ratio button
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Visibility.maintain(
                                visible: !hideCropButton,
                                child: _buildCropButton(),
                              ),
                              if (asset.type == AssetType.video)
                                _buildPlayVideoButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
      ),
    );
  }

  Widget _buildCropButton() {
    return Opacity(
      opacity: 0.6,
      child: InstaPickerCircleIconButton(
        onTap: () {
          if (widget.controller.isCropViewReady.value) {
            widget.controller.nextCropRatio();
          }
        },
        theme: widget.theme?.copyWith(
          buttonTheme: const ButtonThemeData(padding: EdgeInsets.all(2)),
        ),
        size: 32,
        // if crop ratios are the default ones, build UI similar to instagram
        icon:
            widget.controller.cropDelegate.cropRatios == kDefaultInstaCropRatios
                ? Transform.rotate(
                    angle: 45 * math.pi / 180,
                    child: Icon(
                      widget.controller.aspectRatio == 1
                          ? Icons.unfold_more
                          : Icons.unfold_less,
                    ),
                  )
                // otherwise simply display the selected aspect ratio
                : Text(widget.controller.aspectRatioString),
      ),
    );
  }

  Widget _buildPlayVideoButton() {
    return Opacity(
      opacity: 0.6,
      child: InstaPickerCircleIconButton(
        onTap: () {
          final isVideoPlayer = _isVideoPlayer.value;
          if (!isVideoPlayer) saveCurrentCropChanges();
          _isVideoPlayer.value = !isVideoPlayer;
        },
        theme: widget.theme?.copyWith(
          buttonTheme: const ButtonThemeData(padding: EdgeInsets.all(2)),
        ),
        size: 32,
        icon: Icon(
          _isVideoPlayer.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
        ),
      ),
    );
  }
}
