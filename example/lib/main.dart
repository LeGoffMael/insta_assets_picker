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
      home: const PickerScreen(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  final _instaAssetsPicker = InstaAssetPicker();

  @override
  void dispose() {
    _instaAssetsPicker.dispose();
    super.dispose();
  }

  Future<void> callPicker(BuildContext context) =>
      _instaAssetsPicker.pickAssets(
        context,
        title: 'Select images',
        maxAssets: 10,
        textDelegate: const EnglishAssetPickerTextDelegate(),
        onCompleted: (cropStream) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PickerCropResultScreen(cropStream: cropStream),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Center(
            child: Text(
              'The picker reproduces Instagram picker',
              style: TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => callPicker(context),
            child: const Text(
              'Open the Picker',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class PickerCropResultScreen extends StatelessWidget {
  const PickerCropResultScreen({super.key, required this.cropStream});

  final Stream<InstaAssetsExportDetails> cropStream;

  Widget _buildTitle(String title, int length) {
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
              length.toString(),
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

  Widget _buildCroppedImagesListView(
    BuildContext context,
    InstaAssetsExportDetails? exportDetails,
  ) {
    if (exportDetails == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: exportDetails.croppedFiles.length,
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
                  child: Image.file(exportDetails.croppedFiles[index]),
                ),
              );
            },
          ),
          if (exportDetails.progress < 1.0)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(.5),
                ),
              ),
            ),
          if (exportDetails.progress < 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: exportDetails.progress,
                    semanticsLabel: '${exportDetails.progress * 100}%',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedAssetsListView(List<AssetEntity>? selectedAssets) {
    if (selectedAssets == null) return const SizedBox.shrink();

    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: selectedAssets.length,
        itemBuilder: (BuildContext _, int index) {
          final AssetEntity asset = selectedAssets.elementAt(index);

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            // TODO : add delete action
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image(image: AssetEntityImageProvider(asset)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker result')),
      body: StreamBuilder<InstaAssetsExportDetails>(
          stream: cropStream,
          builder: (context, snapshot) {
            final count = snapshot.data?.selectedAssets.length ?? 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: kThemeChangeDuration,
                  curve: Curves.easeInOut,
                  height: snapshot.data != null ? height / 2 : 40.0,
                  child: Column(
                    children: <Widget>[
                      _buildTitle('Cropped Images', count),
                      _buildCroppedImagesListView(context, snapshot.data),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: kThemeChangeDuration,
                  curve: Curves.easeInOut,
                  height: (snapshot.data?.selectedAssets.isNotEmpty ?? false)
                      ? height / 4
                      : 40.0,
                  child: Column(
                    children: <Widget>[
                      _buildTitle('Selected Assets', count),
                      _buildSelectedAssetsListView(
                        snapshot.data?.selectedAssets,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}
