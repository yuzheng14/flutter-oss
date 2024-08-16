import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oss/api.dart';
import 'package:flutter_oss/store/object.dart';

// class StoragePage extends StatefulWidget {
//   const StoragePage({super.key});

//   @override
//   State<StoragePage> createState() => _StoragePageState();
// }

// class _StoragePageState extends State<StoragePage> {
//   late Future<ListObjectsResult> objects;

//   Future<ListObjectsResult> listAllObjects(Minio minio) async {
//     if (!(await minio.bucketExists('flutter-test'))) {
//       await minio.makeBucket('flutter-test');
//     }
//     return minio.listAllObjectsV2('flutter-test');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: objects,
//       builder:
//           (BuildContext context, AsyncSnapshot<ListObjectsResult> snapshot) {
//         if (snapshot.hasError) {
//           print(snapshot.error);
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.error_outline,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 16),
//                   child: Text('Error: ${snapshot.error}'),
//                 ),
//               ],
//             ),
//           );
//         } else if (snapshot.hasData) {
//           final objects = snapshot.data!.objects;

//           if (objects.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.info),
//                   Padding(
//                     padding: EdgeInsets.only(top: 16),
//                     child: Text('There is no object, please upload.'),
//                   )
//                 ],
//               ),
//             );
//           }

//           return ListView(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Text('You have ${objects.length} objects:'),
//               ),
//               ...objects.map((object) => ListTile())
//             ],
//           );
//         } else {
//           return const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 60,
//                   height: 60,
//                   child: CircularProgressIndicator(),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.only(top: 16),
//                   child: Text('Await data...'),
//                 )
//               ],
//             ),
//           );
//         }
//       },
//     );
//   }
// }

class StoragePage extends StatelessWidget {
  final Function uploadFile;

  StoragePage({required this.uploadFile});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          // cascade operator
          ObjectBloc(apiService: ApiService())..add(FetchObjects()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('all objects'),
        ),
        body: BlocBuilder<ObjectBloc, ObjectState>(builder: (context, state) {
          if (state is ObjectLoading) {
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
          } else if (state is ObjectLoaded) {
            return ListView.builder(
              itemCount: state.objects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.objects[index].name),
                  subtitle: Text('Size: ${state.objects[index].size}'),
                );
              },
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Failed to fetch data.'),
                  ),
                ],
              ),
            );
          }
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => uploadFile(),
          tooltip: 'Upload File',
          child: Icon(Icons.file_upload),
        ),
      ),
    );
  }
}
