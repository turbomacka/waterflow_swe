import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/station_provider.dart';
import 'screens/station_selector_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StationProvider(),
      child: const SmhiHydroApp(),
    ),
  );
}

class SmhiHydroApp extends StatelessWidget {
  const SmhiHydroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMHI Hydro',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const StationSelectorScreen(),
    );
  }
}
