import 'dart:convert';
import 'dart:io';
import '../models/aircraft.dart';
import '../models/level_data.dart';

class LevelRepository {
  static final List<LevelData> levels = _generate100Levels();

  static LevelData getLevel(int levelNumber) {
    if (levelNumber < 1) return levels.first;
    if (levelNumber > 100) return levels.last;
    return levels[levelNumber - 1];
  }

  static List<LevelData> _generate100Levels() {
    final List<LevelData> list = [];
    final airportCodes = ['VASU', 'VAAH', 'VABB', 'VAPO', 'VOBL'];

    for (int lvl = 1; lvl <= 100; lvl++) {
      final code = airportCodes[(lvl - 1) % airportCodes.length];

      // Progressive Target Landings: 5 at lvl 1 -> 50 at lvl 100
      final target = 4 + (lvl * 0.46).round();

      // Progressive Spawn Interval: 8.5s down to 2.8s
      final spawnInterval = (8.5 - (lvl / 100.0) * 5.6).clamp(2.8, 8.5);

      // Progressive Max Simultaneous Planes: 3 up to 9
      final maxPlanes = (3 + (lvl / 15.0).floor()).clamp(3, 9);

      // 3rd Runway for Take-Off is enabled from Level 12 onwards on alternate / milestone levels
      final hasTakeoff = lvl >= 12 && (lvl % 2 == 0 || lvl >= 45);
      final takeoffInterval = (26.0 - (lvl / 100.0) * 12.0).clamp(14.0, 26.0);

      // Allowed Aircraft Categories expand with levels
      final categories = <AircraftCategory>[
        AircraftCategory.narrowBody,
        AircraftCategory.turboprop,
      ];
      if (lvl >= 4) {
        categories.add(AircraftCategory.helicopter);
      }
      if (lvl >= 16) {
        categories.add(AircraftCategory.wideBodyHeavy);
      }
      if (lvl >= 24) {
        categories.add(AircraftCategory.militaryFighter);
      }

      // Wind conditions
      final windHeading = (lvl * 37) % 360;
      final windSpeed = 6.0 + (lvl * 0.22);

      String title;
      String desc;

      if (lvl <= 10) {
        title = 'Cadet Vector $lvl: Airspace Basics';
        desc = 'Clear basic arrivals onto active runway. Keep clean radar separation.';
      } else if (lvl <= 25) {
        title = 'Radar Sector $lvl: ${hasTakeoff ? "Takeoff Active" : "Mixed Traffic"}';
        desc = hasTakeoff
            ? '3rd Runway active for departures! Vector climbing traffic clear of incoming jets.'
            : 'Handle incoming turboprops and commercial narrowbodies.';
      } else if (lvl <= 50) {
        title = 'TRACON Ops $lvl: ${hasTakeoff ? "Dual Arrival + Departures" : "High Density"}';
        desc = 'Heavy widebodies and IAF fighters entering sector. Coordinate multi-runway flow.';
      } else if (lvl <= 75) {
        title = 'Monsoon Surge $lvl: Airspace Saturation';
        desc = 'Relentless arrivals and rapid takeoffs. Vector departures safely out of bounds.';
      } else {
        title = 'Master Controller $lvl: Sky Command';
        desc = 'Peak rush hour crisis! Maximum traffic throughput and departure sequencing.';
      }

      list.add(
        LevelData(
          levelNumber: lvl,
          title: title,
          description: desc,
          airportCode: code,
          targetLandings: target,
          spawnInterval: spawnInterval,
          maxSimultaneousAircraft: maxPlanes,
          hasTakeoffRunway: hasTakeoff,
          takeoffInterval: takeoffInterval,
          allowedCategories: categories,
          windHeadingDeg: windHeading.toDouble(),
          windSpeedKnots: windSpeed,
        ),
      );
    }
    return list;
  }
}

/// Global Game Progress & High Score Persistence Manager
class GameProgressManager {
  static final GameProgressManager _instance = GameProgressManager._internal();
  factory GameProgressManager() => _instance;
  GameProgressManager._internal() {
    _loadProgress();
  }

  int _highestUnlockedLevel = 1;
  final Map<int, int> _levelStars = {};
  int _classicHighScore = 0;
  int _classicMaxLandings = 0;

  int get highestUnlockedLevel => _highestUnlockedLevel;
  int get classicHighScore => _classicHighScore;
  int get classicMaxLandings => _classicMaxLandings;

  int getStarsForLevel(int level) => _levelStars[level] ?? 0;
  bool isLevelUnlocked(int level) => level <= _highestUnlockedLevel;

  void completeLevel(int level, int stars, int score) {
    final prevStars = _levelStars[level] ?? 0;
    if (stars > prevStars) {
      _levelStars[level] = stars;
    }
    if (level >= _highestUnlockedLevel && _highestUnlockedLevel < 100) {
      _highestUnlockedLevel = level + 1;
    }
    _saveProgress();
  }

  void recordClassicScore(int score, int landings) {
    bool changed = false;
    if (score > _classicHighScore) {
      _classicHighScore = score;
      changed = true;
    }
    if (landings > _classicMaxLandings) {
      _classicMaxLandings = landings;
      changed = true;
    }
    if (changed) {
      _saveProgress();
    }
  }

  File? _getStorageFile() {
    try {
      final dir = Directory.systemTemp;
      return File('${dir.path}/indian_atc_progress.json');
    } catch (_) {
      return null;
    }
  }

  void _loadProgress() {
    try {
      final file = _getStorageFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = jsonDecode(content);
        _highestUnlockedLevel = data['highestUnlockedLevel'] ?? 1;
        _classicHighScore = data['classicHighScore'] ?? 0;
        _classicMaxLandings = data['classicMaxLandings'] ?? 0;

        if (data['levelStars'] is Map) {
          (data['levelStars'] as Map).forEach((k, v) {
            final lvl = int.tryParse(k.toString());
            final star = int.tryParse(v.toString());
            if (lvl != null && star != null) {
              _levelStars[lvl] = star;
            }
          });
        }
      }
    } catch (_) {
      // Gracefully fall back to memory
    }
  }

  void _saveProgress() {
    try {
      final file = _getStorageFile();
      if (file != null) {
        final data = {
          'highestUnlockedLevel': _highestUnlockedLevel,
          'classicHighScore': _classicHighScore,
          'classicMaxLandings': _classicMaxLandings,
          'levelStars': _levelStars.map((k, v) => MapEntry(k.toString(), v)),
        };
        file.writeAsStringSync(jsonEncode(data));
      }
    } catch (_) {}
  }
}

