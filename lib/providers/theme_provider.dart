import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Color scheme provider
final colorSchemeProvider = StateNotifierProvider<ColorSchemeNotifier, ColorSchemeType>((ref) {
  return ColorSchemeNotifier();
});

// Theme data provider
final themeDataProvider = Provider<ThemeData>((ref) {
  final colorSchemeType = ref.watch(colorSchemeProvider);
  return _getThemeData(colorSchemeType);
});

// Dark theme data provider
final darkThemeDataProvider = Provider<ThemeData>((ref) {
  final colorSchemeType = ref.watch(colorSchemeProvider);
  return _getThemeData(colorSchemeType, isDark: true);
});

enum ColorSchemeType {
  indigo,
  blue,
  purple,
  teal,
  green,
  orange,
  red,
  pink,
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeModeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

class ColorSchemeNotifier extends StateNotifier<ColorSchemeType> {
  ColorSchemeNotifier() : super(ColorSchemeType.indigo) {
    _loadColorScheme();
  }

  Future<void> _loadColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorSchemeIndex = prefs.getInt('color_scheme') ?? 0;
    state = ColorSchemeType.values[colorSchemeIndex];
  }

  Future<void> setColorScheme(ColorSchemeType scheme) async {
    state = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_scheme', scheme.index);
  }
}

ThemeData _getThemeData(ColorSchemeType colorSchemeType, {bool isDark = false}) {
  final colorScheme = _getColorScheme(colorSchemeType, isDark: isDark);
  
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: isDark ? Brightness.dark : Brightness.light,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

ColorScheme _getColorScheme(ColorSchemeType type, {bool isDark = false}) {
  final brightness = isDark ? Brightness.dark : Brightness.light;
  
  switch (type) {
    case ColorSchemeType.indigo:
      return ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      );
    case ColorSchemeType.blue:
      return ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      );
    case ColorSchemeType.purple:
      return ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: brightness,
      );
    case ColorSchemeType.teal:
      return ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: brightness,
      );
    case ColorSchemeType.green:
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: brightness,
      );
    case ColorSchemeType.orange:
      return ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: brightness,
      );
    case ColorSchemeType.red:
      return ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: brightness,
      );
    case ColorSchemeType.pink:
      return ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: brightness,
      );
  }
}

String getColorSchemeDisplayName(ColorSchemeType type) {
  switch (type) {
    case ColorSchemeType.indigo:
      return 'Indigo';
    case ColorSchemeType.blue:
      return 'Blue';
    case ColorSchemeType.purple:
      return 'Purple';
    case ColorSchemeType.teal:
      return 'Teal';
    case ColorSchemeType.green:
      return 'Green';
    case ColorSchemeType.orange:
      return 'Orange';
    case ColorSchemeType.red:
      return 'Red';
    case ColorSchemeType.pink:
      return 'Pink';
  }
}

Color getColorSchemeColor(ColorSchemeType type) {
  switch (type) {
    case ColorSchemeType.indigo:
      return Colors.indigo;
    case ColorSchemeType.blue:
      return Colors.blue;
    case ColorSchemeType.purple:
      return Colors.purple;
    case ColorSchemeType.teal:
      return Colors.teal;
    case ColorSchemeType.green:
      return Colors.green;
    case ColorSchemeType.orange:
      return Colors.orange;
    case ColorSchemeType.red:
      return Colors.red;
    case ColorSchemeType.pink:
      return Colors.pink;
  }
}
