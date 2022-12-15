// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CropViewer extends StatefulWidget {
  const CropViewer({super.key, required this.provider, this.theme});

  final DefaultAssetPickerProvider provider;

  final ThemeData? theme;

  @override
  State<CropViewer> createState() => _CropViewerState();
}

class _CropViewerState extends State<CropViewer> {
  final _cropKey = GlobalKey<CropState>();
  bool _isSquare = true;

  double get aspectRatio => _isSquare ? 1 : 4 / 5;

  @override
  Widget build(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(builder:
        (BuildContext context, DefaultAssetPickerProvider provider, __) {
      final List<AssetEntity> current = provider.currentAssets
          .where((AssetEntity e) => e.type == AssetType.image)
          .toList();
      final List<AssetEntity> selected = provider.selectedAssets;
      final int effectiveIndex =
          selected.isEmpty ? 0 : current.indexOf(selected.last);

      print('preview = ${provider.previewAsset}');

      if (provider.previewAsset == null) {
        // TODO : crop view
        return SizedBox.square(
          dimension: MediaQuery.of(context).size.width,
          child: Text('Crop Viewer (${selected.length})'),
        );
      }

      return SizedBox.square(
        dimension: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Positioned.fill(
              child: Crop(
                key: _cropKey,
                image: AssetEntityImageProvider(
                  provider.previewAsset!,
                  isOriginal: true,
                ),
                maximumScale: 10,
                aspectRatio: aspectRatio,
                disableResize: true,
                backgroundColor: widget.theme!.cardColor,
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () => setState(() => _isSquare = !_isSquare),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: widget.theme!.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(_isSquare ? Icons.unfold_more : Icons.unfold_less),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
