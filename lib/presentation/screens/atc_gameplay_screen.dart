import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/audio/atc_sound_manager.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/airport.dart';
import '../../data/models/level_data.dart';
import '../../data/repositories/airport_repository.dart';
import '../../data/repositories/level_repository.dart';
import '../../game/indian_atc_game.dart';
import '../widgets/atc_pause_dialog.dart';
import '../widgets/atc_tactical_bar.dart';
import '../widgets/landing_results_dialog.dart';
import '../widgets/radar_theme_dialog.dart';

class AtcGameplayScreen extends StatefulWidget {
  final AirportData airport;
  final GameMode gameMode;
  final LevelData? levelData;

  const AtcGameplayScreen({
    super.key,
    required this.airport,
    this.gameMode = GameMode.classic,
    this.levelData,
  });

  @override
  State<AtcGameplayScreen> createState() => _AtcGameplayScreenState();
}

class _AtcGameplayScreenState extends State<AtcGameplayScreen> {
  late IndianAtcGame _game;
  bool _isGameInitialized = false;
  bool _isPaused = false;
  double _gameSpeed = 1.0;

  final ValueNotifier<int> _currentLandings = ValueNotifier<int>(0);
  final ValueNotifier<int> _currentScore = ValueNotifier<int>(0);
  final ValueNotifier<String> _activeAtcBroadcast =
      ValueNotifier<String>('Bombay Approach, radar contact established.');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = RadarThemeScope.of(context);
    if (!_isGameInitialized) {
      _initializeGame(theme);
      _isGameInitialized = true;
    } else {
      _game.updateTheme(theme);
    }
  }

  @override
  void dispose() {
    _currentLandings.dispose();
    _currentScore.dispose();
    _activeAtcBroadcast.dispose();
    super.dispose();
  }

  void _initializeGame(RadarTheme theme) {
    _game = IndianAtcGame(
      airport: widget.airport,
      theme: theme,
      gameMode: widget.gameMode,
      levelData: widget.levelData,
      onStatsChanged: (landings, score) {
        _currentLandings.value = landings;
        _currentScore.value = score;
      },
      onAtcRadioBroadcast: (message) {
        _activeAtcBroadcast.value = message;
      },
      onGameOver: (reason) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResultsDialog(isVictory: false, reason: reason);
          }
        });
      },
      onLevelCompleted: (stars, finalScore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResultsDialog(
              isVictory: true,
              stars: stars,
              reason: widget.gameMode == GameMode.level
                  ? 'Sector mission objective achieved!'
                  : 'Outstanding radar control distinction!',
            );
          }
        });
      },
    );
    _game.setGameSpeed(_gameSpeed);
  }

  void _toggleSpeed() {
    setState(() {
      _gameSpeed = _gameSpeed == 1.0 ? 2.0 : 1.0;
      _game.setGameSpeed(_gameSpeed);
    });
    AtcSoundManager().playVectorAssigned();
  }

  void _togglePause() {
    if (_game.isGameOver) return;
    if (_isPaused) {
      _resumeGame();
    } else {
      _pauseGame();
    }
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
    });
    _game.pauseGame();
    _showPauseDialog();
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
    _game.resumeGame();
  }

  void _restartGame() {
    _currentLandings.value = 0;
    _currentScore.value = 0;
    _isPaused = false;
    final theme = RadarThemeScope.of(context);
    _initializeGame(theme);
    setState(() {});
  }

  void _showPauseDialog() {
    final theme = RadarThemeScope.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AtcPauseDialog(
        theme: theme,
        airport: widget.airport,
        landings: _currentLandings.value,
        score: _currentScore.value,
        activeAircraftCount: _game.aircraftList.length,
        onResume: () {
          Navigator.pop(ctx);
          _resumeGame();
        },
        onRestart: () {
          Navigator.pop(ctx);
          _restartGame();
        },
        onExit: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showResultsDialog({
    required bool isVictory,
    int stars = 3,
    required String reason,
  }) {
    final theme = RadarThemeScope.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LandingResultsDialog(
        theme: theme,
        gameMode: widget.gameMode,
        isVictory: isVictory,
        stars: stars,
        landings: _currentLandings.value,
        score: _currentScore.value,
        statusReason: reason,
        onRetry: () {
          Navigator.pop(ctx);
          _restartGame();
        },
        onNextStage: () {
          Navigator.pop(ctx);
          if (widget.gameMode == GameMode.level && widget.levelData != null) {
            final nextLvlNum = widget.levelData!.levelNumber + 1;
            if (nextLvlNum <= 100) {
              final nextLevel = LevelRepository.getLevel(nextLvlNum);
              final nextAirport = AirportRepository.getAirportByCode(nextLevel.airportCode);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AtcGameplayScreen(
                    airport: nextAirport,
                    gameMode: GameMode.level,
                    levelData: nextLevel,
                  ),
                ),
              );
            } else {
              Navigator.pop(context); // Campaign finished!
            }
          } else {
            final nextStageIndex = widget.airport.stageNumber;
            if (nextStageIndex < AirportRepository.stages.length) {
              final nextAirport = AirportRepository.stages[nextStageIndex];
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AtcGameplayScreen(airport: nextAirport),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }

  void _openThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const RadarThemeDialog(),
    ).then((_) {
      if (mounted) {
        final newTheme = RadarThemeScope.of(context);
        _game.updateTheme(newTheme);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = RadarThemeScope.of(context);
    final targetLandings = widget.levelData?.targetLandings ?? widget.airport.targetLandings;

    return Scaffold(
      backgroundColor: theme.airspaceBackground,
      body: Stack(
        children: [
          // 1. Central Flame Radar Canvas with Touch Gesture Routing
          Positioned.fill(
            child: GestureDetector(
              onPanDown: (details) {
                _game.handlePanDown(details.localPosition);
              },
              onPanUpdate: (details) {
                _game.handlePanUpdate(details.localPosition);
              },
              onPanEnd: (_) {
                _game.handlePanEnd();
              },
              child: GameWidget(game: _game),
            ),
          ),

          // 2. Top Tactical HUD Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentLandings,
              builder: (context, landings, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: _currentScore,
                  builder: (context, score, _) {
                    return AtcTacticalBar(
                      airport: widget.airport,
                      theme: theme,
                      gameMode: widget.gameMode,
                      levelNumber: widget.levelData?.levelNumber,
                      targetLandings: targetLandings,
                      currentLandings: landings,
                      currentScore: score,
                      gameSpeed: _gameSpeed,
                      isPaused: _isPaused,
                      onSpeedPressed: _toggleSpeed,
                      onPausePressed: _togglePause,
                      onThemePressed: _openThemeSelector,
                      onToggleLightDark: () {
                        final controller = RadarThemeScope.controllerOf(context);
                        controller.toggleLightDarkMode();
                        _game.updateTheme(controller.theme);
                        setState(() {});
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 3. Bottom-Left Fast-Forward Speed Button (Matches reference image)
          Positioned(
            bottom: 24,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleSpeed,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _gameSpeed > 1.0
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _gameSpeed > 1.0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        size: 18,
                        color: _gameSpeed > 1.0 ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _gameSpeed > 1.0 ? 'x2' : 'x1',
                        style: TextStyle(
                          color: _gameSpeed > 1.0 ? Colors.black : Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom-Right Quick Pause Button (Matches reference image)
          Positioned(
            bottom: 24,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePause,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isPaused
                        ? AtcColors.tcasWarningYellow.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPaused
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 24,
                    color: _isPaused ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 5. Paused Overlay Status Banner (when paused)
          if (_isPaused)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AtcColors.tcasWarningYellow.withValues(alpha: 0.8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_outline_rounded,
                        color: AtcColors.tcasWarningYellow,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AIRSPACE ON HOLD',
                        style: TextStyle(
                          color: AtcColors.tcasWarningYellow,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
