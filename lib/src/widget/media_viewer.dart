import 'dart:io';
import 'dart:math' as math;

import 'package:chewie/chewie.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MediaViewer extends StatefulWidget {
  const MediaViewer({
    super.key,
    required this.provider,
    required this.textDelegate,
    required this.cropController,
    required this.videoController,
    required this.loaderWidget,
    required this.height,
    this.opacity = 1.0,
    this.theme,
    // this.chewieController,
    // this.videoPlayerController,
  });

  final DefaultAssetPickerProvider provider;

  final AssetPickerTextDelegate textDelegate;

  final InstaAssetsCropController cropController;

  final InstaAssetsVideoController videoController;

  final Widget loaderWidget;

  final double opacity;

  final double height;

  final ThemeData? theme;

  @override
  State<MediaViewer> createState() => MediaViewerState();
}

class MediaViewerState extends State<MediaViewer> {
  final _cropKey = GlobalKey<CropState>();
  AssetEntity? _previousAsset;
  final ValueNotifier<bool> _isLoadingError = ValueNotifier<bool>(false);



  @override
  void dispose() {
    widget.videoController.dispose();
    // save current crop position on dispose (#25)
    saveCurrentCropChanges();
    _isLoadingError.dispose();
    super.dispose();
  }

  /// Save the crop parameters state in [InstaAssetsCropController]
  /// to retrieve it if the asset is opened again
  /// and apply them at the exportation
  void saveCurrentCropChanges() {
    widget.cropController.onChange(
      _previousAsset,
      _cropKey.currentState,
      widget.provider.selectedAssets,
    );
  }

  /// Returns the [Crop] or [VideoPlayer] widget
  Widget _buildCropView(AssetEntity asset, CropInternal? cropParam) {
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.cropController.isCropViewReady.value = true);
    return Opacity(
      opacity: widget.cropController.isCropViewReady.value ? widget.opacity : 1.0,
      child: asset.type == AssetType.image ? Crop(
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
                  alignment: widget.cropController.aspectRatio == 1.0 ? Alignment.center : Alignment.bottomCenter,
                  height: widget.height,
                  width: widget.height * widget.cropController.aspectRatio,
                  image: AssetEntityImageProvider(asset, isOriginal: false),
                  enableMemoryCache: false,
                  fit: BoxFit.cover,
                ),
              ),
              // show backdrop when image is loading or if an error occured
              Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: widget.theme?.cardColor.withOpacity(0.4)),
                  )),
              isLoadingError ? Text(widget.textDelegate.loadFailed) : widget.loaderWidget,
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
            widget.cropController.isCropViewReady.value = true;
          });
        },
        onLoading: (isReady) => WidgetsBinding.instance
            .addPostFrameCallback((_) => widget.cropController.isCropViewReady.value = isReady),
        maximumScale: 10,
        aspectRatio: widget.cropController.aspectRatio,
        disableResize: true,
        backgroundColor: widget.theme!.canvasColor,
        initialParam: cropParam,
      ) : FutureBuilder(
        future: getVideoFile(asset),
        builder: (_, data) {
          if (data.connectionState == ConnectionState.done) {
            if(asset.type == AssetType.video) {
              return Chewie(controller: widget.videoController.chewieController!);
            }
            throw const FormatException('unsupported file (not an image or videos)');
          }
          return const CupertinoActivityIndicator();
        },
      ),
    );
  }
  /// Get file in asset and then initialize video controller
  Future<void> getVideoFile(AssetEntity asset) async {
    final assetFile = await asset.file;
    await widget.videoController.initialize(file: assetFile!);
  }

  /// Returns the [Crop] widget
  // Widget _buildCropView(AssetEntity asset, CropInternal? cropParam) => Opacity(
  //       opacity: widget.cropController.isCropViewReady.value ? widget.opacity : 1.0,
  //       child: Crop(
  //         key: _cropKey,
  //         image: AssetEntityImageProvider(asset, isOriginal: true),
  //         placeholderWidget: ValueListenableBuilder<bool>(
  //           valueListenable: _isLoadingError,
  //           builder: (context, isLoadingError, child) => Stack(
  //             alignment: Alignment.center,
  //             children: [
  //               Opacity(
  //                 opacity: widget.opacity,
  //                 child: ExtendedImage(
  //                   // to match crop alignment
  //                   alignment: widget.cropController.aspectRatio == 1.0 ? Alignment.center : Alignment.bottomCenter,
  //                   height: widget.height,
  //                   width: widget.height * widget.cropController.aspectRatio,
  //                   image: AssetEntityImageProvider(asset, isOriginal: false),
  //                   enableMemoryCache: false,
  //                   fit: BoxFit.cover,
  //                 ),
  //               ),
  //               // show backdrop when image is loading or if an error occured
  //               Positioned.fill(
  //                   child: DecoratedBox(
  //                 decoration: BoxDecoration(color: widget.theme?.cardColor.withOpacity(0.4)),
  //               )),
  //               isLoadingError ? Text(widget.textDelegate.loadFailed) : widget.loaderWidget,
  //             ],
  //           ),
  //         ),
  //         // if the image could not be loaded (i.e unsupported format like RAW)
  //         // unselect it and clear cache, also show the error widget
  //         onImageError: (exception, stackTrace) {
  //           widget.provider.unSelectAsset(asset);
  //           AssetEntityImageProvider(asset).evict();
  //           WidgetsBinding.instance.addPostFrameCallback((_) {
  //             _isLoadingError.value = true;
  //             widget.cropController.isCropViewReady.value = true;
  //           });
  //         },
  //         onLoading: (isReady) =>
  //             WidgetsBinding.instance.addPostFrameCallback((_) => widget.cropController.isCropViewReady.value = isReady),
  //         maximumScale: 10,
  //         aspectRatio: widget.cropController.aspectRatio,
  //         disableResize: true,
  //         backgroundColor: widget.theme!.canvasColor,
  //         initialParam: cropParam,
  //       ),
  //     );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder<AssetEntity?>(
        valueListenable: widget.cropController.previewAsset,
        builder: (_, previewAsset, __) => Selector<DefaultAssetPickerProvider, List<AssetEntity>>(
            selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets,
            builder: (_, List<AssetEntity> selected, __) {
              _isLoadingError.value = false;
              final int effectiveIndex = selected.isEmpty ? 0 : selected.indexOf(selected.last);

              // if no asset is selected yet, returns the loader
              if (previewAsset == null && selected.isEmpty) {
                return widget.loaderWidget;
              }

              final asset = previewAsset ?? selected[effectiveIndex];
              final savedCropParam = widget.cropController.get(asset)?.cropParam;

              // if the selected asset changed, save the previous crop parameters state
              if (asset != _previousAsset && _previousAsset != null) {
                saveCurrentCropChanges();
              }

              _previousAsset = asset;

              // don't show crop button if an asset is selected or if there is only one crop
              return selected.length > 1 || widget.cropController.cropDelegate.cropRatios.length <= 1
                  ? _buildCropView(asset, savedCropParam)
                  : ValueListenableBuilder<int>(
                      valueListenable: widget.cropController.cropRatioIndex,
                      builder: (context, index, child) => Stack(
                        children: [
                          Positioned.fill(
                            child: _buildCropView(asset, savedCropParam),
                          ),
                          // Build crop aspect ratio button
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: _buildCropButton(),
                          ),
                        ],
                      ),
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
          if (widget.cropController.isCropViewReady.value) {
            widget.cropController.nextCropRatio();
          }
        },
        theme: widget.theme?.copyWith(
          buttonTheme: const ButtonThemeData(padding: EdgeInsets.all(2)),
        ),
        size: 32,
        // if crop ratios are the default ones, build UI similar to instagram
        icon: widget.cropController.cropDelegate.cropRatios == kDefaultInstaCropRatios
            ? Transform.rotate(
                angle: 45 * math.pi / 180,
                child: Icon(
                  widget.cropController.aspectRatio == 1 ? Icons.unfold_more : Icons.unfold_less,
                ),
              )
            // otherwise simply display the selected aspect ratio
            : Text(widget.cropController.aspectRatioString),
      ),
    );
  }
}
