import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/data/system_exercise_categories.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/shared/models/exercise_category_def.dart';

class ExerciseCategoryRepository {
  ExerciseCategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _categories(String uid) =>
      _firestore.collection(FirestorePaths.exerciseCategories(uid));

  Future<void> ensureSeeded(String uid) async {
    final snapshot = await _categories(uid).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final category in SystemExerciseCategories.all) {
      batch.set(_categories(uid).doc(category.id), category.toMap());
    }
    await batch.commit();
  }

  Stream<List<ExerciseCategoryDef>> watchCategories(String uid) async* {
    await ensureSeeded(uid);
    yield* _categories(uid).orderBy('order').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(ExerciseCategoryDef.fromFirestore).toList(),
        );
  }

  Future<String> createCategory(String uid, ExerciseCategoryDef category) async {
    final docRef = category.id.isNotEmpty
        ? _categories(uid).doc(category.id)
        : _categories(uid).doc();

    final snapshot = await _categories(uid).orderBy('order', descending: true).limit(1).get();
    final nextOrder = snapshot.docs.isEmpty
        ? 100
        : (ExerciseCategoryDef.fromFirestore(snapshot.docs.first).order + 1);

    await docRef.set(
      category
          .copyWith(
            id: docRef.id,
            order: category.order > 0 ? category.order : nextOrder,
            isSystem: false,
            iconKey: 'custom',
          )
          .toMap(),
    );
    return docRef.id;
  }

  Future<void> updateCategory(String uid, ExerciseCategoryDef category) async {
    await _categories(uid).doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    final doc = await _categories(uid).doc(categoryId).get();
    if (!doc.exists) return;
    final category = ExerciseCategoryDef.fromFirestore(doc);
    if (category.isSystem) {
      throw ExerciseCategoryRepositoryException(
        'לא ניתן למחוק קטגוריית מערכת',
      );
    }
    await _categories(uid).doc(categoryId).delete();
  }
}

class ExerciseCategoryRepositoryException implements Exception {
  ExerciseCategoryRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
