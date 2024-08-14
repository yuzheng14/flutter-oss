import 'dart:convert';

import 'model/list_entry.dart';
import 'package:http/http.dart' as http;

// Reference: https://docs.flutter.dev/cookbook/networking/fetch-data
// generated by chatGPT4

class ApiService {
  Future<List<ListEntry>> fetchObjects() async {
    var response = await http.get(Uri.parse('http://localhost:8000/object'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => ListEntry.fromJson(item))
          .where((item) =>
              !item.isDeleteMarker) // Filtering out DeleteMarker objects
          .toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> uploadFile() async {
    // TODO to be implemented
  }
}
