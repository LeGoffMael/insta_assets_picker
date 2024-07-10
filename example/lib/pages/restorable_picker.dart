import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';
import 'package:insta_assets_picker_demo/widgets/insta_picker_interface.dart';

class RestorablePicker extends StatefulWidget with InstaPickerInterface {
  const RestorablePicker({super.key});

  @override
  PickerDescription get description => const PickerDescription(
        icon: '♻️',
        label: 'Restorable Picker',
        description: 'Picker that can be close and reopen to the same state.',
      );

  @override
  State<RestorablePicker> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<RestorablePicker> {
  final _instaAssetsPicker = InstaAssetPicker();
  late final _provider = DefaultAssetPickerProvider(
    maxAssets: 10,
    requestType: RequestType.common,
  );
  late final ThemeData _pickerTheme = widget.getPickerTheme(context);

  List<AssetEntity> selectedAssets = <AssetEntity>[];
  InstaAssetsExportDetails? exportDetails;

  @override
  void dispose() {
    _provider.dispose();
    _instaAssetsPicker.dispose();
    super.dispose();
  }

  Future<void> callRestorablePicker() async {
    final List<AssetEntity>? result =
        await _instaAssetsPicker.restorableAssetsPicker(
      context,
      pickerConfig: InstaAssetPickerConfig(
        title: widget.description.fullLabel,
        closeOnComplete: true,
        pickerTheme: _pickerTheme,
      ),
      provider: () => _provider,
      onCompleted: (cropStream) {
        // example without StreamBuilder
        cropStream.listen((event) {
          if (mounted) {
            setState(() {
              exportDetails = event;
            });
          }
        });
      },
    );

    if (result != null) {
      selectedAssets = result;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.buildCustomLayout(
        context,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: widget.pickerColumn(
                onPressed: callRestorablePicker,
                text: 'The picker will restore the picker state.\n'
                    'The preview, selected album and scroll position will be the same as before pop\n'
                    'Using this picker means that you must dispose it manually',
              ),
            ),
            CropResultView(result: exportDetails)
          ],
        ),
      );
}
