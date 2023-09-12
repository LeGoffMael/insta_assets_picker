import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

mixin InstaPickerInterface on Widget {
  PickerDescription get description;

  ThemeData getPickerTheme(BuildContext context) {
    return InstaAssetPicker.themeData(Theme.of(context).colorScheme.primary)
        .copyWith(
      appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  AppBar get _appBar =>
      AppBar(title: Text('${description.icon} ${description.label}'));

  Column pickerColumn({
    String? text,
    required VoidCallback onPressed,
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              text ??
                  'The ${description.label} will push result in a new screen',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: FittedBox(
              child: Text(
                'Open the ${description.label}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      );

  Scaffold buildLayout(
    BuildContext context, {
    required VoidCallback onPressed,
  }) =>
      Scaffold(
        appBar: _appBar,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: pickerColumn(onPressed: onPressed),
        ),
      );

  Scaffold buildCustomLayout(
    BuildContext context, {
    required Widget child,
  }) =>
      Scaffold(
        appBar: _appBar,
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

class PickerDescription {
  final String icon;
  final String label;
  final String? description;

  const PickerDescription({
    required this.icon,
    required this.label,
    this.description,
  });
}
