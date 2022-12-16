// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insta_assets_picker/src/widget/crop_viewer.dart';
import 'package:provider/provider.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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

  @override
  void initState(AssetPickerState<AssetEntity, AssetPathEntity> state) {
    super.initState(state);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CropViewer(provider: provider, theme: pickerTheme),
                  pathEntitySelector(context),
                  Expanded(child: _buildGrid(context)),
                ],
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
