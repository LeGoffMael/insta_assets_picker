import 'package:flutter/material.dart';
import 'package:insta_assets_picker_demo/widgets/insta_picker_interface.dart';

class SinglePicker extends StatelessWidget with InstaPickerInterface {
  const SinglePicker({super.key});

  @override
  PickerDescription get description => const PickerDescription(
        icon: '☝️',
        label: 'Single Mode Picker',
        description: 'Picker to select a single image. '
            'Selecting a new image will replace the old one.',
      );

  @override
  Widget build(BuildContext context) => buildLayout(
        context,
        onPressed: () => pickAssets(context, maxAssets: 1),
      );
}

const _kMultiplePickerMax = 4;

class MultiplePicker extends StatelessWidget with InstaPickerInterface {
  const MultiplePicker({super.key});

  @override
  PickerDescription get description => const PickerDescription(
        icon: '🖼️',
        label: 'Multiple Mode Picker',
        description:
            'Picker for selecting multiple images (max $_kMultiplePickerMax).',
      );

  @override
  Widget build(BuildContext context) => buildLayout(
        context,
        onPressed: () => pickAssets(context, maxAssets: _kMultiplePickerMax),
      );
}
