import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myworkout/firebase_options.dart';

/// אתחול שירותי ליבה לפני הרצת האפליקציה.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline persistence — מובייל; ב-Web נדרש enableIndexedDbPersistence בנפרד (שלב מאוחר יותר).
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  await Hive.initFlutter();
}
