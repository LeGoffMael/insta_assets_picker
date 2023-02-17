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