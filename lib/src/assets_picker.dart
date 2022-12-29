import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class InstaAssetPicker {
  InstaAssetPickerBuilder? builder;

  void dispose() {
    builder?.dispose();
  }

  /// When using `restorableAssetsPicker` function, the picker's state is preserved even after pop
  /// So [InstaAssetPicker] and [provider] must be disposed manually
  Future<List<AssetEntity>?> restorableAssetsPicker(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,

    /// InstaAssetPickerBuilder options
    int gridCount = 4,
    required DefaultAssetPickerProvider provider,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
    bool closeOnComplete = false,
    Widget Function(BuildContext, bool)? loadingIndicatorBuilder,
  }) async {
    assert(provider.requestType == RequestType.image,
        'Only images can be shown in the picker for now');

    builder ??= InstaAssetPickerBuilder(
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme:
          pickerTheme ?? AssetPicker.themeData(Theme.of(context).primaryColor),
      locale: Localizations.maybeLocaleOf(context),
      keepScrollOffset: true,
      textDelegate: textDelegate,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      closeOnComplete: closeOnComplete,
      onCompleted: onCompleted,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder!,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }

  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,

    /// InstaAssetPickerBuilder options
    int gridCount = 4,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
    bool closeOnComplete = false,
    Widget Function(BuildContext, bool)? loadingIndicatorBuilder,

    /// DefaultAssetPickerProvider options
    List<AssetEntity>? selectedAssets,
    int maxAssets = defaultMaxAssetsCount,
    int pageSize = defaultAssetsPerPage,
    ThumbnailSize pathThumbnailSize = defaultPathThumbnailSize,
    SortPathDelegate<AssetPathEntity>? sortPathDelegate =
        SortPathDelegate.common,
    bool sortPathsByModifiedDate = false,
    FilterOptionGroup? filterOptions,
    Duration initializeDelayDuration = const Duration(milliseconds: 250),
  }) async {
    final DefaultAssetPickerProvider provider = DefaultAssetPickerProvider(
      selectedAssets: selectedAssets,
      maxAssets: maxAssets,
      pageSize: pageSize,
      pathThumbnailSize: pathThumbnailSize,
      requestType: RequestType.image,
      sortPathDelegate: sortPathDelegate,
      sortPathsByModifiedDate: sortPathsByModifiedDate,
      filterOptions: filterOptions,
      initializeDelayDuration: initializeDelayDuration,
    );

    final InstaAssetPickerBuilder builder = InstaAssetPickerBuilder(
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme:
          pickerTheme ?? AssetPicker.themeData(Theme.of(context).primaryColor),
      locale: Localizations.maybeLocaleOf(context),
      keepScrollOffset: false,
      textDelegate: textDelegate,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      closeOnComplete: closeOnComplete,
      onCompleted: onCompleted,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
