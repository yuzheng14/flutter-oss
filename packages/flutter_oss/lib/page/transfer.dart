import 'package:flutter/material.dart';
import 'package:flutter_oss/model/transfer_task.dart';

class TransferPage extends StatelessWidget {
  final List<TransferTask> tasks;
  final Function uploadFile;

  const TransferPage(
      {super.key, required this.tasks, required this.uploadFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('transfer files')),
      body: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return ListTile(
              title: Row(
                children: [
                  Text(task.name),
                  const Spacer(),
                  Text('${(task.progress * 100).toStringAsFixed(2)}%'),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.type,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              subtitle: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => uploadFile(),
        tooltip: 'Upload File',
        child: Icon(Icons.file_upload),
      ),
    );
  }
}
