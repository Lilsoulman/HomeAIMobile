import 'package:flutter/material.dart';

/// Shared visual tokens for every NexusMind surface.
abstract final class NexusPalette {
  static const brandGreen = Color(0xFF3DD6A0);
  static const aiAccent = Color(0xFF73A7FF);
  static const homeAccent = Color(0xFF4DA3FF);
  static const text = Color(0xFF1A1A1A);
  static const lightBackground = Color(0xFFF6F7F9);
  static const lightCard = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkSurfaceRaised = Color(0xFF36363A);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkTextTertiary = Color(0xFF71717A);
  static const lightOutline = Color(0xFFE3E5E8);
  static const darkOutline = Color(0x1AFFFFFF);
}

abstract final class NexusLayout {
  static const pagePadding = EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  static const contentRadius = 20.0;
  static const controlRadius = 16.0;
  static const sectionGap = 24.0;
  static const controlGap = 12.0;
  static const itemGap = 12.0;
  static const bottomContentPadding = 100.0;
}

abstract final class NexusTheme {
  static ThemeData light(Color accent) => _build(
    brightness: Brightness.light,
    accent: accent,
    background: NexusPalette.lightBackground,
    card: NexusPalette.lightCard,
    outline: NexusPalette.lightOutline,
  );

  static ThemeData dark(Color accent) => _build(
    brightness: Brightness.dark,
    accent: accent,
    background: NexusPalette.darkBackground,
    card: NexusPalette.darkCard,
    outline: NexusPalette.darkOutline,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color background,
    required Color card,
    required Color outline,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          secondary: NexusPalette.brandGreen,
          surface: card,
          primaryContainer: isDark
              ? const Color(0xFF203243)
              : const Color(0xFFDCEEFF),
          onPrimaryContainer: isDark
              ? const Color(0xFFD9ECFF)
              : const Color(0xFF102A43),
          secondaryContainer: isDark
              ? const Color(0xFF1B3933)
              : const Color(0xFFD9F7EC),
          onSecondaryContainer: isDark
              ? const Color(0xFFC9F8E6)
              : const Color(0xFF073B2A),
          surfaceContainerHighest: isDark
              ? NexusPalette.darkSurfaceRaised
              : const Color(0xFFF0F1F3),
          onSurface: isDark ? NexusPalette.darkTextPrimary : NexusPalette.text,
          onSurfaceVariant: isDark
              ? NexusPalette.darkTextSecondary
              : const Color(0xFF6C6C72),
          outline: outline,
          outlineVariant: outline,
        );
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'Microsoft YaHei',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final controlBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: outline,
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: isDark ? NexusPalette.darkTextSecondary : null,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: isDark ? NexusPalette.darkTextTertiary : null,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: scheme.onSurface,
          backgroundColor: card,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: controlBorder,
        enabledBorder: controlBorder,
        focusedBorder: controlBorder.copyWith(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: card,
        indicatorColor: accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFF2F2F4) : NexusPalette.text,
        contentTextStyle: TextStyle(
          color: isDark ? NexusPalette.text : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        ),
      ),
    );
  }
}

class NexusSurface extends StatelessWidget {
  const NexusSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      border: Border.all(color: Theme.of(context).dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// The shared context anchor used at the top of primary workspace pages.
class NexusPageHeader extends StatelessWidget {
  const NexusPageHeader({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}
