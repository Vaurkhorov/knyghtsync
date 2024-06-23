import 'dart:io';

import 'package:flutter/material.dart';
import 'package:knyghtsync/file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'knyght sync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellowAccent, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

enum FolderStatus {
  applicationStarted,
  noFolderInPrefs,
  folderRetrieved,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Directory? folder;
  FolderStatus status = FolderStatus.applicationStarted;

  void _setFolderAndStatus(Directory folder) {
    setState(() {
      folder = folder;
      status = FolderStatus.folderRetrieved;
    });
  }

  @override
  Widget build(BuildContext context) {
    getFolder().then((f) {
      setState(() {
        folder = f;
        status = FolderStatus.folderRetrieved;

        if (f == null) {
          status = FolderStatus.noFolderInPrefs;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: FolderTiles(
            folder: folder,
            status: status,
            setFolderCallback: _setFolderAndStatus
        ),
      ),
    );
  }
}

class FolderTiles extends StatefulWidget {
  final Directory? folder;
  final FolderStatus status;
  final void Function(Directory) setFolderCallback;

  const FolderTiles({super.key, required this.folder, required this.status, required this.setFolderCallback});

  @override
  FolderTilesState createState() => FolderTilesState();
}

class FolderTilesState extends State<FolderTiles> {
  @override
  Widget build(BuildContext context) {
    if (widget.status == FolderStatus.applicationStarted) {
      return const CircularProgressIndicator();
    } else if (widget.status == FolderStatus.noFolderInPrefs) {
      return InitialiseButton(setFolderCallback: widget.setFolderCallback);
    } else {
      final String path = widget.folder.toString();
      return Text('Grid view has not been implemented yet. Your chosen folder is $path');
      // return GridView.builder(gridDelegate: gridDelegate, itemBuilder: itemBuilder);
    }
  }
}

class InitialiseButton extends StatelessWidget {
  final void Function(Directory) setFolderCallback;
  const InitialiseButton({super.key, required this.setFolderCallback});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("No folder has been selected yet to synchronise. Choose one now?"),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: () {
            getFolderOrPrompt().then((folder) {
              setFolderCallback(folder);
            });
          },
        ),
      ],
    );
  }
}