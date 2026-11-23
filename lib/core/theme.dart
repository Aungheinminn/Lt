import 'package:material_ui/material_ui.dart';

import '../ui/tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? LtColors.dark : LtColors.light;
  final scheme = ColorScheme.fromSeed(seedColor: c.brand, brightness: brightness).copyWith(
    primary: c.brand,
    onPrimary: c.onBrand,
    primaryContainer: c.brandSoft,
    onPrimaryContainer: c.brandText,
    secondaryContainer: c.brandSoft,
    onSecondaryContainer: c.brandText,
    surface: c.bg,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surface2,
    outline: c.faint,
    outlineVariant: c.line,
    error: c.rec,
    errorContainer: c.recSoft,
  );
  final shape10 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(LtRadius.sm));
  const buttonText = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: kFontFamily);

  final base = ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.ink, size: 22),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: shape10,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: c.brandText,
        shape: shape10,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.ink),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.brand : c.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface2,
      hintStyle: TextStyle(color: c.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LtRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LtRadius.sm),
        borderSide: BorderSide(color: c.brand, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.bg, fontFamily: kFontFamily, fontSize: 14),
      actionTextColor: c.brandSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LtRadius.md)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LtRadius.xl)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LtRadius.md)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: c.bg, fontSize: 12),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
  );
}
