# Instagram Assets Picker

[![Pub](https://img.shields.io/pub/v/insta_assets_picker.svg)](https://pub.dev/packages/insta_assets_picker)

An image picker based on Instagram picker UI. It is using the powerful [flutter_wechat_assets_picker](https://pub.dev/packages/wechat_assets_picker)
package to handle the picker and a custom version of [image_crop](https://pub.dev/packages/image_crop) for crop.

## 🚀 Features

- ✅ Instagram layout
    - Scroll behaviors, animation
    - Preview, select, unselect action logic
- ✅ Theme and language customization
- ✅ Multiple images pick (with maximum limit)
- ✅ Restore state of picker after pop
- ✅ Select aspect ratios to crop all images with (default to 1:1 & 4:5)
- ✅ Crop all images at once and receive a stream with a progress value
- ✅ Prepend or append a custom item in the assets list
- ❌ Videos are not supported

## 📸 Screenshots

| Layout and scroll                   | Crop                                     |
| ----------------------------------- | ---------------------------------------- |
| ![](https://raw.githubusercontent.com/LeGoffMael/insta_assets_picker/main/example/screenshots/scroll.webp) | ![](https://raw.githubusercontent.com/LeGoffMael/insta_assets_picker/main/example/screenshots/crop-export.webp) |

## 📖 Installation

Add this package to the `pubspec.yaml`

```yaml
insta_assets_picker: ^1.5.0
```

### ‼️ DO NOT SKIP THIS PART

Since this package is a custom delegate of `flutter_wechat_assets_picker` you **MUST** follow this package setup recommendation : [installation guide](https://pub.dev/packages/wechat_assets_picker#preparing-for-use-).

## 👀 Usage

For more details check out the [example](https://github.com/LeGoffMael/insta_assets_picker/blob/main/example/lib/main.dart).

```dart
Future<List<AssetEntity>?> callPicker() => InstaAssetPicker.pickAssets(
    context,
    title: 'Select images',
    maxAssets: 10,
    onCompleted: (Stream<InstaAssetsExportDetails> stream) {
        // TODO : handle crop stream result
        // i.e : display it using a StreamBuilder
        // - in the same page (closeOnComplete=true)
        // - send it to another page (closeOnComplete=false)
        // or use `stream.listen` to handle the data manually in your state manager
        // - ...
    },
);
```

Fields in `InstaAssetsExportDetails`:

| Name           | Type                | Description                                             |
| -------------- | ------------------- | ------------------------------------------------------- |
| croppedFiles   | `List<File>`        | List of all cropped files                               |
| selectedAssets | `List<AssetEntity>` | Selected assets without crop                            |
| aspectRatio    | `double`            | Selected aspect ratio (1 or 4/5)                        |
| progress       | `double`            | Progress indicator of the exportation (between 0 and 1) |


### Picker configuration

Please follow `flutter_wechat_assets_picker` documentation : [AssetPickerConfig](https://pub.dev/packages/wechat_assets_picker#usage-)

### Localizations

Please follow `flutter_wechat_assets_picker` documentation : [Localizations](https://pub.dev/packages/wechat_assets_picker#localizations)

### Theme customization

Most of the components of the picker can be customized using theme.

```dart
// set picker theme based on app theme primary color
final theme = InstaAssetPicker.themeData(Theme.of(context).primaryColor);
InstaAssetPicker.pickAssets(
    context,
    pickerTheme: theme.copyWith(
      canvasColor: Colors.black, // body background color
      splashColor: Color.grey, // ontap splash color
      colorScheme: theme.colorScheme.copyWith(
        background: Colors.black87, // albums list background color
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.black, // app bar background color
        titleTextStyle: Theme.of(context)
            .appBarTheme
            .titleTextStyle
            ?.copyWith(color: Colors.white), // change app bar title text style to be like app theme
      ),
      // edit `confirm` button style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          disabledForegroundColor: Colors.red,
        ),
      ),
    ),
    onCompleted: (_) {},
);
```

### Crop customization

You can set the list of crop aspect ratios available.
You can also set the preferred size, for the cropped images.

```dart
InstaAssetPicker.pickAssets(
    context,
    cropDelegate: InstaAssetCropDelegate(
      // allows you to set the preferred size used when cropping the image.
      // the final size will depends on the scale used when cropping.
      preferredSize: 1080,
      cropRatios: [
      // - allow you to set the list of aspect ratios selectable,
      // the default values are [1/1, 4/5] like instagram.
      // - if you want to disable cropping, you can set only one parameter,
      // in this case, the "crop" button will not be displayed (#10).
      // - if the value of cropRatios is different than the default value,
      // the "crop" button will display the selected crop value (i.e.: 1.:1)
      // instead of unfold arrows.
    ]),
    onCompleted: (_) {},
);
```

## ✨ Credit

This package is based on [flutter_wechat_assets_picker](https://pub.dev/packages/wechat_assets_picker) by [AlexV525](https://github.com/AlexV525) and [image_crop](https://pub.dev/packages/image_crop) by [lykhonis](https://github.com/lykhonis).