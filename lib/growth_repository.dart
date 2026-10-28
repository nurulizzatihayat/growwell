import 'package:sqflite/sqflite.dart';
import 'database.dart';

class GrowthRepository {
  Future<String?> profileName(String owner) async {
    final rows = await (await DatabaseHelper.database).query('profiles',
        columns: ['name'], where: 'uid = ?', whereArgs: [owner], limit: 1);
    return rows.isEmpty ? null : rows.first['name'] as String?;
  }

  Future<List<Map<String, Object?>>> children(String owner) async =>
      (await DatabaseHelper.database).query('growth_children',
          where: 'owner = ?', whereArgs: [owner], orderBy: 'name');

  Future<int> addChild(
          String owner, String name, String birth, String sex) async =>
      (await DatabaseHelper.database).insert('growth_children',
          {'owner': owner, 'name': name, 'birth': birth, 'sex': sex});

  Future<void> updateChild(
      String owner, int id, String name, String birth, String sex) async {
    final count = await (await DatabaseHelper.database).update(
        'growth_children', {'name': name, 'birth': birth, 'sex': sex},
        where: 'owner = ? AND id = ?', whereArgs: [owner, id]);
    if (count != 1) throw StateError('Child not found');
  }

  Future<List<Map<String, Object?>>> measurements(
          String owner, int childId) async =>
      (await DatabaseHelper.database).rawQuery(
          'SELECT m.* FROM growth_measurements m JOIN growth_children c ON c.id = m.child_id WHERE c.owner = ? AND c.id = ? ORDER BY m.date DESC, m.id DESC',
          [owner, childId]);

  Future<void> addMeasurement(String owner, int childId, String date,
      double height, double weight, String method) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      final child = await txn.query('growth_children',
          where: 'owner = ? AND id = ?', whereArgs: [owner, childId]);
      if (child.isEmpty) throw StateError('Child not found');
      await txn.insert(
          'growth_measurements',
          {
            'child_id': childId,
            'date': date,
            'height': height,
            'weight': weight,
            'method': method
          },
          conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }
}
