import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:tektest_2/homepage.dart';

//import 'package:fl_chart/fl_chart.dart';
//import 'package:custom_window_manager/custom_window_manager.dart'
//const List<String> list = <String>[ 'NONE', 'Port-1', 'Port-2'];

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    appWindow.size = const Size(550, 700);
    Size initialSize = appWindow.size;
    appWindow.size = initialSize;
    appWindow.minSize = initialSize;
    appWindow.title = "Bartels Mikro Technik GmbH";
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
