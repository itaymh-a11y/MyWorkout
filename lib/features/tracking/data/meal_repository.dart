import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/meal_template.dart';

class MealRepository {
  MealRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection(FirestorePaths.mealLogs(uid));

  CollectionReference<Map<String, dynamic>> _templates(String uid) =>
      _firestore.collection(FirestorePaths.mealTemplates(uid));

  Stream<List<MealLog>> watchLogsOnDay(String uid, String day) {
    return _logs(uid).where('dayKey', isEqualTo: day).snapshots().map((snapshot) {
      final logs = snapshot.docs.map(MealLog.fromFirestore).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return logs;
    });
  }

  Stream<List<MealLog>> watchLogsInRange(
    String uid, {
    required String startDay,
    required String endDay,
  }) {
    return _logs(uid)
        .where('dayKey', isGreaterThanOrEqualTo: startDay)
        .where('dayKey', isLessThanOrEqualTo: endDay)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MealLog.fromFirestore).toList(),
        );
  }

  Future<String> addLog({
    required String uid,
    required String dayKey,
    required String name,
    required int kcal,
    required double proteinG,
    double? carbsG,
    double? fatG,
    double? portionGrams,
    String? templateId,
  }) async {
    final ref = _logs(uid).doc();
    await ref.set({
      'dayKey': dayKey,
      'name': name,
      'kcal': kcal,
      'proteinG': proteinG,
      'carbsG': ?carbsG,
      'fatG': ?fatG,
      'portionGrams': ?portionGrams,
      'templateId': ?templateId,
      'source': MealLog.sourceManual,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteLog(String uid, String logId) {
    return _logs(uid).doc(logId).delete();
  }

  Stream<List<MealTemplate>> watchTemplates(String uid) {
    return _templates(uid).orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(MealTemplate.fromFirestore).toList(),
        );
  }

  Future<String> saveTemplate({
    required String uid,
    required String name,
    required int kcal,
    required double proteinG,
    double? carbsG,
    double? fatG,
    double? portionGrams,
  }) async {
    final ref = _templates(uid).doc();
    await ref.set(
      MealTemplate(
        id: ref.id,
        name: name,
        kcal: kcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        portionGrams: portionGrams,
      ).toMap(),
    );
    return ref.id;
  }

  Future<void> updateTemplate(String uid, MealTemplate template) {
    return _templates(uid).doc(template.id).set(template.toMap());
  }

  Future<void> deleteTemplate(String uid, String templateId) {
    return _templates(uid).doc(templateId).delete();
  }
}
