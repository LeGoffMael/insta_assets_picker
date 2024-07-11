import 'dart:io';

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/main.dart';
import 'package:insta_assets_picker_demo/post_provider.dart';
import 'package:insta_assets_picker_demo/utils.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PostProgressList extends StatelessWidget {
  const PostProgressList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PostProgress> list =
        context.select((PostProvider p) => p.progress);

    return AnimatedSize(
      duration: kThemeAnimationDuration,
      child: list.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (BuildContext context, int index) {
                final PostProgress progress = list[index];

                return SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                          child: Image(
                            image: AssetEntityImageProvider(progress.asset),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LinearProgressIndicator(
                            value: progress.value,
                            color: progress.hasError ?? false
                                ? Colors.redAccent
                                : kDefaultColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                      ),
                      progress.hasError ?? false
                          ? Icon(
                              Icons.error,
                              color: Colors.redAccent,
                            )
                          : Text(
                              '${(progress.value * 100).toInt()}%',
                              style: TextStyle(
                                color: kDefaultColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: list.length,
            ),
    );
  }
}

class PostList extends StatelessWidget {
  const PostList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Post> posts = context.select((PostProvider p) => p.posts);

    return Scaffold(
      appBar: AppBar(title: Text('My Posts')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PostProgressList()),
          SliverList.separated(
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(post: posts[index]),
            separatorBuilder: (_, __) => SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: width,
      height: width / post.aspectRatio,
      child: PageView.builder(
        itemCount: post.files.length,
        itemBuilder: (context, index) {
          final file = post.files[index];
          final isVideo = isVideoFile(file);

          if (isVideo) {
            return _PostVideoPlayer(file: file);
          }
          return Image.file(file);
        },
      ),
    );
  }
}

class _PostVideoPlayer extends StatefulWidget {
  const _PostVideoPlayer({required this.file});

  final File file;

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

// Based on `video_player` example: https://pub.dev/packages/video_player/example
class _PostVideoPlayerState extends State<_PostVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          VideoPlayer(_controller),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 50),
            reverseDuration: const Duration(milliseconds: 200),
            child: _controller.value.isPlaying
                ? const SizedBox.shrink()
                : const ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40.0,
                        semanticLabel: 'Play',
                      ),
                    ),
                  ),
          ),
          GestureDetector(
            onTap: () {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            },
          ),
        ],
      );
}
