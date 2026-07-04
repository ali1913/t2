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
      // Force RTL layout app-wide. If you later add Arabic strings/locale
      // support via flutter_localizations, this can be replaced by setting
      // `locale: const Locale('ar')` + supportedLocales instead.
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0; // 0 = Home, 1 = Settings

  static const _pages = [
    TrackerTab(),
    _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _pages[_tabIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        // First item renders at the RTL "start" (right side), matching
        // Home being on the right / Settings on the left.
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('تذكرة', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue),
            onPressed: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings — coming soon'));
  }
}