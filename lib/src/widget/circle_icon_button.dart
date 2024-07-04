import 'package:flutter/material.dart';

class InstaPickerCircleIconButton extends StatelessWidget {
  const InstaPickerCircleIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.theme,
    required this.size,
  });

  const InstaPickerCircleIconButton.unselectAll({
    super.key,
    required this.onTap,
    required this.theme,
    required this.size,
  }) : icon = const Icon(Icons.layers_clear_sharp);

  final VoidCallback onTap;
  final Widget icon;
  final double size;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(side: BorderSide.none),
          padding: theme?.buttonTheme.padding,
          backgroundColor: theme?.buttonTheme.colorScheme?.surface,
          foregroundColor: theme?.iconTheme.color,
        ),
        child: FittedBox(child: icon),
      ),
    );
  }
}
