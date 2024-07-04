## 2.3.1

- bump `wechat_assets_picker` to 9.1.0
- fixes the deprecated `ColorScheme.background` warnings
- fixes empty gallery on restorable picker first open [#45](https://github.com/LeGoffMael/insta_assets_picker/pull/45)

## 2.3.0

- bump `wechat_assets_picker` to 9.0.0
- request only images permission

### Breaking changes

- Migrate to Flutter 3.16, and drop supports for previous Flutter versions.

## 2.2.1

- exposes `limitedPermissionOverlayPredicate` parameter [#35](https://github.com/LeGoffMael/insta_assets_picker/pull/35)

## 2.2.0

- bump `wechat_assets_picker` to 8.8.0
- fix completed progress status being fires twice [#32](https://github.com/LeGoffMael/insta_assets_picker/pull/32)

## 2.1.0

- single pick mode is now handled properly (selecting a new image replace the old one).
- fix an issue on restorable picker where the crop ratio was not saved properly.
- fix an issue where the picker was not popped after complete.

## 2.0.0

- new `actionsBuilder` parameter
- new examples to show how to take a picture from the picker

### Breaking changes

- Some UI components were updated to look more like instagram

## 1.6.0

### Breaking changes

- Migrate to Flutter 3.13, and drop supports for previous Flutter versions.

## 1.5.2

- bump `wechat_assets_picker` to 8.6.x [#18](https://github.com/LeGoffMael/insta_assets_picker/pull/18)

## 1.5.1

- set `textButtonTheme` in the pickerTheme to customize the confirm button appareance

## 1.5.0

- remove `isSquareDefaultCrop` parameter
- add the possibiliy the list aspect ratios selectable, the first element will be the default value

```dart
InstaAssetPicker.pickAssets(
  context,
  title: 'Select images',
  cropDelegate: InstaAssetCropDelegate(cropRatios: [4 / 5, 1 / 1]),
  onCompleted: (cropStream) {},
),
```

## 1.4.0

- add `specialItemBuilder` and `specialItemPosition` to picker

### Breaking changes

- Migrate to Flutter 3.10, drop supports for previous Flutter versions.

## 1.3.0

### Breaking changes

- Migrate to Flutter 3.7, drop supports for previous Flutter versions.

## 1.2.2

- Internal migration from [image_crop](https://pub.dev/packages/image_crop) package to insta_assets_crop
  - Fix cropped image size too small on android [image_crop/#75](https://github.com/lykhonis/image_crop/pull/75)
- New `cropDelegate` parameter to specify crop options
  - Increased default cropped preferred size from 1024px to 1080px (like instagram)

### Breaking changes

- Renamed `InstaAssetsCrop` into `InstaAssetsCropData`.
- Moved `isSquareDefaultCrop` into `cropDelegate`.

## 1.2.1

- Fix `PlatformException(PERMISSION_REQUESTING)` which causes loading error on first open on android

## 1.2.0

- Check permission before opening picker and new `onPermissionDenied` argument [#6](https://github.com/LeGoffMael/insta_assets_picker/pull/6)
- Expose `themeData` in InstaAssetPicker
- Fix crop view not expanding on android when there is few assets

## 1.1.1

- Fix warnings with Flutter 3.7
- Improved documentation

## 1.1.0

- New `isSquareDefaultCrop` argument, the crop view is now initialized in 4:5 by default like instagram
- Fix error in log on image crop iOS
- Fix warnings with Flutter 3.7
- Improved documentation

## 1.0.1+2

- Change screenshots paths in readme

## 1.0.1+1

- Change screenshots images in readme

## 1.0.1

- Improve theme use and documentation [#2](https://github.com/LeGoffMael/insta_assets_picker/pull/2)

## 1.0.0

- Initial release.
- Layout similar to Instagram
- Scroll animations
- Supports multi images picker, crop and aspect ratio (1 & 4/5)