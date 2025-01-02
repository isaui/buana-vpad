// db_helper.dart
import 'package:buana_vpad/enums/button_shape.dart';
import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/dpad_layout.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'controller_layouts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Controller Layout table
    await db.execute('''
      CREATE TABLE controller_layouts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        is_editable INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Button Layout table
    await db.execute('''
      CREATE TABLE button_layouts (
        id TEXT PRIMARY KEY,
        controller_id TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        shape TEXT NOT NULL,
        label TEXT NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        angle REAL NOT NULL,
        sensitivity REAL NOT NULL,
        deadzone REAL NOT NULL,
        is_analog INTEGER NOT NULL,
        corner_radius REAL NOT NULL,
        haptic_feedback INTEGER NOT NULL,
        FOREIGN KEY (controller_id) REFERENCES controller_layouts (id)
      )
    ''');

    // Joystick Layout table
    await db.execute('''
      CREATE TABLE joystick_layouts (
        id TEXT NOT NULL,
        controller_id TEXT NOT NULL,
        position TEXT NOT NULL, -- 'left' or 'right'
        x REAL NOT NULL,
        y REAL NOT NULL,
        outer_size REAL NOT NULL,
        inner_size REAL NOT NULL,
        deadzone REAL NOT NULL,
        max_distance REAL NOT NULL,
        is_draggable INTEGER NOT NULL,
        is_fixed INTEGER NOT NULL,
        haptic_enabled INTEGER NOT NULL,
        PRIMARY KEY (controller_id, position),
        FOREIGN KEY (controller_id) REFERENCES controller_layouts (id)
      )
    ''');

    // DPad Layout table
    await db.execute('''
      CREATE TABLE dpad_layouts (
        id TEXT NOT NULL,
        controller_id TEXT NOT NULL,
        center_x REAL NOT NULL,
        center_y REAL NOT NULL,
        size REAL NOT NULL,
        haptic_enabled INTEGER NOT NULL,
        PRIMARY KEY (controller_id),
        FOREIGN KEY (controller_id) REFERENCES controller_layouts (id)
      )
    ''');
  }

  // Controller Layout Methods
  Future<String> insertControllerLayout(ControllerLayout layout) async {
    final db = await database;
    await db.insert(
      'controller_layouts',
      {
        'id': layout.id,
        'name': layout.name,
        'width': layout.width,
        'height': layout.height,
        'is_editable': layout.isEditable ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert buttons
    for (var button in layout.buttons.entries) {
      await insertButtonLayout(button.value, layout.id);
    }

    // Insert joysticks
    if (layout.leftJoystick != null) {
      await insertJoystickLayout(layout.leftJoystick!, layout.id, 'left');
    }
    if (layout.rightJoystick != null) {
      await insertJoystickLayout(layout.rightJoystick!, layout.id, 'right');
    }

    // Insert DPad
    if (layout.dpadLayout != null) {
      await insertDPadLayout(layout.dpadLayout!, layout.id);
    }

    return layout.id;
  }

  Future<void> insertButtonLayout(
      ButtonLayout button, String controllerId) async {
    final db = await database;
    await db.insert(
      'button_layouts',
      {
        'id': '${controllerId}_${button.id}',
        'controller_id': controllerId,
        'x': button.x,
        'y': button.y,
        'shape': button.shape.toString(),
        'label': button.label,
        'width': button.width,
        'height': button.height,
        'angle': button.angle,
        'sensitivity': button.sensitivity,
        'deadzone': button.deadzone,
        'is_analog': button.isAnalog ? 1 : 0,
        'corner_radius': button.cornerRadius,
        'haptic_feedback': button.hapticFeedback ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertJoystickLayout(
      JoystickLayout joystick, String controllerId, String position) async {
    final db = await database;
    await db.insert(
      'joystick_layouts',
      {
        'id': '${controllerId}_${position}',
        'controller_id': controllerId,
        'position': position,
        'x': joystick.x,
        'y': joystick.y,
        'outer_size': joystick.outerSize,
        'inner_size': joystick.innerSize,
        'deadzone': joystick.deadzone,
        'max_distance': joystick.maxDistance,
        'is_draggable': joystick.isDraggable ? 1 : 0,
        'is_fixed': joystick.isFixed ? 1 : 0,
        'haptic_enabled': joystick.hapticEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDPadLayout(DPadLayout dpad, String controllerId) async {
    final db = await database;
    await db.insert(
      'dpad_layouts',
      {
        'id': '${controllerId}_dpad',
        'controller_id': controllerId,
        'center_x': dpad.centerX,
        'center_y': dpad.centerY,
        'size': dpad.size,
        'haptic_enabled': dpad.hapticEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ControllerLayout?> getControllerLayout(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> layoutMaps = await db.query(
      'controller_layouts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (layoutMaps.isEmpty) return null;

    // Get buttons
    final List<Map<String, dynamic>> buttonMaps = await db.query(
      'button_layouts',
      where: 'controller_id = ?',
      whereArgs: [id],
    );

    // Get joysticks
    final List<Map<String, dynamic>> joystickMaps = await db.query(
      'joystick_layouts',
      where: 'controller_id = ?',
      whereArgs: [id],
    );

    // Get DPad
    final List<Map<String, dynamic>> dpadMaps = await db.query(
      'dpad_layouts',
      where: 'controller_id = ?',
      whereArgs: [id],
    );

    // Convert maps to objects
    Map<String, ButtonLayout> buttons = {};
    for (var buttonMap in buttonMaps) {
      final button = ButtonLayout(
        id: buttonMap['id'],
        x: buttonMap['x'],
        y: buttonMap['y'],
        shape: ButtonShape.values
            .firstWhere((e) => e.toString() == buttonMap['shape']),
        label: buttonMap['label'],
        width: buttonMap['width'],
        height: buttonMap['height'],
        angle: buttonMap['angle'],
        sensitivity: buttonMap['sensitivity'],
        deadzone: buttonMap['deadzone'],
        isAnalog: buttonMap['is_analog'] == 1,
        cornerRadius: buttonMap['corner_radius'],
        hapticFeedback: buttonMap['haptic_feedback'] == 1,
      );
      buttons[button.id] = button;
    }

    JoystickLayout? leftJoystick;
    JoystickLayout? rightJoystick;
    for (var joystickMap in joystickMaps) {
      final joystick = JoystickLayout(
        x: joystickMap['x'],
        y: joystickMap['y'],
        outerSize: joystickMap['outer_size'],
        innerSize: joystickMap['inner_size'],
        deadzone: joystickMap['deadzone'],
        maxDistance: joystickMap['max_distance'],
        isDraggable: joystickMap['is_draggable'] == 1,
        isFixed: joystickMap['is_fixed'] == 1,
        hapticEnabled: joystickMap['haptic_enabled'] == 1,
      );

      if (joystickMap['position'] == 'left') {
        leftJoystick = joystick;
      } else {
        rightJoystick = joystick;
      }
    }

    DPadLayout? dpadLayout;
    if (dpadMaps.isNotEmpty) {
      final dpadMap = dpadMaps.first;
      dpadLayout = DPadLayout(
        centerX: dpadMap['center_x'],
        centerY: dpadMap['center_y'],
        size: dpadMap['size'],
        hapticEnabled: dpadMap['haptic_enabled'] == 1,
      );
    }

    return ControllerLayout(
      name: layoutMaps.first['name'],
      id: layoutMaps.first['id'],
      buttons: buttons,
      width: layoutMaps.first['width'],
      height: layoutMaps.first['height'],
      leftJoystick: leftJoystick,
      rightJoystick: rightJoystick,
      dpadLayout: dpadLayout,
      isEditable: layoutMaps.first['is_editable'] == 1,
    );
  }

  Future<List<ControllerLayout>> getAllControllerLayouts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('controller_layouts');

    List<ControllerLayout> layouts = [];
    for (var map in maps) {
      final layout = await getControllerLayout(map['id']);
      if (layout != null) {
        layouts.add(layout);
      }
    }

    return layouts;
  }

  Future<void> deleteControllerLayout(String id) async {
    final db = await database;

    // Gunakan transaction untuk memastikan semua delete berhasil
    await db.transaction((txn) async {
      // Delete semua button layouts terkait
      await txn.delete(
        'button_layouts',
        where: 'controller_id = ?',
        whereArgs: [id],
      );

      // Delete semua joystick layouts terkait
      await txn.delete(
        'joystick_layouts',
        where: 'controller_id = ?',
        whereArgs: [id],
      );

      // Delete dpad layout terkait
      await txn.delete(
        'dpad_layouts',
        where: 'controller_id = ?',
        whereArgs: [id],
      );

      // Terakhir delete controller layout-nya
      await txn.delete(
        'controller_layouts',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteAllControllerLayouts() async {
    final db = await database;

    // Gunakan transaction untuk memastikan semua delete berhasil
    await db.transaction((txn) async {
      // Delete semua data dari setiap tabel
      await txn.delete('button_layouts');
      await txn.delete('joystick_layouts');
      await txn.delete('dpad_layouts');
      await txn.delete('controller_layouts');
    });
  }
}
