import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_oss/model/list_entry.dart';

class StoragePage extends StatefulWidget {
  final Future<void> Function() uploadFile;

  StoragePage({required this.uploadFile});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  Future<List<ListEntry>> objects = Future.value([]);

  Future<void> fetchObjects() async {
    var response = await http.get(Uri.parse('http://localhost:8000/object'));
    if (response.statusCode == 200) {
      setState(() {
        objects = Future.value(
            (jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>)
                .map((item) => ListEntry.fromJson(item))
                .where((item) => !item.isDeleteMarker)
                .toList());
      });
    } else {
      setState(() {
        objects = Future.error(
            Exception('Failed to load data: ${response.statusCode}'));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchObjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('all objects'),
      ),
      body: FutureBuilder(
          future: objects,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var data = snapshot.data!;
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(data[index].name),
                    subtitle: Text('Size: ${data[index].size}'),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Failed to fetch data: ${snapshot.error}'),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Await data...'),
                    )
                  ],
                ),
              );
            }
          }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await widget.uploadFile();
              fetchObjects();
            },
            tooltip: 'Upload File',
            child: Icon(Icons.file_upload),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: fetchObjects,
            tooltip: 'Reload Data',
            child: Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
