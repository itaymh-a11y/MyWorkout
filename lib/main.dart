import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/app.dart';
import 'package:myworkout/core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  try {
    await bootstrapApp();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    runApp(BootstrapErrorApp(message: error.toString()));
    return;
  }

  runApp(
    const ProviderScope(
      child: MyWorkoutApp(),
    ),
  );
}

/// מסך שגיאה כש-Firebase או Hive לא אותחלו (למשל לפני flutterfire configure).
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'שגיאת אתחול',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ודא שהרצת flutterfire configure והחלפת את firebase_options.dart.',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
