import 'package:flutter/material.dart';

/// לוגו MyWorkout — גדלים שונים למסך כניסה, AppBar ועוד.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 48,
    this.semanticLabel = 'MyWorkout',
  });

  /// לוגו קטן ל-AppBar ומסכים פנימיים.
  const AppLogo.small({super.key})
      : height = 32,
        semanticLabel = 'MyWorkout';

  /// לוגו גדול למסך התחברות.
  const AppLogo.large({super.key})
      : height = 140,
        semanticLabel = 'MyWorkout';

  static const assetPath = 'assets/branding/app_logo.png';

  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.high,
    );
  }
}
