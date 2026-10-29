import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<void> _createGrowthTables(Database db) async {
    await db.execute(
        'CREATE TABLE growth_children (id INTEGER PRIMARY KEY AUTOINCREMENT, owner TEXT NOT NULL, name TEXT NOT NULL, birth TEXT NOT NULL, sex TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE growth_measurements (id INTEGER PRIMARY KEY AUTOINCREMENT, child_id INTEGER NOT NULL, date TEXT NOT NULL, height REAL NOT NULL, weight REAL NOT NULL, method TEXT NOT NULL, FOREIGN KEY (child_id) REFERENCES growth_children(id))');
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), 'growwell.db');
    _database = await openDatabase(path,
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE profiles (uid TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL)');
          await _createGrowthTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createGrowthTables(db);
        });
    return _database!;
  }

  static Future<void> saveProfile(
      {required String uid,
      required String name,
      required String email}) async {
    final db = await database;
    await db.insert('profiles', {'uid': uid, 'name': name, 'email': email},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
