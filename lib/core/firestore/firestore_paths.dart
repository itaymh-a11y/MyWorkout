/// נתיבי Firestore מרכזיים.
abstract final class FirestorePaths {
  static const builtinExercises = 'builtin_exercises';

  static String userDoc(String uid) => 'users/$uid';

  static String userExercises(String uid) => 'users/$uid/exercises';

  static String exerciseOverrides(String uid) =>
      'users/$uid/exercise_overrides';

  static String exerciseCategories(String uid) =>
      'users/$uid/exercise_categories';

  static String userPlans(String uid) => 'users/$uid/plans';

  static String userPlanDoc(String uid, String planId) =>
      'users/$uid/plans/$planId';

  static String planExercises(String uid, String planId) =>
      'users/$uid/plans/$planId/exercises';

  static String userSessions(String uid) => 'users/$uid/sessions';

  static String userSessionDoc(String uid, String sessionId) =>
      'users/$uid/sessions/$sessionId';

  static String sessionSets(String uid, String sessionId) =>
      'users/$uid/sessions/$sessionId/sets';
}
