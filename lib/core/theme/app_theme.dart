import 'package:flutter/material.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';

/// ערכת נושא MyWorkout — כתום־אש, כחול־פלדה וכסף.
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ember,
      onPrimary: Colors.white,
      primaryContainer: AppColors.emberLight,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.navy,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.silverLight,
      onSecondaryContainer: AppColors.navy,
      tertiary: AppColors.silverDark,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.silverMuted,
      onTertiaryContainer: AppColors.navy,
      error: Color(0xFFC62828),
      onError: Colors.white,
      surface: AppColors.warmBackground,
      onSurface: AppColors.navy,
      onSurfaceVariant: AppColors.silverDark,
      outline: AppColors.silver,
      outlineVariant: AppColors.silverLight,
      shadow: Color(0x1A1E3354),
      surfaceTint: AppColors.ember,
      inverseSurface: AppColors.navy,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.emberLight,
    );

    final baseText = TextTheme(
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      titleSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      labelLarge: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      bodyLarge: const TextStyle(color: AppColors.navy),
      bodyMedium: const TextStyle(color: AppColors.navy),
      bodySmall: const TextStyle(color: AppColors.silverDark),
      labelSmall: const TextStyle(color: AppColors.silverDark),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const [AppBrandColors.light],
      scaffoldBackgroundColor: AppColors.warmBackground,
      textTheme: baseText,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.cardSurface,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        height: 68,
        backgroundColor: AppColors.cardSurface,
        indicatorColor: AppColors.emberLight,
        shadowColor: AppColors.navy.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.navy : AppColors.silverDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.ember : AppColors.silverDark,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.silverLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.silverLight,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.silverLight,
          disabledForegroundColor: AppColors.silverDark,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.silver, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navyMid,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        labelStyle: const TextStyle(color: AppColors.silverDark),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.silverLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ember, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.silverMuted,
        selectedColor: AppColors.navy.withValues(alpha: 0.12),
        labelStyle: const TextStyle(color: AppColors.navy),
        secondaryLabelStyle: const TextStyle(color: AppColors.navy),
        checkmarkColor: AppColors.navy,
        side: const BorderSide(color: AppColors.silverLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.silverDark,
        textColor: AppColors.navy,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.ember;
          }
          return AppColors.silverLight;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ember,
        linearTrackColor: AppColors.silverLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.cardSurface),
        elevation: WidgetStateProperty.all(0),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.silverLight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: baseText.titleMedium,
      ),
    );
  }
}
