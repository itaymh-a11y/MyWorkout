# Seed — תרגילים מובנים

האפליקציה **אינה** יכולה לכתוב ל-`builtin_exercises` (חסום ב-Firestore Rules).
יש לטעון את הנתונים פעם אחת מהמחשב:

## אפשרות א': סקריפט Node (מומלץ)

1. ב-Firebase Console → Project Settings → Service accounts → **Generate new private key**
2. שמור את הקובץ (למשל `serviceAccountKey.json`) **מחוץ** ל-git
3. התקן תלויות והרץ:

```powershell
cd c:\Cursor\MyWorkout\scripts
npm init -y
npm install firebase-admin
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"
$env:FIREBASE_PROJECT_ID="myworkout-f6236"
node ..\scripts\seed-builtin.mjs
```

## אפשרות ב': ייבוא ידני בקונסול

Firebase Console → Firestore → **Start collection** → `builtin_exercises`  
העתק מסמכים מ-`assets/seed/builtin_exercises.json` (כל אובייקט = מסמך, השדה `id` = Document ID).

## אימות

באפליקציה (מצב Debug): מסך בדיקות נתונים → "טען תרגילים מובנים".
