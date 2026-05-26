import 'package:flutter/material.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';

/// כרטיס עם פס הדגשה צבעוני — מבדיל אימון / תרגיל / תוכנית / לוח.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.accent,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final ContentAccent accent;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final accentColor = brand.contentAccent(accent);
    final fill = color ?? AppColors.cardSurface;

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: Border(
            right: BorderSide(color: accentColor, width: 4),
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
