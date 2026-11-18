import 'package:flutter/material.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/level_data.dart';

class LandingResultsDialog extends StatelessWidget {
  final RadarTheme theme;
  final GameMode gameMode;
  final bool isVictory;
  final int stars;
  final int landings;
  final int score;
  final String statusReason;
  final VoidCallback onRetry;
  final VoidCallback onNextStage;

  const LandingResultsDialog({
    super.key,
    required this.theme,
    this.gameMode = GameMode.classic,
    required this.isVictory,
    this.stars = 3,
    required this.landings,
    required this.score,
    required this.statusReason,
    required this.onRetry,
    required this.onNextStage,
  });

  @override
  Widget build(BuildContext context) {
    final isLevelMode = gameMode == GameMode.level;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.hudSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVictory ? theme.ilsConeColor : AtcColors.tcasCriticalRed,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (isVictory ? theme.ilsConeColor : AtcColors.tcasCriticalRed)
                  .withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVictory && isLevelMode) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      idx < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: idx < stars
                          ? AtcColors.starGold
                          : theme.textSecondary.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Icon(
                isVictory ? Icons.emoji_events : Icons.warning_amber_rounded,
                size: 48,
                color: isVictory ? AtcColors.starGold : AtcColors.tcasCriticalRed,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              isVictory
                  ? (isLevelMode ? 'LEVEL CLEARED!' : 'SECTOR CLEARED!')
                  : 'AIRSPACE SHUTDOWN',
              style: TextStyle(
                color: isVictory ? theme.ilsConeColor : AtcColors.tcasCriticalRed,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusReason,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.airspaceBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.hudBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'OPERATIONS',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$landings',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: theme.hudBorder),
                  Column(
                    children: [
                      Text(
                        'FINAL SCORE',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      side: BorderSide(color: theme.hudBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onRetry,
                    child: const Text('RETRY', style: TextStyle(fontFamily: 'monospace')),
                  ),
                ),
                if (isVictory) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onNextStage,
                      child: Text(
                        isLevelMode ? 'NEXT LEVEL' : 'NEXT STAGE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
