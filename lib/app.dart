import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myworkout/core/auth/auth_gate.dart';
import 'package:myworkout/core/theme/app_theme.dart';

class MyWorkoutApp extends StatelessWidget {
  const MyWorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWorkout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}
