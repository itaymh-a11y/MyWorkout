import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/exercises/data/builtin_exercise_catalog.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_override.dart';
import 'package:myworkout/shared/models/exercise_source.dart';

class ExerciseRepository {
  ExerciseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _builtin =>
      _firestore.collection(FirestorePaths.builtinExercises);

  CollectionReference<Map<String, dynamic>> _userExercises(String uid) =>
      _firestore.collection(FirestorePaths.userExercises(uid));

  CollectionReference<Map<String, dynamic>> _exerciseOverrides(String uid) =>
      _firestore.collection(FirestorePaths.exerciseOverrides(uid));

  Future<List<Exercise>> _resolveBuiltin(
    List<Exercise> fromFirestore,
  ) async {
    if (fromFirestore.isNotEmpty) return fromFirestore;
    return BuiltinExerciseCatalog.load();
  }

  List<Exercise> applyOverrides(
    List<Exercise> exercises,
    Map<String, ExerciseOverride> overrides,
  ) {
    return exercises
        .map((e) => e.withOverride(overrides[e.id]))
        .toList();
  }

  Stream<Map<String, ExerciseOverride>> watchExerciseOverrides(String uid) {
    return _exerciseOverrides(uid).snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs)
          doc.id: ExerciseOverride.fromFirestore(doc),
      };
    });
  }

  Stream<List<Exercise>> watchBuiltinExercises() {
    return _builtin.orderBy('name').snapshots().asyncMap((snapshot) async {
      final fromFirestore = snapshot.docs
          .map(
            (doc) => Exercise.fromFirestore(
              doc,
              source: ExerciseSource.builtin,
            ),
          )
          .toList();
      return _resolveBuiltin(fromFirestore);
    });
  }

  Stream<List<Exercise>> watchUserExercises(String uid) {
    return _userExercises(uid).orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Exercise.fromFirestore(
                  doc,
                  source: ExerciseSource.custom,
                ),
              )
              .toList(),
        );
  }

  Future<List<Exercise>> fetchBuiltinExercisesOnce() async {
    final snapshot = await _builtin.orderBy('name').get();
    final fromFirestore = snapshot.docs
        .map(
          (doc) => Exercise.fromFirestore(
            doc,
            source: ExerciseSource.builtin,
          ),
        )
        .toList();
    return _resolveBuiltin(fromFirestore);
  }

  Future<Exercise?> getBuiltinExercise(
    String rawId, {
    String? uid,
  }) async {
    Exercise? base;
    final doc = await _builtin.doc(rawId).get();
    if (doc.exists) {
      base = Exercise.fromFirestore(doc, source: ExerciseSource.builtin);
    } else {
      final catalog = await BuiltinExerciseCatalog.load();
      for (final exercise in catalog) {
        if (exercise.id == rawId) {
          base = exercise;
          break;
        }
      }
    }
    if (base == null) return null;
    if (uid == null) return base;

    final overrideDoc = await _exerciseOverrides(uid).doc(rawId).get();
    if (!overrideDoc.exists) return base;
    return base.withOverride(ExerciseOverride.fromFirestore(overrideDoc));
  }

  Future<Exercise?> getUserExercise(String uid, String rawId) async {
    final doc = await _userExercises(uid).doc(rawId).get();
    if (!doc.exists) return null;
    return Exercise.fromFirestore(doc, source: ExerciseSource.custom);
  }

  /// שומר התאמה אישית לברירות מחדל של תרגיל מובנה.
  Future<void> saveBuiltinOverride(
    String uid,
    String builtinExerciseId,
    ExerciseOverride override,
  ) async {
    await _exerciseOverrides(uid).doc(builtinExerciseId).set(override.toMap());
  }

  /// מחזיר תרגיל מובנה לברירות המחדל הגלובליות.
  Future<void> resetBuiltinOverride(String uid, String builtinExerciseId) async {
    await _exerciseOverrides(uid).doc(builtinExerciseId).delete();
  }

  Future<String> createUserExercise(String uid, Exercise exercise) async {
    final docRef = exercise.id.isNotEmpty
        ? _userExercises(uid).doc(exercise.id)
        : _userExercises(uid).doc();

    final data = exercise
        .copyWith(
          source: ExerciseSource.custom,
          createdAt: exercise.createdAt ?? DateTime.now(),
        )
        .toMap();

    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateUserExercise(String uid, Exercise exercise) async {
    await _userExercises(uid).doc(exercise.id).update(
          exercise.toMap(includeCreatedAt: false),
        );
  }

  Future<void> deleteUserExercise(String uid, String rawId) async {
    await _userExercises(uid).doc(rawId).delete();
  }
}
