import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<Directory?> getFolder() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? path = prefs.getString('folder');

  if (path != null) {
    return Directory(path);
  }

  return null;
}

class NoFolderSelected implements Exception {
  String error = 'No folder was selected.';
}

Future<Directory> getFolderOrPrompt() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? path = prefs.getString('folder');

  if (path != null) {
    return Directory(path);
  }

  path = await getDirectoryPath();

  if (path != null) {
    prefs.setString('folder', path);
    return Directory(path);
  }

  throw NoFolderSelected();
}