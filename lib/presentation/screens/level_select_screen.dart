import 'package:flutter/material.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/level_data.dart';
import '../../data/repositories/airport_repository.dart';
import '../../data/repositories/level_repository.dart';
import 'atc_gameplay_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _selectedTierIndex = 0; // 0: 1-25, 1: 26-50, 2: 51-75, 3: 76-100

  final List<(String, int, int)> _tiers = [
    ('1 - 25', 1, 25),
    ('26 - 50', 26, 50),
    ('51 - 75', 51, 75),
    ('76 - 100', 76, 100),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = RadarThemeScope.of(context);
    final progress = GameProgressManager();
    final unlockedLvl = progress.highestUnlockedLevel;

    int totalStars = 0;
    for (int i = 1; i <= 100; i++) {
      totalStars += progress.getStarsForLevel(i);
    }

    final tier = _tiers[_selectedTierIndex];
    final tierLevels = LevelRepository.levels
        .where((lvl) => lvl.levelNumber >= tier.$2 && lvl.levelNumber <= tier.$3)
        .toList();

    return Scaffold(
      backgroundColor: theme.airspaceBackground,
      appBar: AppBar(
        backgroundColor: theme.hudSurface,
        elevation: 0,
        title: Text(
          'LEVEL GAME (1 - 100)',
          style: TextStyle(
            color: theme.accentColor,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.hudBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AtcColors.starGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AtcColors.starGold),
                const SizedBox(width: 4),
                Text(
                  '$totalStars / 300',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tier Selector Tabs (1-25, 26-50, 51-75, 76-100)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.hudSurface.withValues(alpha: 0.9),
              child: Row(
                children: List.generate(_tiers.length, (idx) {
                  final t = _tiers[idx];
                  final isSelected = _selectedTierIndex == idx;
                  final isTierUnlocked = unlockedLvl >= t.$2;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTierIndex = idx;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.accentColor
                                : (isTierUnlocked
                                    ? theme.hudBorder.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.accentColor
                                  : theme.hudBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t.$1,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : (isTierUnlocked ? theme.textPrimary : theme.textSecondary.withValues(alpha: 0.5)),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 100 Levels Grid View
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: tierLevels.length,
                itemBuilder: (context, index) {
                  final level = tierLevels[index];
                  final isUnlocked = progress.isLevelUnlocked(level.levelNumber);
                  final stars = progress.getStarsForLevel(level.levelNumber);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isUnlocked
                          ? () {
                              final airport = AirportRepository.getAirportByCode(level.airportCode);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AtcGameplayScreen(
                                    airport: airport,
                                    gameMode: GameMode.level,
                                    levelData: level,
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? theme.hudSurface
                              : Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isUnlocked
                                ? (stars > 0 ? theme.accentColor : theme.hudBorder)
                                : theme.hudBorder.withValues(alpha: 0.3),
                            width: isUnlocked && stars == 3 ? 1.6 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isUnlocked) ...[
                              Icon(
                                Icons.lock_rounded,
                                size: 18,
                                color: theme.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              '${level.levelNumber}',
                              style: TextStyle(
                                color: isUnlocked ? theme.textPrimary : theme.textSecondary.withValues(alpha: 0.5),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (level.hasTakeoffRunway && isUnlocked) ...[
                              const SizedBox(height: 2),
                              Text(
                                '🛫',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                            const SizedBox(height: 4),
                            if (isUnlocked)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (starIdx) {
                                  return Icon(
                                    starIdx < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 11,
                                    color: starIdx < stars ? AtcColors.starGold : theme.textSecondary.withValues(alpha: 0.35),
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

