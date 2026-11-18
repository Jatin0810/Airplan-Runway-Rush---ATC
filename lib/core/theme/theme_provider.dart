import 'package:flutter/material.dart';
import 'radar_theme.dart';

/// Notifier that manages the active radar theme and notifies listeners on change.
/// Defaults to the clean Daylight Satellite Map theme (Light Mode) as requested by the user.
class RadarThemeController extends ChangeNotifier {
  RadarTheme _currentTheme = const DaylightSatelliteRadarTheme();

  RadarTheme get theme => _currentTheme;

  final List<RadarTheme> availableThemes = const [
    DaylightSatelliteRadarTheme(),
    TacticalNightRadarTheme(),
    PhosphorGreenRadarTheme(),
    AmberTacticalRadarTheme(),
  ];

  void setTheme(RadarTheme newTheme) {
    if (_currentTheme == newTheme) return;
    _currentTheme = newTheme;
    notifyListeners();
  }

  void setThemeByIndex(int index) {
    if (index >= 0 && index < availableThemes.length) {
      setTheme(availableThemes[index]);
    }
  }

  /// Toggles between Daylight Satellite Map (Light Mode) and Tactical Night (Dark Mode)
  void toggleLightDarkMode() {
    if (_currentTheme.isLightMode) {
      setTheme(const TacticalNightRadarTheme());
    } else {
      setTheme(const DaylightSatelliteRadarTheme());
    }
  }
}

/// An InheritedNotifier widget providing effortless theme access down the widget tree.
class RadarThemeScope extends InheritedNotifier<RadarThemeController> {
  const RadarThemeScope({
    super.key,
    required RadarThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static RadarTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RadarThemeScope>();
    return scope?.notifier?.theme ?? const DaylightSatelliteRadarTheme();
  }

  static RadarThemeController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RadarThemeScope>();
    assert(scope?.notifier != null, 'No RadarThemeScope found in context');
    return scope!.notifier!;
  }
}
