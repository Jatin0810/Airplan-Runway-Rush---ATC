import 'package:flutter/material.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/airport.dart';
import '../../data/models/level_data.dart';

/// Reusable Top Tactical HUD Bar displaying airport, wind, score, landing progress,
/// speed indicator, and instant Light/Dark mode toggle.
class AtcTacticalBar extends StatelessWidget {
  final AirportData airport;
  final RadarTheme theme;
  final GameMode gameMode;
  final int? levelNumber;
  final int targetLandings;
  final int currentLandings;
  final int currentScore;
  final double gameSpeed;
  final VoidCallback onThemePressed;
  final VoidCallback? onToggleLightDark;
  final VoidCallback? onPausePressed;
  final VoidCallback? onSpeedPressed;
  final bool isPaused;

  const AtcTacticalBar({
    super.key,
    required this.airport,
    required this.theme,
    this.gameMode = GameMode.classic,
    this.levelNumber,
    required this.targetLandings,
    required this.currentLandings,
    required this.currentScore,
    this.gameSpeed = 1.0,
    required this.onThemePressed,
    this.onToggleLightDark,
    this.onPausePressed,
    this.onSpeedPressed,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final isClassic = gameMode == GameMode.classic;

    return Container(
      decoration: BoxDecoration(
        color: theme.hudSurface,
        border: Border(
          bottom: BorderSide(color: theme.hudBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isLightMode ? 0.08 : 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Airport / Level Code, Live Blinker, Wind, Speed & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AtcColors.ilsActiveGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isClassic
                          ? '${airport.code} / ${airport.iata}'
                          : 'LVL $levelNumber • ${airport.iata}',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Text(
                  'WIND ${airport.windHeadingDeg.toInt()}° / ${airport.windSpeedKnots.toInt()}KT',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speed Toggle Button (1x / 2x)
                    if (onSpeedPressed != null)
                      InkWell(
                        onTap: onSpeedPressed,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: gameSpeed > 1.0
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                : theme.hudBorder.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: gameSpeed > 1.0
                                  ? const Color(0xFFF59E0B)
                                  : theme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            gameSpeed > 1.0 ? '2X' : '1X',
                            style: TextStyle(
                              color: gameSpeed > 1.0
                                  ? const Color(0xFFF59E0B)
                                  : theme.textPrimary,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Pause / Resume Button
                    if (onPausePressed != null)
                      InkWell(
                        onTap: onPausePressed,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isPaused
                                ? AtcColors.tcasWarningYellow.withValues(alpha: 0.25)
                                : theme.hudBorder.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPaused
                                  ? AtcColors.tcasWarningYellow
                                  : theme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            size: 13,
                            color: isPaused ? AtcColors.tcasWarningYellow : theme.accentColor,
                          ),
                        ),
                      ),
                    // Quick Light / Dark Mode Toggle Button
                    if (onToggleLightDark != null)
                      InkWell(
                        onTap: onToggleLightDark,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: theme.hudBorder.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            theme.isLightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            size: 13,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: onThemePressed,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.hudBorder.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_outlined, size: 12, color: theme.accentColor),
                            const SizedBox(width: 4),
                            Text(
                              theme.isLightMode ? 'LIGHT' : 'DARK',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Landings Progress, Score, Active Runway Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isClassic
                      ? 'OPERATIONS: $currentLandings (∞)'
                      : 'TARGET: $currentLandings / $targetLandings',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'SCORE: $currentScore',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.ilsConeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.ilsConeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    airport.hasTakeoffRunway
                        ? 'RWY ${airport.activeRunwayId} + DEP ACTIVE'
                        : 'RWY ${airport.activeRunwayId} ACTIVE',
                    style: TextStyle(
                      color: theme.ilsConeColor,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
