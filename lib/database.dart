import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  // Connect to Cloud Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection name
  static const String _collection = 'users';

  // SAVE USER PROFILE
  static Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  // GET USER PROFILE
  static Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final doc = await _db.collection(_collection).doc(uid).get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to retrieve user profile: $e');
    }
  }

  // UPDATE USER PROFILE
  static Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _db.collection(_collection).doc(uid).update({
        'name': name,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // DELETE USER PROFILE
  static Future<void> deleteProfile(String uid) async {
    try {
      await _db.collection(_collection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Get the user's growth_children collection.
  static CollectionReference<Map<String, dynamic>> _childrenCollection(
    String uid,
  ) {
    return _db.collection('users').doc(uid).collection('growth_children');
  }

  // ==========================================
  // CHILD FUNCTIONS
  // ==========================================

  // Add a child.
  static Future<String> addChild({
    required String uid,
    required String name,
    required String birth,
    required String sex,
  }) async {
    final doc = await _childrenCollection(uid).add({
      'name': name,
      'birth': birth,
      'sex': sex,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Get all children belonging to a user.
  static Future<List<Map<String, dynamic>>> getChildren(String uid) async {
    final snapshot = await _childrenCollection(uid).get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  // Update a child's information.
  static Future<void> updateChild({
    required String uid,
    required String childId,
    required String name,
    required String birth,
    required String sex,
  }) async {
    await _childrenCollection(uid)
        .doc(childId)
        .update({'name': name, 'birth': birth, 'sex': sex});
  }

  // Delete a child and their measurement records.
  static Future<void> deleteChild({
    required String uid,
    required String childId,
  }) async {
    final childRef = _childrenCollection(uid).doc(childId);

    final measurements = await childRef.collection('growth_measurements').get();

    final batch = _db.batch();

    for (final doc in measurements.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(childRef);

    await batch.commit();
  }

  // ==========================================
  // MEASUREMENT FUNCTIONS
  // ==========================================

  // Add a growth measurement.
  static Future<String> addMeasurement({
    required String uid,
    required String childId,
    required String date,
    required double height,
    required double weight,
    required String method,
  }) async {
    final doc = await _childrenCollection(uid)
        .doc(childId)
        .collection('growth_measurements')
        .add({
          'date': date,
          'height': height,
          'weight': weight,
          'method': method,
          'createdAt': FieldValue.serverTimestamp(),
        });

    return doc.id;
  }

  // Get all measurements for a child.
  static Future<List<Map<String, dynamic>>> getMeasurements({
    required String uid,
    required String childId,
  }) async {
    final snapshot = await _childrenCollection(uid)
        .doc(childId)
        .collection('growth_measurements')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  // Update a measurement.
  static Future<void> updateMeasurement({
    required String uid,
    required String childId,
    required String measurementId,
    required String date,
    required double height,
    required double weight,
    required String method,
  }) async {
    await _childrenCollection(uid)
        .doc(childId)
        .collection('growth_measurements')
        .doc(measurementId)
        .update({
          'date': date,
          'height': height,
          'weight': weight,
          'method': method,
        });
  }

  // Delete a measurement.
  static Future<void> deleteMeasurement({
    required String uid,
    required String childId,
    required String measurementId,
  }) async {
    await _childrenCollection(uid)
        .doc(childId)
        .collection('growth_measurements')
        .doc(measurementId)
        .delete();
  }
}

class GrowthRepository {
  GrowthRepository();

  // Convert Firestore data into the format expected by growth.dart.
  Map<String, Object?> _convert(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }

      return MapEntry(key, value);
    });
  }

  // Get all children belonging to the signed-in user.
  Future<List<Map<String, Object?>>> children(String ownerId) async {
    final result = await DatabaseHelper.getChildren(ownerId);

    return result.map(_convert).toList();
  }

  // Get all measurements belonging to a selected child.
  Future<List<Map<String, Object?>>> measurements(
    String ownerId,
    String childId,
  ) async {
    final result = await DatabaseHelper.getMeasurements(
      uid: ownerId,
      childId: childId,
    );

    final measurements = result.map(_convert).toList();

    // Newest measurement first.
    measurements.sort((a, b) {
      final dateA = a['date'] as String;
      final dateB = b['date'] as String;

      final dateComparison = dateB.compareTo(dateA);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final createdA = (a['createdAt'] as num?) ?? 0;
      final createdB = (b['createdAt'] as num?) ?? 0;

      return createdB.compareTo(createdA);
    });

    return measurements;
  }

  // Add a child.
  Future<String> addChild(
    String ownerId,
    String name,
    String birth,
    String sex,
  ) {
    return DatabaseHelper.addChild(
      uid: ownerId,
      name: name,
      birth: birth,
      sex: sex,
    );
  }

  // Update a child's information.
  Future<void> updateChild(
    String ownerId,
    String childId,
    String name,
    String birth,
    String sex,
  ) {
    return DatabaseHelper.updateChild(
      uid: ownerId,
      childId: childId,
      name: name,
      birth: birth,
      sex: sex,
    );
  }

  // Delete a child and their measurements.
  Future<void> deleteChild(String ownerId, String childId) {
    return DatabaseHelper.deleteChild(uid: ownerId, childId: childId);
  }

  // Add a growth measurement.
  Future<String> addMeasurement(
    String ownerId,
    String childId,
    String date,
    double height,
    double weight,
    String method,
  ) {
    return DatabaseHelper.addMeasurement(
      uid: ownerId,
      childId: childId,
      date: date,
      height: height,
      weight: weight,
      method: method,
    );
  }

  // Update a growth measurement.
  Future<void> updateMeasurement({
    required String ownerId,
    required String childId,
    required String measurementId,
    required String date,
    required double height,
    required double weight,
    required String method,
  }) {
    return DatabaseHelper.updateMeasurement(
      uid: ownerId,
      childId: childId,
      measurementId: measurementId,
      date: date,
      height: height,
      weight: weight,
      method: method,
    );
  }

  // Delete a growth measurement.
  Future<void> deleteMeasurement({
    required String ownerId,
    required String childId,
    required String measurementId,
  }) {
    return DatabaseHelper.deleteMeasurement(
      uid: ownerId,
      childId: childId,
      measurementId: measurementId,
    );
  }

  // Get the user's profile name if needed.
  Future<String?> profileName(String ownerId) async {
    final profile = await DatabaseHelper.getProfile(ownerId);
    return profile?['name'] as String?;
  }
}
