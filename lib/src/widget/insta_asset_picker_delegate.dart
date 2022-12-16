// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:insta_assets_picker/src/widget/crop_viewer.dart';
import 'package:provider/provider.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// The reduced height of the crop view
const _kReducedCropViewHeight = 80;

class InstaAssetPickerBuilder extends DefaultAssetPickerBuilderDelegate {
  InstaAssetPickerBuilder({
    required super.provider,
    super.gridCount = 4,
    super.pickerTheme,
    super.textDelegate,
    this.title,
  }) : super(
          shouldRevertGrid: false,
          initialPermission: PermissionState.authorized,
          specialPickerType: SpecialPickerType.customPreview,
          specialItemPosition: SpecialItemPosition.none,
        );

  final String? title;

  /// Save last position of the grid view scroll controller
  double _lastScrollOffset = 0.0;
  final ValueNotifier<double> _cropViewPosition = ValueNotifier<double>(0);

  @override
  void initState(AssetPickerState<AssetEntity, AssetPathEntity> state) {
    super.initState(state);
  }

  /// Handle scroll on grid view to hide/expand the crop view
  bool _handleScroll(
    BuildContext context,
    ScrollNotification notification,
    double position,
    double minHeight,
  ) {
    final scrollController = super.gridScrollController;
    final isScrollUp = scrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final isScrollDown = scrollController.position.userScrollDirection ==
        ScrollDirection.forward;

    if (notification is ScrollEndNotification) {
      _lastScrollOffset = scrollController.offset;
      // NOTE: causes issue when spamming small scroll gestures
      // move _cropViewPosition to the closest limit (expanded or reduced)
      // if (position > minHeight && position < 0) {
      //   if (position <
      //       -MediaQuery.of(context).size.width + _kReducedCropViewHeight) {
      //     _cropViewPosition.value = minHeight;
      //   } else {
      //     _cropViewPosition.value = 0;
      //   }
      //   _lastScrollOffset = scrollController.offset;
      //   return true;
      // }
    }

    // expand crop view
    if (isScrollDown && scrollController.offset < 0 && position < 0) {
      _cropViewPosition.value = 0;
    } else if (isScrollUp &&
        (scrollController.offset - _lastScrollOffset) * 1.4 >
            MediaQuery.of(context).size.width - position &&
        position > minHeight) {
      // reduce crop view
      _cropViewPosition.value = MediaQuery.of(context).size.width -
          (scrollController.offset - _lastScrollOffset) * 1.4;
    }

    return true;
  }

  @override
  Widget pathEntitySelector(BuildContext context) {
    Widget selector(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4)
            .copyWith(top: 4, bottom: 8),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.splashColor,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4).copyWith(left: 6),
          ),
          onPressed: () {
            Feedback.forTap(context);
            isSwitchingPath.value = !isSwitchingPath.value;
          },
          child: Selector<DefaultAssetPickerProvider,
              PathWrapper<AssetPathEntity>?>(
            selector: (_, DefaultAssetPickerProvider p) => p.currentPath,
            builder: (_, PathWrapper<AssetPathEntity>? p, Widget? w) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (p != null)
                  Flexible(
                    child: Text(
                      isPermissionLimited && p.path.isAll
                          ? textDelegate.accessiblePathName
                          : p.path.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                w!,
              ],
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isSwitchingPath,
              builder: (_, bool isSwitchingPath, Widget? w) => Transform.rotate(
                angle: isSwitchingPath ? math.pi : 0,
                child: w,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: theme.iconTheme.color,
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext c, _) => selector(c),
    );
  }

  @override
  Widget confirmButton(BuildContext context) {
    final Widget button = Consumer<DefaultAssetPickerProvider>(
      builder: (_, DefaultAssetPickerProvider p, __) {
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor:
                p.isSelectedNotEmpty ? themeColor : theme.dividerColor,
          ),
          onPressed: p.isSelectedNotEmpty
              ? () => Navigator.of(context).maybePop(p.selectedAssets)
              : null,
          child: Text(
            p.isSelectedNotEmpty && !isSingleAssetMode
                ? '${textDelegate.confirm}'
                    ' (${p.selectedAssets.length}/${p.maxAssets})'
                : textDelegate.confirm,
          ),
        );
      },
    );
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (_, __) => button,
    );
  }

  @override
  Widget androidLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        leading: Transform.translate(
          offset: const Offset(-8, 0),
          child: backButton(context),
        ),
        actions: <Widget>[confirmButton(context)],
      ),
      body: ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
        value: provider,
        builder: (BuildContext context, _) {
          return Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _cropViewPosition,
                builder: (context, position, child) {
                  final minHeight = -(MediaQuery.of(context).size.width -
                      _kReducedCropViewHeight);

                  return AnimatedPositioned(
                    top: position.clamp(minHeight, 0),
                    duration: position == 0
                        ? const Duration(milliseconds: 250)
                        : Duration.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Listener(
                          onPointerDown: (_) => _cropViewPosition.value = 0,
                          child: CropViewer(
                              provider: provider, theme: pickerTheme),
                        ),
                        pathEntitySelector(context),
                        SizedBox(
                          height: MediaQuery.of(context).size.height -
                              kToolbarHeight -
                              _kReducedCropViewHeight,
                          width: MediaQuery.of(context).size.width,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification notification) =>
                                _handleScroll(
                              context,
                              notification,
                              position,
                              minHeight,
                            ),
                            child: _buildGrid(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              pathEntityListBackdrop(context),
              _buildListAlbums(context),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) => androidLayout(context);

  Widget _buildListAlbums(context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (BuildContext context, _, __) => MediaQuery(
        // fix: https://github.com/fluttercandies/flutter_wechat_assets_picker/issues/395
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: -kToolbarHeight),
        ),
        child: Builder(
          builder: (BuildContext context) => pathEntityListWidget(context),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (BuildContext context, DefaultAssetPickerProvider p, __) {
        final bool shouldDisplayAssets =
            p.hasAssetsToDisplay || shouldBuildSpecialItem;
        // when asset list is available and no asset is selected,
        // select the first of the list
        if (shouldDisplayAssets && p.selectedAssets.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final list =
                await p.currentPath?.path.getAssetListRange(start: 0, end: 1);
            if (list?.isNotEmpty ?? false) {
              p.selectAsset(list!.first);
            }
          });
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: shouldDisplayAssets
              ? MediaQuery(
                  // fix: https://github.com/fluttercandies/flutter_wechat_assets_picker/issues/395
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: -kToolbarHeight),
                  ),
                  child: RepaintBoundary(child: assetsGridBuilder(context)),
                )
              : loadingIndicator(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Theme(
        data: theme,
        child: Material(
          color: theme.canvasColor,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (isAppleOS) appleOSLayout(context) else androidLayout(context),
              if (Platform.isIOS) iOSPermissionOverlay(context),
            ],
          ),
        ),
      ),
    );
  }
}
