import 'dart:io';

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_picker_library/wechat_picker_library.dart';

abstract class InstaAssetVideoPlayerStatefulWidget extends StatefulWidget {
  const InstaAssetVideoPlayerStatefulWidget({
    super.key,
    required this.asset,
    this.isLoop = false,
    this.isAutoPlay = false,
  });

  final AssetEntity asset;

  final bool isLoop;
  final bool isAutoPlay;
}

/// Based on _VideoPageBuilderState from wechat_assets_picker: https://github.com/fluttercandies/flutter_wechat_assets_picker/blob/main/lib/src/widget/builder/video_page_builder.dart
mixin InstaAssetVideoPlayerMixin<T extends InstaAssetVideoPlayerStatefulWidget>
    on State<T> {
  /// Controller for the video player.
  VideoPlayerController? videoController;

  /// Whether the controller has initialized.
  bool hasLoaded = false;

  /// Whether there's any error when initialize the video controller.
  bool hasErrorWhenInitializing = false;

  /// Whether the controller is playing.
  bool get isControllerPlaying => videoController?.value.isPlaying ?? false;

  bool isInitializing = false;
  bool isLocallyAvailable = false;

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset) {
      videoController
        ?..pause()
        ..dispose();
      videoController = null;
      hasLoaded = false;
      isInitializing = false;
      isLocallyAvailable = false;
      onError(false);
      onLoading(false);
    }
  }

  @override
  void dispose() {
    videoController
      ?..pause()
      ..dispose();
    super.dispose();
  }

  Future<void> initializeVideoPlayerController() async {
    isInitializing = true;
    isLocallyAvailable = true;
    onLoading(true);
    final String? url = await widget.asset.getMediaUrl();
    if (url == null) {
      onError(true);
      if (mounted) {
        setState(() {});
      }
      onLoading(false);
      return;
    }
    final Uri uri = Uri.parse(url);
    if (Platform.isAndroid) {
      videoController = VideoPlayerController.contentUri(uri);
    } else {
      videoController = VideoPlayerController.networkUrl(uri);
    }

    try {
      await videoController?.initialize();
      hasLoaded = true;
      videoController?.setLooping(widget.isLoop);
      if (widget.isAutoPlay) {
        videoController?.play();
      }
    } catch (e, s) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: e,
          stack: s,
          library: 'insta_assets_picker',
          silent: true,
        ),
      );
      onError(true);
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
    onLoading(false);
  }

  /// Callback for the play button.
  ///
  /// Normally it only switches play state for the player. If the video reaches the end,
  /// then click the button will make the video replay.
  Future<void> playButtonCallback() async {
    if (videoController == null) return;
    if (isControllerPlaying) {
      videoController?.pause();
      return;
    }
    if (videoController?.value.duration == videoController?.value.position) {
      videoController
        ?..seekTo(Duration.zero)
        ..play();
      return;
    }
    videoController?.play();
  }

  void onLoading(bool isLoading) {}
  void onError(bool isError) {
    hasErrorWhenInitializing = isError;
  }

  Widget buildLoader();
  Widget buildInitializationError();
  Widget buildVideoPlayer();

  Widget buildDefault() => buildVideoPlayerBuilder(
        builder: (BuildContext context, AssetEntity asset) {
          if (hasErrorWhenInitializing) {
            return buildInitializationError();
          }
          if (!isLocallyAvailable && !isInitializing) {
            initializeVideoPlayerController();
          }
          if (!hasLoaded) {
            return buildLoader();
          }
          return buildVideoPlayer();
        },
      );

  Widget buildVideoPlayerBuilder({
    required Widget Function(BuildContext, AssetEntity) builder,
  }) =>
      LocallyAvailableBuilder(
        key: ValueKey<String>(widget.asset.id),
        asset: widget.asset,
        isOriginal: false,
        builder: builder,
      );

  @override
  Widget build(BuildContext context) => buildDefault();
}
