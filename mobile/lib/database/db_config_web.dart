import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

Future<void> initializeDatabase() async {
  // Configure database factory for web
  databaseFactory = databaseFactoryFfiWeb;
  
  // Optional: Add configuration if needed
  await databaseFactoryFfiWeb.setDatabasesPath('/sqlite');
}