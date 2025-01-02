import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:buana_vpad/database/db_config.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database berdasarkan platform
  await initializeDatabase();

  // Inisialisasi database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Buana VPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
