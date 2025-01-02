// utils/permission_handler.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> requestStoragePermission() async {
    // Jika web atau iOS, tidak perlu permission
    if (kIsWeb || Platform.isIOS) {
      return true;
    }

    // Untuk Android, minta permission
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }

    return true; // Default allow untuk platform lain
  }
}
