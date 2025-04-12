import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

class Post {
  const Post({
    required this.id,
    required this.files,
    required this.aspectRatio,
    required this.createdAt,
  });

  final int id;
  final List<File> files;
  final double aspectRatio;
  final DateTime createdAt;
}

class PostProgress {
  const PostProgress(this.postId, this.asset, this.value, [this.hasError]);

  final int postId;
  final AssetEntity asset;
  final double value;
  final bool? hasError;
}

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<PostProgress> _progress = [];

  List<Post> get posts => _posts;
  List<PostProgress> get progress => _progress;

  void add(Post post) {
    _posts = [post, ..._posts];
    notifyListeners();
    // remove the progress after a delay
    Future.delayed(Duration(seconds: 1), () => _removeProgress(post.id));
  }

  void remove(int postId) {
    final list = [..._posts];
    final index = list.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    list.removeAt(index);
    _posts = list;
    notifyListeners();
  }

  PostProgress? _addProgress(int postId, AssetEntity asset) {
    final list = [..._progress];
    if (list.indexWhere((p) => p.postId == postId) != -1) return null;
    final p = PostProgress(postId, asset, 0);
    _progress = [p, ...list];
    notifyListeners();
    return p;
  }

  void _updateProgress(int postId, double value, {bool? hasError}) {
    final list = [..._progress];
    final index = list.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    list[index] = PostProgress(postId, list[index].asset, value, hasError);
    _progress = list;
    notifyListeners();
  }

  void _removeProgress(int postId) {
    final list = [..._progress];
    final index = list.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    list.removeAt(index);
    _progress = list;
    notifyListeners();
  }

  /// Save the image cropped files or crop the videos using FFmpeg
  /// FFmpegKit package was retired. So example has been removed.
  Future<void> uploadNewPost(InstaAssetsExportDetails exportDetails) async {
    if (exportDetails.progress < 1 || exportDetails.selectedAssets.isEmpty)
      return;

    final int postId = DateTime.now().millisecondsSinceEpoch;
    final PostProgress? progress =
        _addProgress(postId, exportDetails.selectedAssets.first);

    if (progress == null) {
      throw 'Error: Progress already in progress';
    }

    final List<File> files = [];
    final double step = 1 / exportDetails.data.length;

    for (int i = 0; i < exportDetails.data.length; i++) {
      final item = exportDetails.data[i];

      final double progressValue = (i + 1) * step;

      if (item.croppedFile != null) {
        files.add(item.croppedFile!);
        _updateProgress(postId, progressValue);
        continue;
      }

      final File? originFile = await item.selectedData.asset.originFile;

      if (originFile == null) {
        _updateProgress(postId, progressValue, hasError: true);
        throw 'Error: File cannot be fetched';
      }

      // final String extension = getFileExtension(originFile);
      // final String outputPath =
      //     '${(await getTemporaryDirectory()).path}/output_${postId}_$i${extension}';

      // final String? ffmpegCrop = item.selectedData.ffmpegCrop;
      // final String? ffmpegScale = item.selectedData.ffmpegScale;
      // final List<String> filters = [
      //   if (ffmpegCrop != null) 'crop=${ffmpegCrop}',
      //   if (ffmpegScale != null) 'scale=${ffmpegScale}'
      // ];

      // FFmpegKitConfig.enableStatisticsCallback((stats) {
      //   final asset = exportDetails.selectedAssets[i];
      //   if (asset.type != AssetType.video) return;
      //   final double val = stats.getTime() / asset.duration / 1000;
      //   // update progress based on ffmpeg statistics
      //   _updateProgress(postId, progressValue - step + step * val.clamp(0, 1));
      // });
      // final session = await FFmpegKit.execute(
      //   "-y -i \'${originFile.path}\' ${filters.isNotEmpty ? "-vf \'${filters.join(",")}\'" : ''} -c:a copy \'$outputPath\'",
      // );
      // final returnCode = await session.getReturnCode();

      // if (ReturnCode.isSuccess(returnCode)) {
      //   // SUCCESS
      //   files.add(File(outputPath));
      //   _updateProgress(postId, progressValue);
      // } else if (ReturnCode.isCancel(returnCode)) {
      //   // CANCEL
      //   _updateProgress(postId, progressValue, hasError: true);
      //   throw 'Error: FFmpeg execution got cancel.';
      // } else {
      //   _updateProgress(postId, progressValue, hasError: true);
      //   // ERROR
      //   throw 'Error: FFmpeg failed.';
      // }
    }

    if (files.isEmpty) {
      _updateProgress(postId, 1, hasError: true);
      throw 'Error: result is empty';
    }

    _updateProgress(postId, 1);

    add(
      Post(
        id: postId,
        files: files,
        aspectRatio: exportDetails.aspectRatio,
        createdAt: DateTime.now(),
      ),
    );
  }
}
