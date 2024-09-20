// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';

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

/// Configurations for the [InstaAssetPickerBuilder].
class InstaAssetPickerConfig {
  const InstaAssetPickerConfig({
    /// [DefaultAssetPickerBuilderDelegate] config

    this.gridCount = _kGridCount,
    this.pickerTheme,
    this.specialItemPosition,
    this.specialItemBuilder,
    this.loadingIndicatorBuilder,
    this.selectPredicate,
    this.limitedPermissionOverlayPredicate,
    this.themeColor,
    this.textDelegate,
    this.gridThumbnailSize = defaultAssetGridPreviewSize,
    this.previewThumbnailSize,
    this.pathNameBuilder,

    /// [InstaAssetPickerBuilder] config

    this.title,
    this.cropDelegate = const InstaAssetCropDelegate(),
    this.closeOnComplete = false,
    this.skipCropOnComplete = false,
    this.actionsBuilder,
  });

  /* [DefaultAssetPickerBuilderDelegate] config */

  /// Specifies the number of assets in the cross axis.
  ///
  /// Defaults to [_kGridCount], like instagram.
  final int gridCount;

  /// Specifies the theme to apply to the picker.
  /// It is by default initialized with the `primaryColor` of the context theme.
  final ThemeData? pickerTheme;

  /// Set a special item in the picker with several positions.
  /// Since the grid view is reversed, [SpecialItemPosition.prepend]
  /// will be at the top and [SpecialItemPosition.append] at the bottom.
  ///
  /// Defaults to [SpecialItemPosition.none].
  final SpecialItemPosition? specialItemPosition;

  /// Specifies [Widget] for the the special item.
  final SpecialItemBuilder<AssetPathEntity>? specialItemBuilder;

  /// The loader indicator to display in the picker.
  final LoadingIndicatorBuilder? loadingIndicatorBuilder;

  /// Predicate whether an asset can be selected or unselected.
  final AssetSelectPredicate<AssetEntity>? selectPredicate;

  /// Specifies if the limited permission overlay should be displayed.
  final LimitedPermissionOverlayPredicate? limitedPermissionOverlayPredicate;

  /// Main color for the picker.
  final Color? themeColor;

  /// Specifies the language to apply to the picker.
  ///
  /// Default is the locale language from the context.
  final AssetPickerTextDelegate? textDelegate;

  /// Thumbnail size in the grid.
  final ThumbnailSize gridThumbnailSize;

  /// Preview thumbnail size in the crop viewer.
  final ThumbnailSize? previewThumbnailSize;

  /// {@macro wechat_assets_picker.PathNameBuilder}
  final PathNameBuilder<AssetPathEntity>? pathNameBuilder;

  /* [InstaAssetPickerBuilder] config */

  /// Specifies the text title in the picker [AppBar].
  final String? title;

  /// Customize the display and export options of crops
  final InstaAssetCropDelegate cropDelegate;

  /// Specifies if the picker should be closed after assets selection confirmation.
  ///
  /// Defaults to `false`.
  final bool closeOnComplete;

  /// Specifies if the assets should be cropped when the picker is closed.
  /// Set to `true` if you want to perform the crop yourself.
  ///
  /// Defaults to `false`.
  final bool skipCropOnComplete;

  /// The [Widget] to display on top of the assets grid view.
  ///
  /// Default is unselect all assets button.
  final InstaPickerActionsBuilder? actionsBuilder;
}

class InstaAssetPicker {
  InstaAssetPickerBuilder? builder;

  void dispose() {
    builder?.dispose();
    builder = null;
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
    final AssetPicker<AssetEntity, AssetPathEntity> picker =
        context.findAncestorWidgetOfExactType()!;
    final DefaultAssetPickerBuilderDelegate builder =
        picker.builder as DefaultAssetPickerBuilderDelegate;
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
  static Future<PermissionState> _permissionCheck(RequestType? requestType) =>
      AssetPicker.permissionCheck(
        requestOption: PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: requestType ?? RequestType.common,
            mediaLocation: false,
          ),
        ),
      );

  /// Open a [ScaffoldMessenger] describing the reason why the picker cannot be opened.
  static void _openErrorPermission(
    BuildContext context,
    AssetPickerTextDelegate? textDelegate,
    Function(BuildContext context, String error)? customHandler,
  ) {
    final text = textDelegate ?? defaultTextDelegate(context);

    final defaultDescription =
        '${text.unableToAccessAll}\n${text.goToSystemSettings}';

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

  static void _assertRequestType(RequestType requestType) {
    assert(
        requestType == RequestType.image ||
            requestType == RequestType.video ||
            requestType == RequestType.common,
        'Only images and videos can be shown in the picker for now');
  }

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
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [provider] getter of type [DefaultAssetPickerProvider] to specifies picker options.
  /// Getter needed to initialize the provider state after permission check.
  /// This argument is required.
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [pickerConfig] to specifies more optional parameters for the picker.
  Future<List<AssetEntity>?> restorableAssetsPicker(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)?
        onPermissionDenied,

    /// InstaAssetPickerBuilder parameters
    required DefaultAssetPickerProvider Function() provider,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
    InstaAssetPickerConfig pickerConfig = const InstaAssetPickerConfig(),
  }) async {
    PermissionState? ps;
    try {
      ps = await _permissionCheck(null);
    } catch (e) {
      _openErrorPermission(
        context,
        pickerConfig.textDelegate,
        onPermissionDenied,
      );
      return [];
    }

    /// Provider must be initialized after permission check or gallery is empty (#43)
    final restoredProvider = provider();
    _assertRequestType(restoredProvider.requestType);

    builder ??= InstaAssetPickerBuilder(
      initialPermission: ps,
      provider: restoredProvider,
      keepScrollOffset: true,
      onCompleted: onCompleted,
      config: pickerConfig,
      locale: Localizations.maybeLocaleOf(context),
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
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [pickerConfig] to specifies more optional parameters for the picker.
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
  /// - Set [requestType] to specifies which type of asset to show in the picker.
  /// Defaults is [RequestType.common]. Only [RequestType.image], [RequestType.common]
  /// and [RequestType.common] are supported.
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)?
        onPermissionDenied,

    /// InstaAssetPickerBuilder parameters
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
    InstaAssetPickerConfig pickerConfig = const InstaAssetPickerConfig(),

    /// DefaultAssetPickerProvider parameters
    List<AssetEntity>? selectedAssets,
    int maxAssets = defaultMaxAssetsCount,
    int pageSize = defaultAssetsPerPage,
    ThumbnailSize pathThumbnailSize = defaultPathThumbnailSize,
    SortPathDelegate<AssetPathEntity>? sortPathDelegate =
        SortPathDelegate.common,
    bool sortPathsByModifiedDate = false,
    PMFilter? filterOptions,
    Duration initializeDelayDuration = _kInitializeDelayDuration,
    RequestType requestType = RequestType.common,
  }) async {
    _assertRequestType(requestType);

    // must be called before initializing any picker provider to avoid `PlatformException(PERMISSION_REQUESTING)` type exception
    PermissionState? ps;
    try {
      ps = await _permissionCheck(requestType);
    } catch (e) {
      _openErrorPermission(
        context,
        pickerConfig.textDelegate,
        onPermissionDenied,
      );
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
      keepScrollOffset: false,
      onCompleted: onCompleted,
      config: pickerConfig,
      locale: Localizations.maybeLocaleOf(context),
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder,
      permissionRequestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: requestType,
          mediaLocation: false,
        ),
      ),
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
