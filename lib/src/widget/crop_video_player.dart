import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_picker_library/wechat_picker_library.dart';

class InstaAssetsCropVideoPlayer extends StatefulWidget {
  const InstaAssetsCropVideoPlayer({
    super.key,
    required this.asset,
    required this.cropParam,
    required this.textDelegate,
    required this.aspectRatio,
  });

  InstaAssetsCropVideoPlayer.fromCropData(
    InstaAssetsCropData cropData, {
    super.key,
    this.textDelegate,
    required this.aspectRatio,
  })  : asset = cropData.asset,
        cropParam = cropData.cropParam;

  final AssetEntity asset;
  final CropInternal? cropParam;
  final AssetPickerTextDelegate? textDelegate;
  final double aspectRatio;

  @override
  State<InstaAssetsCropVideoPlayer> createState() =>
      _InstaAssetsCropVideoPlayerState();
}

class _InstaAssetsCropVideoPlayerState
    extends State<InstaAssetsCropVideoPlayer> {
  VideoPlayerController? _controller;
  bool hasErrorWhenInitializing = false;

  AssetPickerTextDelegate get textDelegate =>
      widget.textDelegate ?? InstaAssetPicker.defaultTextDelegate(context);

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(InstaAssetsCropVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset) {
      _controller
        ?..pause()
        ..dispose();
      _controller = null;
    }
    hasErrorWhenInitializing = false;
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller
      ?..pause()
      ..dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    final String? url = await widget.asset.getMediaUrl();
    if (url == null) {
      hasErrorWhenInitializing = true;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final Uri uri = Uri.parse(url);
    if (Platform.isAndroid) {
      _controller = VideoPlayerController.contentUri(uri);
    } else {
      _controller = VideoPlayerController.networkUrl(uri);
    }

    try {
      await _controller?.initialize();
      _controller?.setLooping(true);
      _controller?.play();
    } catch (e, s) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: e,
          stack: s,
          library: 'insta_assets_picker',
          silent: true,
        ),
      );
      hasErrorWhenInitializing = true;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Returns a desired dimension of [layout] that respect [r] aspect ratio
  Size computeSizeWithRatio(Size layout, double r) {
    if (layout.aspectRatio == r) {
      return layout;
    }

    if (layout.aspectRatio > r) {
      return Size(layout.height * r, layout.height);
    }

    if (layout.aspectRatio < r) {
      return Size(layout.width, layout.width / r);
    }

    assert(false, 'An error occured while computing the aspectRatio');
    return Size.zero;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const Center(child: ScaleText('loading'));

    if (hasErrorWhenInitializing) {
      return Center(
        child: ScaleText(
          textDelegate.loadFailed,
          semanticsLabel: textDelegate.semanticsTextDelegate.loadFailed,
        ),
      );
    }

    final scale = widget.cropParam?.scale ?? 1;
    final view = widget.cropParam?.view ?? Rect.zero;
    final ratio = widget.cropParam?.ratio ?? widget.aspectRatio;

    return LayoutBuilder(builder: (_, constraints) {
      final size = constraints.biggest;

      final layout =
          computeSizeWithRatio(size, _controller?.value.aspectRatio ?? 1);

      final scaleLayout =
          max(size.width / layout.width, size.height / layout.height);

      final src = Rect.fromLTWH(0.0, 0.0, layout.width, layout.height);
      final dst = Rect.fromLTWH(
        view.left * layout.width * scale * ratio,
        view.top * layout.height * scale * ratio,
        layout.width * scale * ratio,
        layout.height * scale * ratio,
      );

      // Calculate the scale factors
      final double scaleX = dst.width / src.width;
      final double scaleY = dst.height / src.height;

      // Calculate the translation
      final double translateX = (dst.left - src.left);
      final double translateY = (dst.top - src.top);

      return ClipRRect(
        child: Transform.scale(
          scale: scaleLayout,
          // to start from top left
          origin: Offset(0, -layout.height / 2),
          child: Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.scale(
              scale: max(scaleX, scaleY),
              // to start from top left
              origin: Offset(-layout.width / 2, -layout.height / 2),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller?.value.aspectRatio ?? 1,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
