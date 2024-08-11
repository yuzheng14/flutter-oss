import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_oss/main.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart';
import 'package:provider/provider.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  late Future<ListObjectsResult> objects;

  Future<ListObjectsResult> listAllObjects(Minio minio) async {
    if (!(await minio.bucketExists('flutter-test'))) {
      await minio.makeBucket('flutter-test');
    }
    return minio.listAllObjectsV2('flutter-test');
  }

  @override
  Widget build(BuildContext context) {
    // final appState = context.watch<MyAppState>();
    // final minio = appState.minio;
    // setState(() {
    //   objects = listAllObjects(minio).catchError((error) {
    //     print('Error: $error');
    //     throw error;
    //   });
    // });

    return FutureBuilder(
      future: objects,
      builder:
          (BuildContext context, AsyncSnapshot<ListObjectsResult> snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final objects = snapshot.data!.objects;

          if (objects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('There is no object, please upload.'),
                  )
                ],
              ),
            );
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('You have ${objects.length} objects:'),
              ),
              ...objects.map((object) => ListTile())
            ],
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
      },
    );
  }
}
