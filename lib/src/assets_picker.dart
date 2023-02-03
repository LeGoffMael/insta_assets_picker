import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const _kGridCount = 4;
const _kInitializeDelayDuration = Duration(milliseconds: 250);

class InstaAssetPicker {
  InstaAssetPickerBuilder? builder;

  void dispose() {
    builder?.dispose();
  }

  /// When using `restorableAssetsPicker` function, the picker's state is preserved even after pop
  /// ⚠️ [InstaAssetPicker] and [provider] must be disposed manually
  ///
  /// Set [useRootNavigator] to determine
  /// whether the picker route should use the root [Navigator].
  ///
  /// By extending the [AssetPickerPageRoute], users can customize the route
  /// and use it with the [pageRouteBuilder].
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [provider] of type [DefaultAssetPickerProvider] to specifies picker options.
  /// This argument is required.
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount].
  ///
  /// - Set [pickerTheme] to specifies the theme to apply to the picker.
  /// It is by default initialized with the `primaryColor` of the context theme.
  ///
  /// - Set [textDelegate] to specifies the language to apply to the picker.
  /// Default is the locale language from the context.
  ///
  /// - Set [title] to specifies the text title in the picker [AppBar].
  ///
  /// - Set [closeOnComplete] to specifies if the picker should be closed
  /// after assets selection confirmation.
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [loadingIndicatorBuilder] to specifies the loader indicator
  /// to display in the picker.
  Future<List<AssetEntity>?> restorableAssetsPicker(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    required DefaultAssetPickerProvider provider,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
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

  /// Pick assets with the given arguments.
  ///
  /// Set [useRootNavigator] to determine
  /// whether the picker route should use the root [Navigator].
  ///
  /// By extending the [AssetPickerPageRoute], users can customize the route
  /// and use it with the [pageRouteBuilder].
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount].
  ///
  /// - Set [pickerTheme] to specifies the theme to apply to the picker.
  /// It is by default initialized with the `primaryColor` of the context theme.
  ///
  /// - Set [textDelegate] to specifies the language to apply to the picker.
  /// Default is the locale language from the context.
  ///
  /// - Set [title] to specifies the text title in the picker [AppBar].
  ///
  /// - Set [closeOnComplete] to specifies if the picker should be closed
  /// after assets selection confirmation.
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [loadingIndicatorBuilder] to specifies the loader indicator
  /// to display in the picker.
  ///
  /// Those arguments are used by [DefaultAssetPickerProvider]
  ///
  /// - Set [selectedAssets] to specifies which assets to preselect when the
  /// picker is opened.
  ///
  /// - Set [maxAssets] to specifies the maximum of assets that can be selected
  /// Defaults to [defaultMaxAssetsCount].
  ///
  /// - Set [pageSize] to specifies the quantity of assets to display in a single page.
  /// Defaults to [defaultAssetsPerPage].
  ///
  /// - Set [pathThumbnailSize] to specifies the album thumbnail size in the albums list
  /// Defaults to [defaultPathThumbnailSize].
  ///
  /// - Set [sortPathDelegate] to specifies the order of the assets
  /// Defaults to [SortPathDelegate.common].
  ///
  /// - Set [sortPathsByModifiedDate] to specifies
  /// whether the modified_date can be used in the sort delegate.
  /// Defaults to `false`.
  ///
  /// - Set [filterOptions] to specifies the rules to include/exclude assets from the list
  ///
  /// - Set [initializeDelayDuration] to specifies the delay before loading the assets
  /// Defaults to [_kInitializeDelayDuration].
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
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
    Duration initializeDelayDuration = _kInitializeDelayDuration,
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
