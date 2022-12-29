import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker_demo/widgets/crop_result_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta Assets Picker Demo',
      // update to change the main theme of app + picker
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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
  final _provider = DefaultAssetPickerProvider(maxAssets: 10);
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
      title: 'Restorable',
      closeOnComplete: true,
      provider: _provider,
      onCompleted: (cropStream) {
        // example withtout StreamBuilder
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: <Widget>[
            const Material(
              color: Colors.deepPurple,
              child: TabBar(
                tabs: [
                  Tab(text: 'Normal picker'),
                  Tab(text: 'Restorable picker'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Center(
                        child: Text(
                          'The picker will push result in a new screen',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      TextButton(
                        onPressed: () => InstaAssetPicker.pickAssets(
                          context,
                          title: 'Select images',
                          maxAssets: 10,
                          onCompleted: (cropStream) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PickerCropResultScreen(
                                    cropStream: cropStream),
                              ),
                            );
                          },
                        ),
                        child: const Text(
                          'Open the Picker',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Center(
                              child: Text(
                                'The picker will restore the picker state.\n'
                                'The preview, selected album and scroll position will be the same as before pop\n'
                                'Using this picker means that you must dispose it manually',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            TextButton(
                              onPressed: callRestorablePicker,
                              child: const Text(
                                'Open the Restorable Picker',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CropResultView(
                        selectedAssets: selectedAssets,
                        croppedFiles: exportDetails?.croppedFiles ?? [],
                        progress: exportDetails?.progress,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickerCropResultScreen extends StatelessWidget {
  const PickerCropResultScreen({super.key, required this.cropStream});

  final Stream<InstaAssetsExportDetails> cropStream;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(title: const Text('Insta picker result')),
      body: StreamBuilder<InstaAssetsExportDetails>(
        stream: cropStream,
        builder: (context, snapshot) => CropResultView(
          selectedAssets: snapshot.data?.selectedAssets ?? [],
          croppedFiles: snapshot.data?.croppedFiles ?? [],
          progress: snapshot.data?.progress,
          heightFiles: height / 2,
          heightAssets: height / 4,
        ),
      ),
    );
  }
}
