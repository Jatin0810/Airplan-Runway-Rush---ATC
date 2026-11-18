import 'package:flutter/material.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/level_data.dart';
import '../../data/repositories/airport_repository.dart';
import '../../data/repositories/level_repository.dart';
import '../widgets/radar_theme_dialog.dart';
import 'airport_select_screen.dart';
import 'atc_gameplay_screen.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = RadarThemeScope.of(context);
    final mumbai = AirportRepository.getAirportByCode('VABB');
    final progress = GameProgressManager();

    return Scaffold(
      backgroundColor: theme.airspaceBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Status Badge & Theme Button
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
                        'AIRPORTS AUTHORITY OF INDIA (ATC)',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: theme.accentColor, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const RadarThemeDialog(),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ],
              ),

              // Hero Title & Logo
              Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: theme.hudSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.accentColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.flight_takeoff,
                        color: theme.accentColor,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'INDIAN ATC',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AIRPORT RADAR & TRAFFIC CONTROLLER',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.hudSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.hudBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: theme.ilsConeColor),
                        const SizedBox(width: 6),
                        Text(
                          'CLASSIC INFINITE • 100 LEVELS • 3RD TAKEOFF RUNWAY',
                          style: TextStyle(
                            color: theme.ilsConeColor,
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Game Mode Selection Cards
              Column(
                children: [
                  // 1. CLASSIC GAME (INFINITE SURVIVAL)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AtcGameplayScreen(
                              airport: mumbai,
                              gameMode: GameMode.classic,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.all_inclusive_rounded, size: 24),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'CLASSIC GAME',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Infinite Planes • Scaling Difficulty',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: Colors.black.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (progress.classicHighScore > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BEST: ${progress.classicHighScore}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. LEVEL GAME (1 TO 100 LEVELS)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LevelSelectScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.grid_view_rounded, size: 22),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'LEVEL GAME (1 - 100)',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    '100 Missions • Easy to Hard',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LVL ${progress.highestUnlockedLevel}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. AIRPORT EXPLORER (FREE PLAY)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textPrimary,
                        side: BorderSide(color: theme.hudBorder, width: 1.4),
                        backgroundColor: theme.hudSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AirportSelectScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AIRPORT SELECT (FREE PLAY)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Footer
              Text(
                'Indian ATC v1.1 • Dual & Triple Runways • Catmull-Rom Smoothing',
                style: TextStyle(
                  color: theme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
