import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const NoteiruApp());
}

class NoteiruApp extends StatelessWidget {
  const NoteiruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noteiru',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD85A30), // your burnt coral accent
        scaffoldBackgroundColor: const Color(0xFF15140F), // warm near-black
        fontFamily: 'PTSerif',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
