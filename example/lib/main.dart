import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:insta_assets_picker_demo/helpers.dart';
import 'package:insta_assets_picker_demo/pages/basic_picker.dart';
import 'package:insta_assets_picker_demo/pages/camera/camera_picker.dart';
import 'package:insta_assets_picker_demo/pages/camera/wechat_camera_picker.dart';
import 'package:insta_assets_picker_demo/pages/restorable_picker.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta Assets Picker Demo',
      // update to change the main theme of app + picker
      theme: ThemeData(
        useMaterial3: true,
        // primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          enableFeedback: true,
          contentPadding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          titleTextStyle: TextStyle(fontWeight: FontWeight.w600),
          minLeadingWidth: 8,
          leadingAndTrailingTextStyle: TextStyle(fontSize: 24),
        ),
      ),
      home: const PickersScreen(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class PickersScreen extends StatelessWidget {
  const PickersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<InstaPickerInterface> pickers = [
      const BasicPicker(),
      const RestorablePicker(),
      CameraPicker(camera: _cameras.first),
      const WeChatCameraPicker(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Insta pickers')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int index) {
          final PickerDescription description = pickers[index].description;

          return Card(
            child: ListTile(
              leading: Text(description.icon),
              title: Text(description.label),
              subtitle: description.description != null
                  ? Text(description.description!)
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => pickers[index]),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: pickers.length,
      ),
    );
  }
}
