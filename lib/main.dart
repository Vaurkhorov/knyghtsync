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
      home: const MyHomePage(title: 'knyght sync'),
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

  void _setFolderAndStatus(Directory newFolder) {
    setState(() {
      folder = newFolder;
      status = FolderStatus.folderRetrieved;
    });
  }

  @override
  void initState() {
    super.initState();

    getFolder().then((f) {
      setState(() {
        folder = f;

        if (f == null) {
          status = FolderStatus.noFolderInPrefs;
        } else {
          status = FolderStatus.folderRetrieved;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (status == FolderStatus.applicationStarted) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (status == FolderStatus.noFolderInPrefs) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: InitialiseFolder(
              updateFolderCallback: _setFolderAndStatus
          ),
        ),
      );
    }

    // status == FolderStatus.folderRetrieved
    if (folder != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: FolderView(
            root: folder!,
        ),
      );
    } else {
      // We shouldn't be here.
      return ErrorWidget(
          'I should have a folder selected, but I can only find \'null\'.'
      );
    }
  }
}


class InitialiseFolder extends StatelessWidget {
  final void Function(Directory) updateFolderCallback;
  const InitialiseFolder({super.key, required this.updateFolderCallback});


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Select the folder that you want synchronised.'),
        ElevatedButton(
          onPressed: () {
            getFolderOrPrompt().then((selectedFolder) {
              if (selectedFolder != null) {
                updateFolderCallback(selectedFolder);
              }
            });
          },
          child: const Row(
            children: [
              Icon(Icons.drive_folder_upload),
              Text('Select Folder'),
            ],
          ),
        ),
      ],
    );
  }
}

class FolderView extends StatefulWidget {
  final Directory root;
  const FolderView({super.key, required this.root});

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  // late Directory currentDirectory;
  // late Future<List<FileSystemEntity>> directoryList;
  late DirectoryInfo info;

  @override
  initState() {
    super.initState();

    info = DirectoryInfo(widget.root);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: info.directoryList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.connectionState == ConnectionState.done) {
          List<ElevatedButton> displayList = [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  info.returnToRoot();
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.home),
                  Text('Home'),
                ],
              ),
            )
          ];
          if (snapshot.data != null) {
            if (snapshot.data!.isEmpty) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        info.returnToRoot();
                      });
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.home),
                        Text('Home'),
                      ],
                    ),
                  ),
                  Text(
                    'This directory is empty;',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            }
            for (var entity in snapshot.data!) {
              if (entity is File) {
                displayList.add(ElevatedButton(
                  onPressed: null,
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file),
                      Text(entity.path.split('/').last),
                    ],
                  ),
                ));
              } else if (entity is Directory) {
                displayList.add(ElevatedButton(
                  onPressed: () {
                    setState(() {
                      info.updateCurrentDirectory(entity);
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open),
                      Text(entity.path.split('/').last),
                    ],
                  ),
                ));
              } else {
                displayList.add(ElevatedButton(
                  onPressed: null,
                  child: Row(
                    children: [
                      const Icon(Icons.link),
                      Text(entity.path.split('/').last),
                    ],
                  ),
                ));
              }

              return ButtonBar(
                alignment: MainAxisAlignment.start,
                children: displayList,
              );
            }
          } else {
            return ErrorWidget(snapshot.error!);
          }
        }

        // snapshot.hasError must be true by now.
        return ErrorWidget(snapshot.error!);
      },
    );
  }
}

class DirectoryInfo {
  final Directory root;
  Directory currentDirectory;
  Future<List<FileSystemEntity>> directoryList;

  DirectoryInfo(Directory givenRoot)
    : root = givenRoot,
      currentDirectory = givenRoot,
      directoryList = givenRoot.list().toList();
  // Who even designed this syntax? Why is THIS how you make a constructor?
  // The IDE doesn't know how to format this.
  // It's supposed to be an initializer list.
  // (https://dart.dev/language/constructors#use-an-initializer-list)
  // But how do you figure it out the first time when your IDE is yelling at you
  // to initialise you variables? ＼（〇_ｏ）／
  // And the syntax to have both an initializer list and a function body too?
  // I'll just not do that, ty.

  void updateCurrentDirectory(Directory dir) {
    currentDirectory = dir;
    directoryList = dir.list().toList();
  }

  void returnToRoot() {
    updateCurrentDirectory(root);
  }
}