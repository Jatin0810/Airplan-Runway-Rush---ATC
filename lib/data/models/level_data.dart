import 'aircraft.dart';

enum GameMode {
  classic,
  level,
}

class LevelData {
  final int levelNumber; // 1 to 100
  final String title;
  final String description;
  final String airportCode;
  final int targetLandings;
  final double spawnInterval;
  final int maxSimultaneousAircraft;
  final bool hasTakeoffRunway;
  final double takeoffInterval;
  final List<AircraftCategory> allowedCategories;
  final double windHeadingDeg;
  final double windSpeedKnots;

  const LevelData({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.airportCode,
    required this.targetLandings,
    required this.spawnInterval,
    required this.maxSimultaneousAircraft,
    this.hasTakeoffRunway = false,
    this.takeoffInterval = 22.0,
    required this.allowedCategories,
    required this.windHeadingDeg,
    required this.windSpeedKnots,
  });
}

