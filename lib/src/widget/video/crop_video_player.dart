import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_picker_library/wechat_picker_library.dart';

class CropVideoPlayer extends InstaAssetVideoPlayerStatefulWidget {
  const CropVideoPlayer({
    super.key,
    required super.asset,
    super.isAutoPlay,
    super.isLoop,
    required this.cropParam,
    required this.textDelegate,
    required this.aspectRatio,
    required this.loaderBuilder,
  });

  final CropInternal? cropParam;
  final AssetPickerTextDelegate? textDelegate;
  final double aspectRatio;
  final Widget Function(BuildContext context) loaderBuilder;

  @override
  State<CropVideoPlayer> createState() => _InstaAssetCropVideoPlayerState();
}

class _InstaAssetCropVideoPlayerState extends State<CropVideoPlayer>
    with InstaAssetVideoPlayerMixin {
  AssetPickerTextDelegate get textDelegate =>
      widget.textDelegate ?? InstaAssetPicker.defaultTextDelegate(context);

  @override
  Widget buildLoader() => widget.loaderBuilder(context);

  @override
  Widget buildInitializationError() => Center(
        child: ScaleText(
          textDelegate.loadFailed,
          semanticsLabel: textDelegate.semanticsTextDelegate.loadFailed,
        ),
      );

  @override
  Widget buildVideoPlayer() => InstaAssetCropTransform(
        asset: widget.asset,
        cropParam: widget.cropParam,
        targetAspectRatio: widget.aspectRatio,
        child: VideoPlayer(videoController!),
      );
}
