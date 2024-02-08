<p align="center">
  <h1 align="center">Instagram Assets Picker</h1>
</p>

<p align="center">
  <a href="https://pub.dev/packages/insta_assets_picker">
    <img src="https://img.shields.io/pub/v/insta_assets_picker.svg" alt="Pub">
  </a>
  <a href="https://pub.dev/packages/flutter_lints">
    <img src="https://img.shields.io/badge/style-flutter__lints-40c4ff.svg" alt="Flutter lints"/>
  </a>
  <a href="https://gitmoji.dev">
		<img src="https://img.shields.io/badge/gitmoji-%20😜%20😍-FFDD67.svg" alt="Gitmoji">
	</a>
</p>


An image picker based on Instagram picker UI. It is using the powerful [flutter_wechat_assets_picker](https://pub.dev/packages/wechat_assets_picker)
package to handle the picker and a custom version of [image_crop](https://pub.dev/packages/image_crop) for crop.

## 🚀 Features

- ✅ Instagram layout
    - Scroll behaviors, animation
    - Preview, select, unselect action logic
- ✅ Theme and language customization
- ✅ Multiple images pick (with maximum limit)
- ✅ Single image pick mode
- ✅ Restore state of picker after pop
- ✅ Select aspect ratios to crop all images with (default to 1:1 & 4:5)
- ✅ Crop all images at once and receive a stream with a progress value
- ✅ Prepend or append a custom item in the assets list
- ✅ Add custom action buttons
- ❌ Videos are not supported

## 📸 Screenshots

| Layout and scroll                   | Crop                                     |
| ----------------------------------- | ---------------------------------------- |
| ![](https://raw.githubusercontent.com/LeGoffMael/insta_assets_picker/main/example/screenshots/scroll.webp) | ![](https://raw.githubusercontent.com/LeGoffMael/insta_assets_picker/main/example/screenshots/crop-export.webp) |

## 📖 Installation

Add this package to the `pubspec.yaml`

```yaml
insta_assets_picker: ^2.3.0-dev.2
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
      // the "crop" button will display the selected ratio value (i.e.: 1:1)
      // instead of unfold arrows.
    ]),
    onCompleted: (_) {},
);
```

### Camera

Many people requested the ability to take picture from the picker.
The main aspect of this package is selection and uniform crop selection.
Consequently, camera-related operations have no place in this package. 
However, since version `2.0.0`, it is now possible to trigger this action using either `specialItemBuilder` and/or `actionsBuilder`.

The ability to take a photo from the camera must be handled on your side, but the picker is now able to refresh the list and select the new photo.
New [examples](https://github.com/LeGoffMael/insta_assets_picker/tree/main/example/lib/pages/camera) have been written to show how to manage this process with the [camera](https://pub.dev/packages/camera) or [wechat_camera_picker](https://pub.dev/packages/wechat_camera_picker) package.

## ✨ Credit

This package is based on [flutter_wechat_assets_picker](https://pub.dev/packages/wechat_assets_picker) by [AlexV525](https://github.com/AlexV525) and [image_crop](https://pub.dev/packages/image_crop) by [lykhonis](https://github.com/lykhonis).