import 'package:flutter_test/flutter_test.dart';
import 'package:indian_atc/core/theme/radar_theme.dart';
import 'package:indian_atc/data/models/level_data.dart';
import 'package:indian_atc/data/repositories/airport_repository.dart';
import 'package:indian_atc/data/repositories/level_repository.dart';
import 'package:indian_atc/game/indian_atc_game.dart';

void main() {
  test('IndianAtcGame pause and speed toggle test', () {
    final airport = AirportRepository.stages.first;
    const theme = DaylightSatelliteRadarTheme();

    final game = IndianAtcGame(
      airport: airport,
      theme: theme,
      gameMode: GameMode.classic,
      onStatsChanged: (_, __) {},
      onAtcRadioBroadcast: (_) {},
      onGameOver: (_) {},
      onLevelCompleted: (_, __) {},
    );

    expect(game.isPaused, isFalse);
    expect(game.paused, isFalse);
    expect(game.gameSpeed, 1.0);

    game.toggleGameSpeed();
    expect(game.gameSpeed, 2.0);

    game.toggleGameSpeed();
    expect(game.gameSpeed, 1.0);

    game.pauseGame();
    expect(game.isPaused, isTrue);
    expect(game.paused, isTrue);

    game.resumeGame();
    expect(game.isPaused, isFalse);
    expect(game.paused, isFalse);
  });

  test('LevelRepository has 100 levels with progressive difficulty', () {
    expect(LevelRepository.levels.length, 100);

    final lvl1 = LevelRepository.getLevel(1);
    final lvl100 = LevelRepository.getLevel(100);

    expect(lvl1.targetLandings, lessThan(lvl100.targetLandings));
    expect(lvl1.spawnInterval, greaterThan(lvl100.spawnInterval));
    expect(lvl1.maxSimultaneousAircraft, lessThan(lvl100.maxSimultaneousAircraft));
  });
}
