import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta Assets Picker Demo',
      theme: ThemeData(
        // update to change the main theme of app + picker
        primarySwatch: Colors.deepPurple,
      ),
      home: const PickerScren(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class PickerScren extends StatefulWidget {
  const PickerScren({super.key});

  @override
  State<PickerScren> createState() => _PickerScrenState();
}

class _PickerScrenState extends State<PickerScren> {
  final _instaAssetsPicker = InstaAssetPicker();

  List<AssetEntity> entities = <AssetEntity>[];
  List<File> files = <File>[];
  List<InstaAssetsCrop>? cropParameters;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  @override
  void dispose() {
    _instaAssetsPicker.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> callPicker(BuildContext context) async {
    final List<AssetEntity>? result = await _instaAssetsPicker.pickAssets(
      context,
      title: 'Select images',
      maxAssets: 10,
      textDelegate: const EnglishAssetPickerTextDelegate(),
      initialCropParameters: cropParameters,
      onCompleted: (details) async {
        setState(() => files = []);
        final exportDetails = await details;
        cropParameters = exportDetails.cropParamsList;
        if (mounted) {
          _progress.value = 1;
          setState(() => files = exportDetails.croppedFiles);
        }
      },
      onProgress: (p) {
        files.clear();
        _progress.value = p;
      },
    );

    if (result != null) {
      entities = result;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildTitle(String title) {
    return SizedBox(
      height: 20.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurpleAccent,
            ),
            child: Text(
              '${entities.length}',
              style: const TextStyle(
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get croppedImagesWidget {
    return AnimatedContainer(
      duration: kThemeChangeDuration,
      curve: Curves.easeInOut,
      height: files.isNotEmpty ? 300.0 : 40.0,
      child: Column(
        children: <Widget>[
          _buildTitle('Cropped Images'),
          croppedImagesListView,
        ],
      ),
    );
  }

  Widget get croppedImagesListView {
    return ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: (context, progress, child) {
          if (progress == 0) {
            return const SizedBox.shrink();
          } else if (progress <= 1 && files.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    semanticsLabel: '${progress * 100}%',
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              itemBuilder: (BuildContext _, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Image.file(files[index]),
                  ),
                );
              },
            ),
          );
        });
  }

  Widget get selectedAssetsWidget {
    return AnimatedContainer(
      duration: kThemeChangeDuration,
      curve: Curves.easeInOut,
      height: entities.isNotEmpty ? 120.0 : 40.0,
      child: Column(
        children: <Widget>[
          _buildTitle('Selected Assets'),
          selectedAssetsListView,
        ],
      ),
    );
  }

  Widget get selectedAssetsListView {
    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: entities.length,
        itemBuilder: (BuildContext _, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  entities.removeAt(index);
                  files.removeAt(index);
                });
                if (files.isEmpty) _progress.value = 0;
              },
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  _selectedAssetWidget(index),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedAssetWidget(int index) {
    final AssetEntity asset = entities.elementAt(index);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image(image: AssetEntityImageProvider(asset)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('The picker reproduces Instagram picker'),
                  TextButton(
                    onPressed: () => callPicker(context),
                    child: const Text(
                      'Open the Picker',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          croppedImagesWidget,
          selectedAssetsWidget,
        ],
      ),
    );
  }
}
