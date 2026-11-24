import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPalette {
  final String name;
  final Color primary;
  final Color accent;
  final Color background;
  const AppPalette(this.name, this.primary, this.accent, this.background);
}

// Naya colour theme chahiye to yahan ek line add kar dein
const palettes = <AppPalette>[
  AppPalette(
      'White & Blue', Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFFFFFFF)),
  AppPalette('Maroon & Beige', Color(0xFF800000), Color(0xFFC8A97E),
      Color(0xFFF5EBDD)),
  AppPalette('Forest Green & Skin', Color(0xFF228B22), Color(0xFFE0A98B),
      Color(0xFFFDEBDD)),
  AppPalette('Indigo & Lavender', Color(0xFF3949AB), Color(0xFF9FA8DA),
      Color(0xFFF3F0FF)),
  AppPalette(
      'Teal & Mint', Color(0xFF00796B), Color(0xFF80CBC4), Color(0xFFEFFAF7)),
  AppPalette(
      'Black & Gold', Color(0xFF212121), Color(0xFFFFB300), Color(0xFFFFFBF0)),
  AppPalette('Orange & Cream', Color(0xFFE65100), Color(0xFFFFB74D),
      Color(0xFFFFF8E7)),
  AppPalette(
      'Purple & Pink', Color(0xFF6A1B9A), Color(0xFFF48FB1), Color(0xFFFFF0F6)),
  AppPalette(
      'Navy & Sky', Color(0xFF0D2B52), Color(0xFF4FC3F7), Color(0xFFEAF6FF)),
  AppPalette(
      'Rose & Grey', Color(0xFFC2185B), Color(0xFF90A4AE), Color(0xFFFAF3F5)),
];

// Naya font chahiye to Google Fonts ka naam yahan likh dein ('Default' pehla hi rahe)
const fontNames = <String>[
  'Default',
  'Roboto',
  'Poppins',
  'Lato',
  'Nunito',
  'Montserrat',
  'Open Sans',
  'Merriweather',
  'Playfair Display',
];

class ThemeController extends ChangeNotifier {
  int paletteIndex = 0;
  int fontIndex = 0;
  double fontScale = 1.0;
  bool dark = false;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      paletteIndex = (p.getInt('palette') ?? 0).clamp(0, palettes.length - 1);
      fontIndex = (p.getInt('font') ?? 0).clamp(0, fontNames.length - 1);
      fontScale = (p.getDouble('scale') ?? 1.0).clamp(0.8, 1.5);
      dark = p.getBool('dark') ?? false;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('palette', paletteIndex);
      await p.setInt('font', fontIndex);
      await p.setDouble('scale', fontScale);
      await p.setBool('dark', dark);
    } catch (_) {}
  }

  void setPalette(int i) {
    paletteIndex = i;
    notifyListeners();
    _save();
  }

  void setFont(int i) {
    fontIndex = i;
    notifyListeners();
    _save();
  }

  void setScale(double v) {
    fontScale = v;
    notifyListeners();
    _save();
  }

  void setDark(bool v) {
    dark = v;
    notifyListeners();
    _save();
  }

  void reset() {
    paletteIndex = 0;
    fontIndex = 0;
    fontScale = 1.0;
    dark = false;
    notifyListeners();
    _save();
  }

  Color _on(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
          ? Colors.white
          : Colors.black;

  ThemeData get themeData {
    final p = palettes[paletteIndex];
    final brightness = dark ? Brightness.dark : Brightness.light;

    var scheme =
        ColorScheme.fromSeed(seedColor: p.primary, brightness: brightness);
    if (!dark) {
      scheme = scheme.copyWith(
        primary: p.primary,
        onPrimary: _on(p.primary),
        secondary: p.accent,
        onSecondary: _on(p.accent),
        surface: p.background,
      );
    }

    final base = ThemeData(
        useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final textTheme = fontIndex == 0
        ? base.textTheme
        : GoogleFonts.getTextTheme(fontNames[fontIndex], base.textTheme);

    final barBg = dark ? scheme.surfaceContainer : scheme.primary;
    final barFg = dark ? scheme.onSurface : scheme.onPrimary;

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      iconTheme: IconThemeData(color: scheme.primary),
      appBarTheme: AppBarTheme(
        backgroundColor: barBg,
        foregroundColor: barFg,
        iconTheme: IconThemeData(color: barFg),
        actionsIconTheme: IconThemeData(color: barFg),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: barFg,
        unselectedLabelColor: barFg.withAlpha(180),
        indicatorColor: barFg,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondary.withAlpha(110),
      ),
    );
  }
}

// Poori app isi ek object se theme control karti hai
final themeCtrl = ThemeController();
