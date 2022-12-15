import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class CropViewer extends StatelessWidget {
  const CropViewer({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO : crop view
    return SizedBox.square(
      dimension: MediaQuery.of(context).size.width,
      child: const Text('Crop Viewer'),
    );
  }
}
