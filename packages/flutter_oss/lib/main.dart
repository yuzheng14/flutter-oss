import 'package:flutter/material.dart';
import 'package:flutter_oss/storage.dart';
import 'package:flutter_oss/transfer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Storage Client',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Widget page;
    switch (selectedIndex) {
      case 0:
        page = StoragePage();
        break;
      case 1:
        page = const TransferPage();
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
