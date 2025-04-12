import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:video_player/video_player.dart';

class PickerCropResultScreen extends StatelessWidget {
  const PickerCropResultScreen({super.key, required this.cropStream});

  final Stream<InstaAssetsExportDetails> cropStream;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker result')),
      body: StreamBuilder<InstaAssetsExportDetails>(
        stream: cropStream,
        builder: (context, snapshot) => CropResultView(
          result: snapshot.data,
          heightFiles: height / 2,
          heightAssets: height / 4,
        ),
      ),
    );
  }
}

class CropResultView extends StatelessWidget {
  const CropResultView({
    super.key,
    required this.result,
    this.heightFiles = 300.0,
    this.heightAssets = 120.0,
  });

  final InstaAssetsExportDetails? result;
  final double heightFiles;
  final double heightAssets;

  List<InstaAssetsExportData?> get data => result?.data ?? [];
  List<AssetEntity> get selectedAssets => result?.selectedAssets ?? [];

  Widget _buildTitle(String title, int length) {
    return SizedBox(
      height: 20.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurpleAccent,
            ),
            child: Text(
              length.toString(),
              style: const TextStyle(color: Colors.white, height: .7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCroppedAssetsListView(BuildContext context) {
    if (result?.progress == null) {
      return const SizedBox.shrink();
    }

    final double progress = result!.progress;

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            itemBuilder: (BuildContext _, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: data[index]?.croppedFile != null
                      ? Image.file(data[index]!.croppedFile!)
                      : PickerResultPreview(
                          cropData: data[index]!.selectedData,
                          isAutoPlay: index == 0,
                        ),
                ),
              );
            },
          ),
          if (progress < 1.0)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: .5),
                ),
              ),
            ),
          if (progress < 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    semanticsLabel: '${progress * 100}%',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedAssetsListView() {
    if (selectedAssets.isEmpty) return const SizedBox.shrink();

    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: selectedAssets.length,
        itemBuilder: (BuildContext _, int index) {
          final AssetEntity asset = selectedAssets[index];

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            // TODO : add delete action
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Image(image: AssetEntityImageProvider(asset)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedContainer(
          duration: kThemeChangeDuration,
          curve: Curves.easeInOut,
          height: data.isNotEmpty ? heightFiles : 40.0,
          child: Column(
            children: <Widget>[
              _buildTitle('Crop Results', data.length),
              _buildCroppedAssetsListView(context),
            ],
          ),
        ),
        AnimatedContainer(
          duration: kThemeChangeDuration,
          curve: Curves.easeInOut,
          height: selectedAssets.isNotEmpty ? heightAssets : 40.0,
          child: Column(
            children: <Widget>[
              _buildTitle('Selected Assets', selectedAssets.length),
              _buildSelectedAssetsListView(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: result != null &&
                      result?.progress != null &&
                      result!.progress >= 1 &&
                      selectedAssets.isNotEmpty
                  ? () {
                      // context.read<PostProvider>().uploadNewPost(result!);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.all(10),
                        content: const Text(
                            'Here you could export the videos and images and upload them to your server'),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload'),
            ),
          ),
        ),
      ],
    );
  }
}

class PickerResultPreview extends InstaAssetVideoPlayerStatefulWidget {
  PickerResultPreview({
    super.key,
    required this.cropData,
    super.isAutoPlay,
    super.isLoop,
  }) : super(asset: cropData.asset);

  final InstaAssetsCropData cropData;

  @override
  State<PickerResultPreview> createState() => _PickerResultVideoPlayerState();
}

class _PickerResultVideoPlayerState extends State<PickerResultPreview>
    with InstaAssetVideoPlayerMixin {
  @override
  Widget buildLoader() => const Center(child: CircularProgressIndicator());

  @override
  Widget buildInitializationError() =>
      const Center(child: Text('Sorry the video could not be loaded.'));

  @override
  Widget buildVideoPlayer() {
    return GestureDetector(
      onTap: playButtonCallback,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          InstaAssetCropTransform(
            asset: widget.asset,
            cropParam: widget.cropData.cropParam,
            child: VideoPlayer(videoController!),
          ),
          if (videoController != null)
            AnimatedBuilder(
              animation: videoController!,
              builder: (_, __) => AnimatedOpacity(
                opacity: isControllerPlaying ? 0 : 1,
                duration: kThemeAnimationDuration,
                child: CircleAvatar(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: .7),
                  radius: 24,
                  child: const Icon(Icons.play_arrow_rounded, size: 40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.asset.type == AssetType.image
            ? InstaAssetCropTransform(
                asset: widget.asset,
                cropParam: widget.cropData.cropParam,
                child: Image(image: AssetEntityImageProvider(widget.asset)),
              )
            : buildDefault(),
        const Text('⚠️ Preview ⚠️', style: TextStyle(color: Colors.redAccent)),
      ],
    );
  }
}
