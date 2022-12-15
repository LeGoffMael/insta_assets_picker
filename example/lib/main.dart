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
        primarySwatch: Colors.blue,
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
  final int maxAssets = 10;
  List<AssetEntity> entities = <AssetEntity>[];

  Future<void> callPicker(BuildContext context) async {
    final List<AssetEntity>? result = await InstaAssetPicker.pickAssets(
      context,
      selectedAssets: entities,
      title: 'Select images',
      maxAssets: maxAssets,
      textDelegate: const EnglishAssetPickerTextDelegate(),
    );

    if (result != null) {
      entities = result;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget get selectedAssetsWidget {
    return AnimatedContainer(
      duration: kThemeChangeDuration,
      curve: Curves.easeInOut,
      height: entities.isNotEmpty ? 200.0 : 40.0,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Selected Assets'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  padding: const EdgeInsets.all(4.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueGrey,
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
          ),
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
            child: Stack(
              children: <Widget>[
                _selectedAssetWidget(index),
                AnimatedPositionedDirectional(
                  duration: kThemeAnimationDuration,
                  top: 5.0,
                  end: 5.0,
                  child: GestureDetector(
                    onTap: () => setState(() => entities.removeAt(index)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Icon(Icons.close, size: 18.0),
                    ),
                  ),
                ),
              ],
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
          selectedAssetsWidget,
        ],
      ),
    );
  }
}
