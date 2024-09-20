# Migration Guide

This document gathered all breaking changes and migrations requirement between major versions.

## 3.0.0

### InstaAssetPickerConfig

The picker configuration parameters must not be provided into a `InstaAssetPickerConfig` class in `pickerConfig`

```diff
InstaAssetPicker.pickAssets(
    context,
-    title: 'Example title',
-    pickerTheme: widget.getPickerTheme(context),
+    pickerConfig: InstaAssetPickerConfig(
+        title: 'Example title',
+        pickerTheme: widget.getPickerTheme(context),
+    ),
)
```

The picker is now showing image and video assets by default. To show only images, you can change the `requestType` param.
```diff
InstaAssetPicker.pickAssets(
    context,
+   requestType: RequestType.image
)
```


The `InstaAssetsExportDetails` was also updated.
The cropped files are now nullable, an all the crop parameters are returned in a new class called `InstaAssetsExportData`.

```diff
+ class InstaAssetsExportData {
+    final File? croppedFile;
+    final InstaAssetsCropData selectedData;
+ }

InstaAssetsExportDetails {
-   final List<File> croppedFiles;
+   final List<InstaAssetsExportData> data;
```


