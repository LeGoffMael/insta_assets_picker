// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class InstaAssetPickerBuilder extends DefaultAssetPickerBuilderDelegate {
  InstaAssetPickerBuilder({
    required super.provider,
    super.gridCount = 4,
    super.pickerTheme,
    super.textDelegate,
  }) : super(
          shouldRevertGrid: false,
          initialPermission: PermissionState.authorized,
          specialPickerType: SpecialPickerType.noPreview,
          specialItemPosition: SpecialItemPosition.none,
        );

  @override
  void initState(AssetPickerState<AssetEntity, AssetPathEntity> state) {
    super.initState(state);
  }

  @override
  Widget pathEntitySelector(BuildContext context) {
    Widget selector(BuildContext context) {
      return UnconstrainedBox(
        child: GestureDetector(
          onTap: () {
            Feedback.forTap(context);
            isSwitchingPath.value = !isSwitchingPath.value;
          },
          child: Container(
            height: appBarItemHeight,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: theme.dividerColor,
            ),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  w!,
                ],
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.iconTheme.color!.withOpacity(0.5),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isSwitchingPath,
                    builder: (_, bool isSwitchingPath, Widget? w) {
                      return Transform.rotate(
                        angle: isSwitchingPath ? math.pi : 0,
                        child: w,
                      );
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
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
        leading: backButton(context),
        actions: <Widget>[confirmButton(context)],
      ),
      body: ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
        value: provider,
        builder: (BuildContext context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildViewer(provider),
              pathEntitySelector(context),
              Expanded(child: _buildGrid(context)),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) => androidLayout(context);

  Widget _buildViewer(DefaultAssetPickerProvider provider) {
    final List<AssetEntity> current = provider.currentAssets
        .where((AssetEntity e) => e.type == AssetType.image)
        .toList();
    final List<AssetEntity> selected = provider.selectedAssets;

    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }

    final int effectiveIndex = current.indexOf(selected.last);

    // TODO : add crop view
    return Text('Viewer');

    // return AssetPickerViewer<AssetEntity, AssetPathEntity>(
    //   builder: DefaultAssetPickerViewerBuilderDelegate(
    //     currentIndex: effectiveIndex,
    //     previewAssets: current,
    //     provider: AssetPickerViewerProvider<AssetEntity>(
    //       selected,
    //       maxAssets: this.provider.maxAssets,
    //     ),
    //     themeData: AssetPicker.themeData(themeColor),
    //     previewThumbnailSize: previewThumbnailSize,
    //     specialPickerType: specialPickerType,
    //     selectedAssets: selected,
    //     selectorProvider: provider,
    //     maxAssets: this.provider.maxAssets,
    //     selectPredicate: selectPredicate,
    //   ),
    // );
  }

  Widget _buildGrid(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (BuildContext context, DefaultAssetPickerProvider p, __) {
        final bool shouldDisplayAssets =
            p.hasAssetsToDisplay || shouldBuildSpecialItem;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: shouldDisplayAssets
              ? MediaQuery(
                  // fix: https://github.com/fluttercandies/flutter_wechat_assets_picker/issues/395
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: -kToolbarHeight),
                  ),
                  child: Builder(
                    builder: (BuildContext context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        padding: const EdgeInsets.only(top: -kToolbarHeight),
                      ),
                      child: Builder(
                        builder: (BuildContext context) => Stack(
                          children: <Widget>[
                            RepaintBoundary(child: assetsGridBuilder(context)),
                            pathEntityListBackdrop(context),
                            pathEntityListWidget(context),
                          ],
                        ),
                      ),
                    ),
                  ),
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
