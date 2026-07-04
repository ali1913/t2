import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/row_entry.dart';
import 'widgets/tracker_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(RowEntryAdapter());
  await Hive.openBox<RowEntry>(kRowsBoxName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController + TabBar so adding a second tab later is just:
    // 1. length: 2
    // 2. add a Tab(text: '...') below
    // 3. add the matching widget in the TabBarView children
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My App'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tracker'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TrackerTab(),
          ],
        ),
      ),
    );
  }
}
