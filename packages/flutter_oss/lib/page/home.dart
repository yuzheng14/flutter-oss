import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss/model/transfer_task.dart';
import 'package:flutter_oss/page/storage.dart';
import 'package:flutter_oss/page/transfer.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedIndex = 0;
  List<TransferTask> tasks = [];

  Future<void> uploadFile() async {
    var result = await FilePicker.platform.pickFiles();

    if (result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('no file selected')));
      return;
    }

    var request = await http.MultipartRequest('PUT',
        Uri.parse('http://localhost:8000/object/${result.files.single.name}'))
      ..files.add(
          await http.MultipartFile.fromPath('file', result.files.single.path!));

    var stream = await request.send().catchError((err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('upload failed: $err'),
        backgroundColor: Colors.red,
      ));
    });

    var task = TransferTask(
        id: Uuid().v4(),
        name: result.files.single.name,
        type: 'upload',
        progress: 0);

    setState(() {
      tasks.add(task);
    });

    stream.stream.listen((value) {
      setState(() {
        task.progress += value.length / result.files.single.size;
      });
    }).onDone(() {
      task.progress = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    switch (selectedIndex) {
      case 0:
        page = StoragePage(
          uploadFile: uploadFile,
        );
        break;
      case 1:
        page = TransferPage(
          tasks: tasks,
          uploadFile: uploadFile,
        );
        break;
      default:
        throw UnimplementedError('no widget for index $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.storage), label: Text('Storage')),
                  NavigationRailDestination(
                      icon: Icon(Icons.cloud_sync), label: Text('Transfer')),
                ],
                selectedIndex: selectedIndex,
                extended: constraints.maxWidth >= 600,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            )
          ],
        ),
      );
    });
  }
}
