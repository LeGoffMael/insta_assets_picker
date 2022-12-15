import 'package:flutter/material.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class InstaAssetPicker {
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    int gridCount = 4,
    DefaultAssetPickerProvider? defaultProvider,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,

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
    assert(
        defaultProvider == null ||
            defaultProvider.requestType == RequestType.image,
        'Only images can be shown in the picker for now');

    final DefaultAssetPickerProvider provider = defaultProvider ??
        DefaultAssetPickerProvider(
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
      textDelegate: textDelegate,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder,
    );
  }
}
