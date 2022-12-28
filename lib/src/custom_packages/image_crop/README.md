# Custom image crop

> **_NOTE:_**  This file come from a [fork](https://github.com/LeGoffMael/image_crop/tree/mergedBranch) of [image_crop](https://pub.dev/packages/image_crop) by [lykhonis](https://github.com/lykhonis).

Contains all the changes needed to use this library in `insta_assets_picker`:

- [#77](https://github.com/lykhonis/image_crop/pull/77): disable initial magnification
- [#95](https://github.com/lykhonis/image_crop/pull/95): new `disableResize` parameter
- [#96](https://github.com/lykhonis/image_crop/pull/96): new `backgroundColor` parameter
- [#97](https://github.com/lykhonis/image_crop/pull/97): new `placeholderWidget` & `onLoading` parameters
- [#98](https://github.com/lykhonis/image_crop/pull/98): new `initialParam` parameter to initialize view programmatically
- [f34bfef](https://github.com/LeGoffMael/image_crop/commit/f34bfef5eaf7aef298c475fd1a1874adaa6bcad3): fix issue on aspect ratio change, no PR made because it might not be the best fix
- [8fb0bc0](https://github.com/LeGoffMael/image_crop/commit/8fb0bc04696f95055be5f3dc32cbb8714b278a9c): fix issue with GIF, no PR for this yet since it is specific to GIF extended image provider

## Edit

If changes are needed, the [fork repository](https://github.com/LeGoffMael/image_crop/tree/mergedBranch) should be updated.

If the original package happen to be updated, the `custom_packages` could be deleted, along with all its imports.