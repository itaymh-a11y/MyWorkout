import 'package:firebase_auth/firebase_auth.dart';

/// תרגום שגיאות Firebase Auth לעברית.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'כתובת האימייל אינה תקינה.',
      'user-disabled' => 'חשבון זה הושבת.',
      'user-not-found' => 'לא נמצא משתמש עם אימייל זה.',
      'wrong-password' => 'סיסמה שגויה.',
      'invalid-credential' => 'אימייל או סיסמה שגויים.',
      'email-already-in-use' => 'כתובת האימייל כבר בשימוש.',
      'weak-password' => 'הסיסמה חלשה מדי (לפחות 6 תווים).',
      'operation-not-allowed' =>
        'התחברות באימייל לא מופעלת בפרויקט Firebase.',
      'too-many-requests' =>
        'יותר מדי ניסיונות. נסה שוב בעוד כמה דקות.',
      _ => error.message ?? 'אירעה שגיאה בהתחברות.',
    };
  }
  return 'אירעה שגיאה בלתי צפויה. נסה שוב.';
}
