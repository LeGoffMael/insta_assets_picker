// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const _kGridCount = 4;
const _kInitializeDelayDuration = Duration(milliseconds: 250);
const kDefaultInstaCropRatios = [1.0, 4 / 5];

class InstaAssetCropDelegate {
  const InstaAssetCropDelegate({
    this.preferredSize = 1080,
    this.cropRatios = kDefaultInstaCropRatios,
  });

  /// The param [preferredSize] is used to produce higher quality cropped image.
  /// Keep in mind that the higher this value is, the heavier the cropped image will be.
  ///
  /// This value while be used as such
  /// ```dart
  /// preferredSize = (preferredSize / scale).round()
  /// ```
  ///
  /// Defaults to `1080`, like instagram.
  final double preferredSize;

  /// The param [cropRatios] provided the list of crop ratios that can be set
  /// from the crop view.
  ///
  /// Defaults to `[1/1, 4/5]` like instagram.
  final List<double> cropRatios;
}

class InstaAssetPicker {
  InstaAssetPickerBuilder? builder;

  void dispose() {
    builder?.dispose();
  }

  static AssetPickerTextDelegate defaultTextDelegate(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return assetPickerTextDelegateFromLocale(locale);
  }

  static Future<void> refreshAndSelectEntity(
    BuildContext context,
    AssetEntity? entity,
  ) async {
    if (entity == null) {
      return;
    }
    final AssetPicker<AssetEntity, AssetPathEntity> picker = context.findAncestorWidgetOfExactType()!;
    final DefaultAssetPickerBuilderDelegate builder = picker.builder as DefaultAssetPickerBuilderDelegate;
    final DefaultAssetPickerProvider p = builder.provider;
    await p.switchPath(
      PathWrapper<AssetPathEntity>(
        path: await p.currentPath!.path.obtainForNewProperties(),
      ),
    );
    builder.viewAsset(context, 0, entity);
  }

  /// Request the current [PermissionState] of required permissions.
  ///
  /// Throw an error if permissions are unauthorized.
  /// Since the exception is thrown from the MethodChannel it cannot be caught by a try/catch
  ///
  /// check `AssetPickerDelegate.permissionCheck()` from flutter_wechat_assets_picker package for more information.
  static Future<PermissionState> _permissionCheck({RequestType requestType = RequestType.common}) => AssetPicker.permissionCheck(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: requestType,
            mediaLocation: false,
          ),
        ),
      );

  /// Open a [ScaffoldMessenger] describing the reason why the picker cannot be opened.
  static void _openErrorPermission(
    BuildContext context,
    AssetPickerTextDelegate textDelegate,
    Function(BuildContext context, String error)? customHandler,
  ) {
    final defaultDescription = '${textDelegate.unableToAccessAll}\n${textDelegate.goToSystemSettings}';

    if (customHandler != null) {
      customHandler(context, defaultDescription);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(defaultDescription)),
      );
    }
  }

  /// Build a [ThemeData] with the given [themeColor] for the picker.
  ///
  /// check `AssetPickerDelegate.themeData()` from flutter_wechat_assets_picker package for more information.
  static ThemeData themeData(Color? themeColor, {bool light = false}) =>
      AssetPicker.themeData(themeColor, light: light);

  /// When using `restorableAssetsPicker` function, the picker's state is preserved even after pop
  ///
  /// ⚠️ [InstaAssetPicker] and [provider] must be disposed manually
  ///
  /// Set [useRootNavigator] to determine
  /// whether the picker route should use the root [Navigator].
  ///
  /// By extending the [AssetPickerPageRoute], users can customize the route
  /// and use it with the [pageRouteBuilder].
  ///
  /// Set [onPermissionDenied] to manually handle the denied permission error.
  /// The default behavior is to open a [ScaffoldMessenger].
  ///
  /// Crop options
  /// - Set [cropDelegate] to customize the display and export of crops.
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [provider] of type [DefaultAssetPickerProvider] to specifies picker options.
  /// This argument is required.
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount], like instagram.
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
  /// - Set [limitedPermissionOverlayPredicate] to specifies if the limited
  /// permission overlay should be displayed.
  ///
  /// - Set [specialItemPosition] to allows users to set a special item in the picker
  /// with several positions. Since the grid view is reversed, [SpecialItemPosition.prepend]
  /// will be at the top and [SpecialItemPosition.append] at the bottom.
  /// Defaults to [SpecialItemPosition.none].
  ///
  /// - Set [specialItemBuilder] to specifies [Widget] for the the special item.
  ///
  /// - Set [actionsBuilder] function to specifies the [Widget]s to display
  /// on top of the assets grid view. Default is unselect all assets button.
  Future<List<AssetEntity>?> restorableAssetsPicker(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)? onPermissionDenied,

    /// Crop options
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    required DefaultAssetPickerProvider provider,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails) onCompleted,
    Widget Function(BuildContext context, bool isAssetsEmpty)? loadingIndicatorBuilder,
    LimitedPermissionOverlayPredicate? limitedPermissionOverlayPredicate,
    Widget? Function(BuildContext context, AssetPathEntity? path, int length)? specialItemBuilder,
    SpecialItemPosition? specialItemPosition,
    InstaPickerActionsBuilder? actionsBuilder,
    RequestType requestType = RequestType.common,
  }) async {
    assert(provider.requestType == RequestType.image || provider.requestType == RequestType.video, 'Only images or Videos can be shown in the picker for now');

    final text = textDelegate ?? defaultTextDelegate(context);

    PermissionState? ps;
    if (builder == null) {
      try {
        ps = await _permissionCheck(requestType: requestType);
      } catch (e) {
        _openErrorPermission(context, text, onPermissionDenied);
      }
    }

    builder ??= InstaAssetPickerBuilder(
      initialPermission: ps ?? PermissionState.denied,
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme: pickerTheme ?? themeData(Theme.of(context).primaryColor),
      locale: Localizations.maybeLocaleOf(context),
      keepScrollOffset: true,
      textDelegate: text,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      limitedPermissionOverlayPredicate: limitedPermissionOverlayPredicate,
      closeOnComplete: closeOnComplete,
      cropDelegate: cropDelegate,
      onCompleted: onCompleted,
      specialItemBuilder: specialItemBuilder,
      specialItemPosition: specialItemPosition,
      actionsBuilder: actionsBuilder,
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
  /// Set [onPermissionDenied] to manually handle the denied permission error.
  /// The default behavior is to open a [ScaffoldMessenger].
  ///
  /// Crop options
  /// - Set [cropDelegate] to customize the display and export of crops.
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount], like instagram.
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
  /// - Set [limitedPermissionOverlayPredicate] to specifies if the limited
  /// permission overlay should be displayed.
  ///
  /// - Set [actionsBuilder] function to specifies the [Widget]s to display
  /// on top of the assets grid view. Default is unselect all assets button.
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
  ///
  /// - Set [specialItemPosition] to allows users to set a special item in the picker
  /// with several positions. Since the grid view is reversed, [SpecialItemPosition.prepend]
  /// will be at the top and [SpecialItemPosition.append] at the bottom.
  /// Defaults to [SpecialItemPosition.none].
  ///
  /// - Set [specialItemBuilder] to specifies [Widget] for the the special item.
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)? onPermissionDenied,

    /// Crop options
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails) onCompleted,
    Widget Function(BuildContext context, bool isAssetsEmpty)? loadingIndicatorBuilder,
    LimitedPermissionOverlayPredicate? limitedPermissionOverlayPredicate,

    /// DefaultAssetPickerProvider options
    List<AssetEntity>? selectedAssets,
    int maxAssets = defaultMaxAssetsCount,
    int pageSize = defaultAssetsPerPage,
    ThumbnailSize pathThumbnailSize = defaultPathThumbnailSize,
    SortPathDelegate<AssetPathEntity>? sortPathDelegate = SortPathDelegate.common,
    bool sortPathsByModifiedDate = false,
    FilterOptionGroup? filterOptions,
    Duration initializeDelayDuration = _kInitializeDelayDuration,
    Widget? Function(BuildContext context, AssetPathEntity? path, int length)? specialItemBuilder,
    SpecialItemPosition? specialItemPosition,
    InstaPickerActionsBuilder? actionsBuilder,
    RequestType requestType = RequestType.common
  }) async {
    assert(requestType == RequestType.image || requestType == RequestType.video || requestType == RequestType.common, 'Only images or Videos can be shown in the picker for now');
    final text = textDelegate ?? defaultTextDelegate(context);

    // must be called before initializing any picker provider to avoid `PlatformException(PERMISSION_REQUESTING)` type exception
    PermissionState? ps;
    try {
      ps = await _permissionCheck(requestType: requestType);
    } catch (e) {
      _openErrorPermission(context, text, onPermissionDenied);
      return [];
    }

    final DefaultAssetPickerProvider provider = DefaultAssetPickerProvider(
      selectedAssets: selectedAssets,
      maxAssets: maxAssets,
      pageSize: pageSize,
      pathThumbnailSize: pathThumbnailSize,
      requestType: requestType,
      sortPathDelegate: sortPathDelegate,
      sortPathsByModifiedDate: sortPathsByModifiedDate,
      filterOptions: filterOptions,
      initializeDelayDuration: initializeDelayDuration,
    );

    final InstaAssetPickerBuilder builder = InstaAssetPickerBuilder(
      initialPermission: ps,
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme: pickerTheme ?? themeData(Theme.of(context).primaryColor),
      locale: Localizations.maybeLocaleOf(context),
      keepScrollOffset: false,
      textDelegate: text,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      limitedPermissionOverlayPredicate: limitedPermissionOverlayPredicate,
      closeOnComplete: closeOnComplete,
      cropDelegate: cropDelegate,
      onCompleted: onCompleted,
      specialItemBuilder: specialItemBuilder,
      specialItemPosition: specialItemPosition,
      actionsBuilder: actionsBuilder,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
