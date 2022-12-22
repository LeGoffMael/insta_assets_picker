// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';
import 'package:insta_assets_picker/src/widget/circle_icon_button.dart';
import 'package:insta_assets_picker/src/widget/crop_viewer.dart';
import 'package:provider/provider.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// The reduced height of the crop view
const _kReducedCropViewHeight = 50.0;
const _kIndicatorSize = 20.0;
const _kPathSelectorRowHeight = 50.0;

class InstaAssetPickerBuilder extends DefaultAssetPickerBuilderDelegate {
  InstaAssetPickerBuilder({
    required super.provider,
    required this.onCompleted,
    this.onProgress,
    super.gridCount = 4,
    super.pickerTheme,
    super.textDelegate,
    this.title,
    this.initialCropParameters,
  }) : super(
          shouldRevertGrid: false,
          initialPermission: PermissionState.authorized,
          specialItemPosition: SpecialItemPosition.none,
          keepScrollOffset: true,
        );

  final String? title;

  final List<InstaAssetsCrop>? initialCropParameters;

  final Function(Future<InstaAssetsExportDetails>) onCompleted;

  /// Is called when crop function is updating
  /// The [progress] param represents progress indicator between `0.0` and `1.0`.
  final Function(double progress)? onProgress;

  /// Save last position of the grid view scroll controller
  double _lastScrollOffset = 0.0;
  double _lastEndScrollOffset = 0.0;

  /// set to `true` when grid view scroll position should not be updated after crop is expanded
  /// i.e: when select an asset
  bool _gridScrollLock = false;

  final ValueNotifier<double> _cropViewPosition = ValueNotifier<double>(0);
  final _cropViewerKey = GlobalKey<CropViewerState>();
  late final _cropController = InstaAssetsCropController(initialCropParameters);

  @override
  void initState(AssetPickerState<AssetEntity, AssetPathEntity> state) {
    super.initState(state);
  }

  @override
  void dispose() {
    _cropController.dispose();
    _cropViewPosition.dispose();
    super.dispose();
  }

  void onConfirm(BuildContext context) {
    Navigator.of(context).maybePop(provider.selectedAssets);
    _cropViewerKey.currentState?.saveCurrentCropChanges();
    onCompleted(_cropController.exportCropFiles(onProgress: (p) {
      if (onProgress != null) {
        onProgress!(p);
      }
    }));
  }

  void _expandCropView([bool lockScroll = false]) {
    _gridScrollLock = lockScroll;
    _cropViewPosition.value = 0;
  }

  void unSelectAll() {
    provider.selectedAssets = [];
    _cropController.clear();
  }

  /// Initialize [previewAsset] with [p.selectedAssets] if not empty
  /// otherwise if the first item of the album
  Future<void> _initializePreviewAsset(
    DefaultAssetPickerProvider p,
    bool shouldDisplayAssets,
  ) async {
    if (_cropController.previewAsset.value != null) return;

    if (p.selectedAssets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _cropController.previewAsset.value = p.selectedAssets.last);
    }

    // when asset list is available and no asset is selected,
    // preview the first of the list
    if (shouldDisplayAssets && p.selectedAssets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final list =
            await p.currentPath?.path.getAssetListRange(start: 0, end: 1);
        if (list?.isNotEmpty ?? false) {
          _cropController.previewAsset.value = list!.first;
        }
      });
    }
  }

  @override
  Future<void> viewAsset(
    BuildContext context,
    int index,
    AssetEntity currentAsset,
  ) async {
    if (_cropController.isCropViewReady.value != true) {
      return;
    }

    // if is preview asset, unselect it
    if (provider.selectedAssets.isNotEmpty &&
        _cropController.previewAsset.value == currentAsset) {
      selectAsset(context, currentAsset, true);
      _cropController.previewAsset.value = provider.selectedAssets.isEmpty
          ? currentAsset
          : provider.selectedAssets.last;
      return;
    }

    _cropController.previewAsset.value = currentAsset;
    selectAsset(context, currentAsset, false);
  }

  @override
  Future<void> selectAsset(
    BuildContext context,
    AssetEntity asset,
    bool selected,
  ) async {
    if (_cropController.isCropViewReady.value != true) {
      return;
    }

    final prevCount = provider.selectedAssets.length;
    await super.selectAsset(context, asset, selected);

    // update preview asset with selected
    final selectedAssets = provider.selectedAssets;
    if (prevCount < selectedAssets.length) {
      _cropController.previewAsset.value = asset;
    } else if (selected &&
        asset == _cropController.previewAsset.value &&
        selectedAssets.isNotEmpty) {
      _cropController.previewAsset.value = selectedAssets.last;
    }
    _expandCropView(true);
  }

  /// Handle scroll on grid view to hide/expand the crop view
  bool _handleScroll(
    BuildContext context,
    ScrollNotification notification,
    double position,
    double minHeight,
  ) {
    final isScrollUp = gridScrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final isScrollDown = gridScrollController.position.userScrollDirection ==
        ScrollDirection.forward;

    if (notification is ScrollEndNotification) {
      _lastEndScrollOffset = gridScrollController.offset;
      // reduce crop view
      if (position > minHeight && position < 0) {
        _cropViewPosition.value = minHeight;
        return true;
      }
    }

    // expand crop view
    if (isScrollDown && gridScrollController.offset < 0 && position < 0) {
      // if scroll at edge, compute position based on scroll
      if (_lastScrollOffset > gridScrollController.offset) {
        _cropViewPosition.value -=
            (_lastScrollOffset.abs() - gridScrollController.offset.abs()) * 6;
      } else {
        // otherwise just expand it
        _expandCropView();
      }
    } else if (isScrollUp &&
        (gridScrollController.offset - _lastEndScrollOffset) * 1.4 >
            MediaQuery.of(context).size.width - position &&
        position > minHeight) {
      // reduce crop view
      _cropViewPosition.value = MediaQuery.of(context).size.width -
          (gridScrollController.offset - _lastEndScrollOffset) * 1.4;
    }

    _lastScrollOffset = gridScrollController.offset;

    return true;
  }

  /// Returns a loader [Widget] to show in crop view and instead of confirm button
  Widget _buildLoader(BuildContext context, double radius) {
    if (super.loadingIndicatorBuilder != null) {
      return super.loadingIndicatorBuilder!(context, provider.isAssetsEmpty);
    }

    return Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoActivityIndicator(animating: true, radius: radius)
        : CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          );
  }

  @override
  Widget pathEntitySelector(BuildContext context) {
    Widget selector(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4)
            .copyWith(top: 8, bottom: 12),
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
    final Widget button = ValueListenableBuilder<bool>(
      valueListenable: _cropController.isCropViewReady,
      builder: (_, isLoaded, __) => Consumer<DefaultAssetPickerProvider>(
        builder: (_, DefaultAssetPickerProvider p, __) {
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  p.isSelectedNotEmpty ? themeColor : theme.dividerColor,
            ),
            onPressed: isLoaded && p.isSelectedNotEmpty
                ? () => onConfirm(context)
                : null,
            child: isLoaded
                ? Text(
                    p.isSelectedNotEmpty && !isSingleAssetMode
                        ? '${textDelegate.confirm}'
                            ' (${p.selectedAssets.length}/${p.maxAssets})'
                        : textDelegate.confirm,
                  )
                : _buildLoader(context, 10),
          );
        },
      ),
    );
    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (_, __) => button,
    );
  }

  @override
  Widget androidLayout(BuildContext context) {
    // height of appbar + cropview + path selector row
    final topWidgetHeight = MediaQuery.of(context).size.width +
        kToolbarHeight +
        _kPathSelectorRowHeight +
        MediaQuery.of(context).padding.top;

    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (context, _) => ValueListenableBuilder<double>(
          valueListenable: _cropViewPosition,
          builder: (context, position, child) {
            final minHeight = -(MediaQuery.of(context).size.width -
                _kReducedCropViewHeight +
                kToolbarHeight);

            position = position.clamp(minHeight, 0);
            final opacity = ((position / -minHeight) + 1).clamp(0.4, 1.0);

            double gridHeight = MediaQuery.of(context).size.height -
                kToolbarHeight -
                _kReducedCropViewHeight;
            // when not assets are displayed, compute the exact height to show the loader
            if (!provider.hasAssetsToDisplay) {
              gridHeight -=
                  MediaQuery.of(context).size.width - -_cropViewPosition.value;
            }
            final topPadding = topWidgetHeight +
                position +
                (_gridScrollLock ? minHeight / 2 : 0);
            _gridScrollLock = false;

            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: SizedBox(
                    height: gridHeight,
                    width: MediaQuery.of(context).size.width,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => _handleScroll(
                        context,
                        notification,
                        position,
                        minHeight,
                      ),
                      child: _buildGrid(context),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  top: position,
                  duration: position == minHeight || position == 0
                      ? const Duration(milliseconds: 250)
                      : Duration.zero,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: topWidgetHeight,
                    child: AssetPickerAppBarWrapper(
                      appBar: AssetPickerAppBar(
                        title: title != null
                            ? Text(
                                title!,
                                style: Theme.of(context).textTheme.titleLarge,
                              )
                            : null,
                        leading: backButton(context),
                        actions: <Widget>[confirmButton(context)],
                      ),
                      body: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pickerTheme?.canvasColor,
                        ),
                        child: Column(
                          children: [
                            Listener(
                              onPointerDown: (_) {
                                _expandCropView();
                                // stop scroll event
                                gridScrollController
                                    .jumpTo(gridScrollController.offset);
                              },
                              child: Opacity(
                                opacity: opacity,
                                child: CropViewer(
                                  key: _cropViewerKey,
                                  controller: _cropController,
                                  provider: provider,
                                  loaderWidget: _buildLoader(context, 16),
                                  theme: pickerTheme,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: _kPathSelectorRowHeight,
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  pathEntitySelector(context),
                                  CircleIconButton(
                                    onTap: unSelectAll,
                                    theme: pickerTheme,
                                    icon: const Icon(
                                      Icons.layers_clear_sharp,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                pathEntityListBackdrop(context),
                _buildListAlbums(context),
              ],
            );
          }),
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) => androidLayout(context);

  Widget _buildListAlbums(context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (BuildContext context, _, __) => Builder(
        builder: (BuildContext context) => pathEntityListWidget(context),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (BuildContext context, DefaultAssetPickerProvider p, __) {
        final bool shouldDisplayAssets =
            p.hasAssetsToDisplay || shouldBuildSpecialItem;
        _initializePreviewAsset(p, shouldDisplayAssets);

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

  /// To show selected assets indicator and preview asset overlay
  @override
  Widget selectIndicator(BuildContext context, int index, AssetEntity asset) {
    final selectedAssets = provider.selectedAssets;
    final Duration duration = switchingPathDuration * 0.75;

    final int indexSelected = selectedAssets.indexOf(asset);
    final bool isSelected = indexSelected != -1;

    final Widget innerSelector = AnimatedContainer(
      duration: duration,
      width: _kIndicatorSize,
      height: _kIndicatorSize,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.selectedRowColor, width: 1),
        color: isSelected ? themeColor : theme.selectedRowColor.withOpacity(.2),
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        child: AnimatedSwitcher(
          duration: duration,
          reverseDuration: duration,
          child: isSelected
              ? Text((indexSelected + 1).toString())
              : const SizedBox.shrink(),
        ),
      ),
    );

    return ValueListenableBuilder<AssetEntity?>(
      valueListenable: _cropController.previewAsset,
      builder: (context, previewAsset, child) {
        final bool isPreview = asset == _cropController.previewAsset.value;

        return Positioned.fill(
          child: GestureDetector(
            onTap: isPreviewEnabled
                ? () => viewAsset(context, index, asset)
                : null,
            child: AnimatedContainer(
              duration: switchingPathDuration,
              padding: const EdgeInsets.all(4),
              color: isPreview
                  ? theme.selectedRowColor.withOpacity(.5)
                  : theme.backgroundColor.withOpacity(.1),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: isSelected && !isSingleAssetMode
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => selectAsset(context, asset, isSelected),
                        child: innerSelector,
                      )
                    : innerSelector,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget selectedBackdrop(BuildContext context, int index, AssetEntity asset) =>
      const SizedBox.shrink();

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
