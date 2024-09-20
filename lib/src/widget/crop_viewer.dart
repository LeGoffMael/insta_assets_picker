import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart' as insta_crop_view;
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_picker_library/wechat_picker_library.dart';

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
    this.previewThumbnailSize,
  });

  final DefaultAssetPickerProvider provider;
  final AssetPickerTextDelegate textDelegate;
  final InstaAssetsCropController controller;
  final Widget loaderWidget;
  final double height, opacity;
  final ThemeData? theme;
  final ThumbnailSize? previewThumbnailSize;

  @override
  State<CropViewer> createState() => CropViewerState();
}

class CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<insta_crop_view.CropState>();
  AssetEntity? _previousAsset;

  @override
  void deactivate() {
    // save current crop position before dispose (#25)
    saveCurrentCropChanges();
    super.deactivate();
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: widget.height,
      width: width,
      child: ValueListenableBuilder<AssetEntity?>(
        valueListenable: widget.controller.previewAsset,
        builder: (_, previewAsset, __) =>
            Selector<DefaultAssetPickerProvider, List<AssetEntity>>(
          selector: (_, DefaultAssetPickerProvider p) => p.selectedAssets,
          builder: (_, List<AssetEntity> selected, __) {
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
              saveCurrentCropChanges();
            }

            _previousAsset = asset;

            // hide crop button if an asset is selected or if there is only one crop
            final hideCropButton = selected.length > 1 ||
                widget.controller.cropDelegate.cropRatios.length <= 1;

            return ValueListenableBuilder<int>(
              valueListenable: widget.controller.cropRatioIndex,
              builder: (context, _, __) => Opacity(
                opacity: widget.opacity,
                child: InnerCropView(
                  cropKey: _cropKey,
                  asset: asset,
                  cropParam: savedCropParam,
                  controller: widget.controller,
                  textDelegate: widget.textDelegate,
                  theme: widget.theme,
                  height: widget.height,
                  hideCropButton: hideCropButton,
                  previewThumbnailSize: widget.previewThumbnailSize,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class InnerCropView extends InstaAssetVideoPlayerStatefulWidget {
  const InnerCropView({
    super.key,
    required super.asset,
    required this.cropParam,
    required this.controller,
    required this.textDelegate,
    required this.theme,
    required this.height,
    required this.hideCropButton,
    required this.cropKey,
    required this.previewThumbnailSize,
  });

  final insta_crop_view.CropInternal? cropParam;
  final InstaAssetsCropController controller;
  final AssetPickerTextDelegate textDelegate;
  final ThemeData? theme;
  final double height;
  final bool hideCropButton;
  final GlobalKey<insta_crop_view.CropState> cropKey;
  final ThumbnailSize? previewThumbnailSize;

  @override
  State<InnerCropView> createState() => _InnerCropViewState();
}

class _InnerCropViewState extends State<InnerCropView>
    with InstaAssetVideoPlayerMixin {
  final ValueNotifier<bool> _isLoadingError = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
    _isLoadingError.dispose();
  }

  @override
  void onLoading(bool isLoading) {
    super.onLoading(isLoading);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.isCropViewReady.value = !isLoading,
    );
  }

  @override
  void onError(bool isError) {
    super.onError(isError);
    _isLoadingError.value = isError;
  }

  @override
  Widget buildLoader() => Transform.scale(
        scale: widget.asset.orientatedHeight / widget.height,
        child: Image(
          // generate video thumbnail (low quality for performances)
          image: AssetEntityImageProvider(
            widget.asset,
            thumbnailSize: widget.previewThumbnailSize != null
                ? ThumbnailSize(
                    (widget.previewThumbnailSize!.height *
                            widget.asset.orientatedSize.aspectRatio)
                        .toInt(),
                    widget.previewThumbnailSize!.height.toInt(),
                  )
                : ThumbnailSize(
                    (widget.height * widget.asset.orientatedSize.aspectRatio)
                        .toInt(),
                    widget.height.toInt(),
                  ),
            isOriginal: false,
          ),
        ),
      );

  @override
  Widget buildInitializationError() => ScaleText(
        widget.textDelegate.loadFailed,
        semanticsLabel: widget.textDelegate.semanticsTextDelegate.loadFailed,
      );

  @override
  Widget buildVideoPlayer() => VideoPlayer(videoController!);

  @override
  Widget buildDefault() {
    if (!isLocallyAvailable && !isInitializing) {
      initializeVideoPlayerController();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(opacity: animation, child: child),
      child: hasLoaded ? buildVideoPlayer() : buildLoader(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LocallyAvailableBuilder(
          key: ValueKey<String>(widget.asset.id),
          asset: widget.asset,
          isOriginal: true,
          builder: (BuildContext context, AssetEntity asset) =>
              insta_crop_view.Crop(
            key: widget.cropKey,
            maximumScale: 10,
            aspectRatio: widget.controller.aspectRatio,
            disableResize: true,
            backgroundColor: widget.theme!.canvasColor,
            initialParam: widget.cropParam,
            size: widget.asset.orientatedSize,
            child: widget.asset.type == AssetType.image
                ? ExtendedImage(
                    image: AssetEntityImageProvider(
                      widget.asset,
                      isOriginal: true,
                    ),
                    loadStateChanged: (ExtendedImageState state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.completed:
                          onLoading(false);
                          onError(false);
                          return state.completedWidget;
                        case LoadState.loading:
                          onLoading(true);
                          onError(false);
                          return buildLoader();
                        case LoadState.failed:
                          onLoading(false);
                          onError(true);
                          return buildLoader();
                      }
                    },
                  )
                // build video
                : buildDefault(),
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingError,
          builder: (context, isLoadingError, __) => isLoadingError
              ? Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.theme?.cardColor.withOpacity(0.4),
                    ),
                    child: Center(child: buildInitializationError()),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Build crop aspect ratio button
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.hideCropButton
                  ? const SizedBox.shrink()
                  : _buildCropButton(),
              if (widget.asset.type == AssetType.video) _buildPlayVideoButton(),
            ],
          ),
        ),
      ],
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
    if (videoController == null || !hasLoaded) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: videoController!,
      builder: (_, __) => Opacity(
        opacity: 0.6,
        child: InstaPickerCircleIconButton(
          onTap: playButtonCallback,
          theme: widget.theme?.copyWith(
            buttonTheme: const ButtonThemeData(padding: EdgeInsets.all(2)),
          ),
          size: 32,
          icon: isControllerPlaying
              ? const Icon(Icons.pause_rounded)
              : const Icon(Icons.play_arrow_rounded),
        ),
      ),
    );
  }
}
