import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.theme,
  });

  final VoidCallback onTap;
  final Widget icon;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size.fromRadius(14),
        shape: CircleBorder(
          side: theme?.iconTheme.color != null
              ? BorderSide(
                  color: theme!.iconTheme.color!.withOpacity(0.5),
                  width: 0.1,
                )
              : BorderSide.none,
        ),
        padding: const EdgeInsets.all(6),
        backgroundColor: theme?.buttonTheme.colorScheme?.background,
        foregroundColor: theme?.iconTheme.color,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: icon,
    );
  }
}
