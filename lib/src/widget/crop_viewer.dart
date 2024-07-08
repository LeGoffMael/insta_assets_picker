import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart' as insta_crop_view;
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
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
  });

  final DefaultAssetPickerProvider provider;
  final AssetPickerTextDelegate textDelegate;
  final InstaAssetsCropController controller;
  final Widget loaderWidget;
  final double height, opacity;
  final ThemeData? theme;

  @override
  State<CropViewer> createState() => CropViewerState();
}

class CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<insta_crop_view.CropState>();
  AssetEntity? _previousAsset;

  @override
  void dispose() {
    // save current crop position on dispose (#25)
    saveCurrentCropChanges();
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

  Widget buildPlaceholder(AssetEntity asset) => Stack(
        alignment: Alignment.center,
        children: [
          // scale it up to match the future video size
          Transform.scale(
            scale: asset.height / widget.height,
            child: Image(
              // generate video thumbnail (low quality for performances)
              image: AssetEntityImageProvider(
                asset,
                thumbnailSize: ThumbnailSize(
                  (widget.height * asset.size.aspectRatio).toInt(),
                  widget.height.toInt(),
                ),
                isOriginal: false,
              ),
            ),
          ),
          // show backdrop when image is loading or if an error occured
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.theme?.cardColor.withOpacity(0.4),
              ),
            ),
          ),
          widget.loaderWidget,
        ],
      );

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

            // hide crop button if video player or if an asset is selected or if there is only one crop
            final hideCropButton = selected.length > 1 ||
                widget.controller.cropDelegate.cropRatios.length <= 1;

            return ValueListenableBuilder<int>(
              valueListenable: widget.controller.cropRatioIndex,
              builder: (context, _, __) => InnerCropView(
                cropKey: _cropKey,
                asset: asset,
                cropParam: savedCropParam,
                controller: widget.controller,
                textDelegate: widget.textDelegate,
                theme: widget.theme,
                opacity: widget.opacity,
                height: widget.height,
                hideCropButton: hideCropButton,
                loaderBuilder: (context) => buildPlaceholder(asset),
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
    required this.loaderBuilder,
    required this.theme,
    required this.opacity,
    required this.height,
    required this.hideCropButton,
    required this.cropKey,
  });

  final insta_crop_view.CropInternal? cropParam;
  final InstaAssetsCropController controller;
  final AssetPickerTextDelegate textDelegate;
  final Widget Function(BuildContext context) loaderBuilder;
  final ThemeData? theme;
  final double opacity, height;
  final bool hideCropButton;
  final GlobalKey<insta_crop_view.CropState> cropKey;

  @override
  State<InnerCropView> createState() => _InnerCropViewState();
}

class _InnerCropViewState extends State<InnerCropView>
    with InstaAssetVideoPlayerMixin {
  @override
  void initState() {
    super.initState();
    if (widget.asset.type != AssetType.video) onLoading(false);
  }

  @override
  void didUpdateWidget(covariant InnerCropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset.type != AssetType.video) onLoading(false);
  }

  @override
  void onLoading(bool isLoading) {
    super.onLoading(isLoading);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.isCropViewReady.value = !isLoading,
    );
  }

  @override
  Widget buildLoader() => widget.loaderBuilder(context);

  @override
  Widget buildInitializationError() => Center(
        child: ScaleText(
          widget.textDelegate.loadFailed,
          semanticsLabel: widget.textDelegate.semanticsTextDelegate.loadFailed,
        ),
      );

  @override
  Widget buildVideoPlayer() => VideoPlayer(videoController!);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity:
              widget.controller.isCropViewReady.value ? widget.opacity : 1.0,
          child: insta_crop_view.Crop(
            key: widget.cropKey,
            maximumScale: 10,
            aspectRatio: widget.controller.aspectRatio,
            disableResize: true,
            backgroundColor: widget.theme!.canvasColor,
            initialParam: widget.cropParam,
            size: widget.asset.size,
            child: widget.asset.type == AssetType.image
                ? Image(
                    key: ValueKey<String>(widget.asset.id),
                    image: AssetEntityImageProvider(
                      widget.asset,
                      thumbnailSize:
                          ThumbnailSize.square(widget.height.toInt()),
                      isOriginal: widget.asset.type == AssetType.image,
                    ),
                  )
                : buildVideoPlayerWrapper(),
          ),
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
