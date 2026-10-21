import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final path = join(
      await getDatabasesPath(),
      'growwell.db',
    );

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            uid TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final db = await database;

    await db.insert(
      'profiles',
      {
        'uid': uid,
        'name': name,
        'email': email,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
