import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

/// Returns if [File] is a video based on its mime type
bool isVideoFile(File file) =>
    lookupMimeType(file.path)?.startsWith('video') ?? false;

/// Returns [File] name with extension
String getFileNameWithExtension(File file) => path.basename(file.path);

/// Returns [File] extension in `.xxx` format
String getFileExtension(File file) => path.extension(file.path).toLowerCase();
