import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/pages/university_list_page.dart';
import 'package:flutter_clean_architecture/features/university/presentation/riverpod/pages/university_list_riverpod_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'core/di/injections.dart';

void main() async {
  // Local cache must be ready before injections are registered.
  await Hive.initFlutter();

  // Init Injections
  await initInjections();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clean Architecture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DemoHomePage(),
    );
  }
}

/// Switches between the BLoC and Riverpod demos.
/// Both consume the same domain usecases — only the
/// presentation-layer state management differs.
class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _index = 0;

  static const _pages = [UniversityListPage(), UniversityListRiverpodPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'BLoC'),
          BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'Riverpod'),
        ],
      ),
    );
  }
}
