import 'package:flutter/material.dart';

/// Timbre "Broadcast" design system.
///
/// The app is a radio receiver: warm amber-on-charcoal night faceplate,
/// paper-amber day faceplate, IBM Plex Mono type, engraved line icons,
/// hairline panels instead of cards. All colors live here — never inline
/// in screens.
class TimbreColors {
  // Signal amber (lit dial segments, active states).
  static const accent = Color(0xFFFFB454);
  static const accentDeep = Color(0xFFB06A10); // day faceplate accent

  // Night faceplate (first-class).
  static const nightBg = Color(0xFF161310);
  static const nightSurface = Color(0xFF1D1913);
  static const nightSurfaceHigh = Color(0xFF2A2419);
  static const nightLine = Color(0xFF3A3426);
  static const nightOnBg = Color(0xFFE8E2D6);
  static const nightOnBgDim = Color(0xFF8A8272);

  // Day faceplate (paper).
  static const dayBg = Color(0xFFECE5D6);
  static const daySurface = Color(0xFFE0D8C6);
  static const daySurfaceHigh = Color(0xFFDED8CB);
  static const dayLine = Color(0xFFC9BFA9);
  static const dayOnBg = Color(0xFF332C20);
  static const dayOnBgDim = Color(0xFF8A8272);

  // Aliases kept for older call sites (sheet/dialog theming).
  static const darkBg = nightBg;
  static const darkSurface = nightSurface;
  static const darkSurfaceHigh = nightSurfaceHigh;
  static const lightBg = dayBg;
  static const lightSurface = daySurface;
  static const lightSurfaceHigh = daySurfaceHigh;
}

class TimbreSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class TimbreRadii {
  static const artwork = 10.0;
  static const chip = 7.0;
  static const sheet = 20.0;
  static const panel = 12.0;
}

/// Shared text styles. Screens compose these instead of ad-hoc Typography,
/// so labels always read as engraved faceplate text.
class TimbreText {
  static const family = 'PlexMono';

  /// Small uppercase label with wide tracking ("PROGRAM GUIDE", "MEMORY P1").
  static TextStyle kicker(BuildContext context, {Color? color}) => TextStyle(
        fontFamily: family,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        color: color ?? Theme.of(context).colorScheme.primary,
      );

  /// Dim section header on surface.
  static TextStyle section(BuildContext context) => TextStyle(
        fontFamily: family,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// Oversized dial digit / frequency clock.
  static TextStyle dial(BuildContext context, {double size = 30}) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.primary,
      );
}

class TimbreTheme {
  static ThemeData dark() => _base(Brightness.dark);
  static ThemeData light() => _base(Brightness.light);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? TimbreColors.nightBg : TimbreColors.dayBg;
    final surface = isDark ? TimbreColors.nightSurface : TimbreColors.daySurface;
    final surfaceHigh =
        isDark ? TimbreColors.nightSurfaceHigh : TimbreColors.daySurfaceHigh;
    final onBg = isDark ? TimbreColors.nightOnBg : TimbreColors.dayOnBg;
    final onBgDim = isDark ? TimbreColors.nightOnBgDim : TimbreColors.dayOnBgDim;
    final line = isDark ? TimbreColors.nightLine : TimbreColors.dayLine;
    final accent = isDark ? TimbreColors.accent : TimbreColors.accentDeep;

    final cs = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isDark ? const Color(0xFF161310) : Colors.white,
      secondary: accent,
      onSecondary: isDark ? const Color(0xFF161310) : Colors.white,
      error: const Color(0xFFE85D4A),
      onError: Colors.white,
      surface: surface,
      onSurface: onBg,
      surfaceContainerLowest: bg,
      surfaceContainerLow: bg,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: onBgDim,
      outline: line,
      outlineVariant: line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? TimbreColors.dayBg : TimbreColors.nightBg,
      onInverseSurface: isDark ? TimbreColors.dayOnBg : TimbreColors.nightOnBg,
      inversePrimary: isDark ? TimbreColors.accentDeep : TimbreColors.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      fontFamily: TimbreText.family,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(cs),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: TimbreText.family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onBg,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected) ? accent : onBgDim,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: TimbreText.family,
              fontSize: 9.5,
              letterSpacing: 1.2,
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? accent : onBgDim,
            )),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: TextStyle(fontFamily: TimbreText.family, color: onBg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: surfaceHigh,
        labelStyle: TextStyle(
          fontFamily: TimbreText.family,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: onBgDim,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TimbreRadii.chip),
        ),
        side: BorderSide(color: line),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TimbreRadii.sheet)),
        ),
        showDragHandle: true,
        dragHandleColor: onBgDim,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: TextStyle(fontFamily: TimbreText.family, color: onBg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(fontFamily: TimbreText.family, color: onBgDim),
        labelStyle: TextStyle(fontFamily: TimbreText.family, color: onBgDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimbreRadii.panel),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimbreRadii.panel),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TimbreRadii.panel),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : onBgDim),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent.withValues(alpha: 0.35) : line),
        trackOutlineColor: WidgetStatePropertyAll(line),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onBgDim,
        titleTextStyle: TextStyle(
            fontFamily: TimbreText.family, fontSize: 14.5, fontWeight: FontWeight.w500, color: onBg),
        subtitleTextStyle:
            TextStyle(fontFamily: TimbreText.family, fontSize: 11.5, color: onBgDim),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? TimbreColors.nightBg : Colors.white,
          textStyle: const TextStyle(
              fontFamily: TimbreText.family, fontWeight: FontWeight.w700, letterSpacing: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBg,
          side: BorderSide(color: line),
          textStyle: const TextStyle(
              fontFamily: TimbreText.family, fontWeight: FontWeight.w600, letterSpacing: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
              fontFamily: TimbreText.family, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onBg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: line),
      scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(line)),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    final base = TextStyle(fontFamily: TimbreText.family, color: cs.onSurface, height: 1.3);
    return TextTheme(
      displaySmall: base.copyWith(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: base.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
      headlineMedium: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      headlineSmall: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      titleMedium: base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
      titleSmall: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 15),
      bodyMedium: base.copyWith(fontSize: 13.5),
      bodySmall: base.copyWith(fontSize: 11.5, color: cs.onSurfaceVariant),
      labelLarge: base.copyWith(
          fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      labelMedium: base.copyWith(
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.6),
      labelSmall: base.copyWith(
          fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 1.8, color: cs.onSurfaceVariant),
    );
  }
}
