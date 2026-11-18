import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';

/// Reusable modal sheet to hot-swap radar themes in real-time.
class RadarThemeDialog extends StatelessWidget {
  const RadarThemeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = RadarThemeScope.controllerOf(context);
    final activeTheme = themeController.theme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: activeTheme.hudSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: activeTheme.hudBorder),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT RADAR THEME',
                  style: TextStyle(
                    color: activeTheme.accentColor,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: activeTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...themeController.availableThemes.map((themeOption) {
              final isSelected = activeTheme.name == themeOption.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeOption.accentColor.withValues(alpha: 0.15)
                      : themeOption.airspaceBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? themeOption.accentColor
                        : themeOption.hudBorder,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeOption.airspaceBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: themeOption.accentColor, width: 2),
                    ),
                  ),
                  title: Text(
                    themeOption.name,
                    style: TextStyle(
                      color: themeOption.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    themeOption.description,
                    style: TextStyle(
                      color: themeOption.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: themeOption.accentColor, size: 20)
                      : null,
                  onTap: () {
                    themeController.setTheme(themeOption);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
