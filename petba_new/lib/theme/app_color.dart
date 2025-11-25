import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppColorPalette {
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color icon;
  final Color border;

  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.border,
  });
}

class AppTheme {
  static const AppColorPalette lightPalette = AppColorPalette(
    background: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF4A90E2),
    secondary: Color(0xFF6E8EB5),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5F6368),
    icon: Color(0xFF4A4A4A),
    border: Color(0xFFE2E5EA),
  );

  static const AppColorPalette darkPalette = AppColorPalette(
    background: Color(0xFF0F1115),
    surface: Color(0xFF1E1F24),
    primary: Color(0xFF4A90E2),
    secondary: Color(0xFF6E8EB5),
    textPrimary: Color(0xFFF5F6FA),
    textSecondary: Color(0xFFB0B5BD),
    icon: Color(0xFFE0E0E0),
    border: Color(0xFF2E3138),
  );

  static ThemeData get lightTheme =>
      _buildTheme(lightPalette, Brightness.light);

  static ThemeData get darkTheme => _buildTheme(darkPalette, Brightness.dark);

  static ThemeData _buildTheme(AppColorPalette palette, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.secondary,
        onSecondary: Colors.white,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        background: palette.background,
        onBackground: palette.textPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      canvasColor: palette.surface,
      dividerColor: palette.border,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.icon),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: palette.icon),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: brightness == Brightness.light ? 0 : 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: palette.textSecondary),
        ),
        iconTheme: MaterialStateProperty.all(
          IconThemeData(color: palette.icon),
        ),
      ),
    );
  }
}

class AppThemeColors {
  AppThemeColors._(this._theme);

  final ThemeData _theme;

  factory AppThemeColors.of(BuildContext context) {
    return AppThemeColors._(Theme.of(context));
  }

  ColorScheme get _scheme => _theme.colorScheme;

  Color get background => _theme.scaffoldBackgroundColor;
  Color get surface => _theme.cardColor;
  Color get primary => _scheme.primary;
  Color get secondary => _scheme.secondary;
  Color get textPrimary => _scheme.onSurface;
  Color get textSecondary => _scheme.onSurfaceVariant;
  Color get error => _scheme.error;
  Color get border => _theme.dividerColor;
  Color get icon => _theme.iconTheme.color ?? _scheme.primary;
}

mixin ThemeColorMixin<T extends StatefulWidget> on State<T> {
  ThemeData get theme => Theme.of(context);
  ColorScheme get colorScheme => theme.colorScheme;
  Color get scaffoldColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => theme.cardColor;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get primaryAccent => colorScheme.primary;
  Color get secondaryAccent => colorScheme.secondary;
  Color get errorColor => colorScheme.error;
  Color get successColor => const Color(0xFF4CAF50);
  Color get warningColor => const Color(0xFFFFA000);
  Color get borderColor => theme.dividerColor;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSecondaryColor => colorScheme.onSecondary;
}

extension ThemeColorContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  Color get scaffoldColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => theme.cardColor;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get primaryAccent => colorScheme.primary;
  Color get secondaryAccent => colorScheme.secondary;
  Color get errorColor => colorScheme.error;
  Color get successColor => const Color(0xFF4CAF50);
  Color get warningColor => const Color(0xFFFFA000);
  Color get borderColor => theme.dividerColor;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSecondaryColor => colorScheme.onSecondary;
}
