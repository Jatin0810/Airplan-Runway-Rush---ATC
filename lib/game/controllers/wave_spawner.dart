import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/atc_colors.dart';
import '../../data/models/aircraft.dart';
import '../../data/models/airport.dart';
import '../../data/models/level_data.dart';

/// Manages dynamic difficulty progression, supporting both Classic (Infinite)
/// and Level (1-100) modes, with automatic Take-Off scheduling from the 3rd runway.
class WaveSpawner {
  final AirportData airport;
  final GameMode gameMode;
  final LevelData? levelData;
  final void Function(int level, String title) onDifficultyLevelUp;

  final Random _random = Random();
  double _timer = 0.0;
  double _takeoffTimer = 0.0;
  int _flightCounter = 100;

  int _currentLevel = 1;
  int _landingsCount = 0;

  WaveSpawner({
    required this.airport,
    this.gameMode = GameMode.classic,
    this.levelData,
    required this.onDifficultyLevelUp,
  }) {
    if (gameMode == GameMode.level && levelData != null) {
      _currentLevel = levelData!.levelNumber;
    }
  }

  int get currentLevel => _currentLevel;

  bool get hasTakeoffRunway =>
      (levelData?.hasTakeoffRunway ?? false) || airport.hasTakeoffRunway;

  double get takeoffInterval => levelData?.takeoffInterval ?? 22.0;

  void onLandingRecorded(int totalLandings) {
    _landingsCount = totalLandings;
    if (gameMode == GameMode.level) return;

    final previousLevel = _currentLevel;

    // Classic Mode: Continuous progressive difficulty with no upper bound
    if (_landingsCount >= 50) {
      _currentLevel = 8; // Ultra Extreme Mastery
    } else if (_landingsCount >= 40) {
      _currentLevel = 7;
    } else if (_landingsCount >= 30) {
      _currentLevel = 6;
    } else if (_landingsCount >= 22) {
      _currentLevel = 5; // Rush Hour Survival
    } else if (_landingsCount >= 15) {
      _currentLevel = 4; // High-Density Airspace
    } else if (_landingsCount >= 9) {
      _currentLevel = 3; // Heavy Air Traffic + IAF Fighter Jets
    } else if (_landingsCount >= 4) {
      _currentLevel = 2; // Moderate Traffic + Helicopters
    } else {
      _currentLevel = 1; // Easy Training
    }

    if (_currentLevel > previousLevel) {
      final title = _getLevelTitle(_currentLevel);
      onDifficultyLevelUp(_currentLevel, title);
    }
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Sector Stage 1: Cadet Orientation';
      case 2:
        return 'Sector Stage 2: Turboprops & Helicopters';
      case 3:
        return 'Sector Stage 3: IAF Supersonic Fighters';
      case 4:
        return 'Sector Stage 4: High-Density Arrival Stream';
      case 5:
        return 'Sector Stage 5: Heavy B777 Operations';
      case 6:
        return 'Sector Stage 6: Rush Hour Saturation';
      case 7:
        return 'Sector Stage 7: Severe Airspace Congestion';
      case 8:
      default:
        return 'Sector Stage $level: Sky Command Overload';
    }
  }

  double get _spawnInterval {
    if (gameMode == GameMode.level && levelData != null) {
      return levelData!.spawnInterval;
    }
    switch (_currentLevel) {
      case 1:
        return 7.5;
      case 2:
        return 6.2;
      case 3:
        return 5.2;
      case 4:
        return 4.4;
      case 5:
        return 3.8;
      case 6:
        return 3.2;
      case 7:
        return 2.9;
      case 8:
      default:
        return 2.6;
    }
  }

  int get _maxSimultaneousAircraft {
    if (gameMode == GameMode.level && levelData != null) {
      return levelData!.maxSimultaneousAircraft;
    }
    switch (_currentLevel) {
      case 1:
        return 3;
      case 2:
        return 4;
      case 3:
        return 5;
      case 4:
        return 6;
      case 5:
        return 7;
      case 6:
        return 8;
      case 7:
        return 9;
      case 8:
      default:
        return 10;
    }
  }

  void update(
    double dt,
    Size bounds,
    int currentActiveCount,
    Function(AircraftModel) onSpawnArrival, {
    Function(AircraftModel)? onSpawnTakeoff,
  }) {
    _timer += dt;

    if (currentActiveCount < _maxSimultaneousAircraft && _timer >= _spawnInterval) {
      _timer = 0.0;
      final newPlane = _generateAircraft(bounds);
      onSpawnArrival(newPlane);
    }

    // 3rd Runway Take-Off Departures Scheduling
    if (hasTakeoffRunway && onSpawnTakeoff != null) {
      _takeoffTimer += dt;
      if (_takeoffTimer >= takeoffInterval) {
        _takeoffTimer = 0.0;
        final takeoffRunway = airport.runways.firstWhere(
          (r) => r.isTakeoffOnly,
          orElse: () => airport.runways.first,
        );
        final departurePlane = _generateTakeoffAircraft(
          takeoffRunway,
          Offset(bounds.width / 2, bounds.height / 2),
        );
        onSpawnTakeoff(departurePlane);
      }
    }
  }

  AircraftModel _generateTakeoffAircraft(RunwayData rwy, Offset airportCenter) {
    _flightCounter++;
    final rad = rwy.headingDeg * (pi / 180.0);
    final halfLen = rwy.lengthPixels / 2;
    // Launch threshold is at -halfLen along the runway heading
    final thresholdPos = airportCenter +
        rwy.centerOffset -
        Offset(cos(rad) * (halfLen - 12), sin(rad) * (halfLen - 12));

    final airlines = [
      (
        'IndiGo',
        '6E ${200 + _random.nextInt(699)}',
        'A320',
        AircraftCategory.narrowBody,
        AtcColors.indigoBlue,
        AtcColors.indigoAccent,
      ),
      (
        'Air India',
        'AI ${100 + _random.nextInt(499)}',
        'A321',
        AircraftCategory.narrowBody,
        AtcColors.airIndiaRed,
        AtcColors.airIndiaGold,
      ),
      (
        'SpiceJet',
        'SG ${400 + _random.nextInt(399)}',
        'Q400',
        AircraftCategory.turboprop,
        AtcColors.spiceJetOrange,
        AtcColors.spiceJetYellow,
      ),
    ];
    final selected = airlines[_random.nextInt(airlines.length)];

    return AircraftModel(
      id: 'DEP-$_flightCounter',
      callsign: selected.$1,
      flightNumber: selected.$2,
      airlineName: selected.$1,
      aircraftType: selected.$3,
      category: selected.$4,
      position: thresholdPos,
      heading: rad,
      speed: 46.0,
      maxTurnRate: 1.6,
      wingspan: 26.0,
      primaryColor: selected.$5,
      secondaryColor: selected.$6,
      assignedRunway: rwy.id,
      state: AircraftFlightState.takingOff,
      isDeparture: true,
      rolloutSpeed: 20.0,
      rolloutTotalDistance: rwy.lengthPixels * 0.85,
    );
  }

  AircraftModel _generateAircraft(Size bounds) {
    _flightCounter++;
    final edge = _random.nextInt(4); // 0: Top, 1: Right, 2: Bottom, 3: Left
    double startX = 0;
    double startY = 0;

    switch (edge) {
      case 0:
        startX = bounds.width * 0.15 + _random.nextDouble() * bounds.width * 0.70;
        startY = -14;
        break;
      case 1:
        startX = bounds.width + 14;
        startY = bounds.height * 0.15 + _random.nextDouble() * bounds.height * 0.70;
        break;
      case 2:
        startX = bounds.width * 0.15 + _random.nextDouble() * bounds.width * 0.70;
        startY = bounds.height + 14;
        break;
      case 3:
        startX = -14;
        startY = bounds.height * 0.15 + _random.nextDouble() * bounds.height * 0.70;
        break;
    }

    final centerX = bounds.width / 2;
    final centerY = bounds.height / 2;
    final targetHeading = atan2(centerY - startY, centerX - startX) +
        (_random.nextDouble() - 0.5) * 0.30;

    final roll = _random.nextDouble();

    // Check allowed categories if in level mode
    final allowed = levelData?.allowedCategories;
    bool canSpawnCategory(AircraftCategory cat) =>
        allowed == null || allowed.contains(cat);

    // 1. Helicopters
    if (airport.helipads.isNotEmpty &&
        canSpawnCategory(AircraftCategory.helicopter) &&
        roll < 0.20) {
      return AircraftModel(
        id: 'PH-$_flightCounter',
        callsign: 'Pawan Hans',
        flightNumber: 'VT-PW$_flightCounter',
        airlineName: 'Pawan Hans',
        aircraftType: 'Copter',
        category: AircraftCategory.helicopter,
        position: Offset(startX, startY),
        heading: targetHeading,
        speed: 24.0,
        maxTurnRate: 4.5,
        wingspan: 18.0,
        primaryColor: AtcColors.pawanHansOrange,
        secondaryColor: AtcColors.helicopterWhite,
        assignedRunway: 'H1',
        rolloutTotalDistance: 10.0,
      );
    }

    // 2. IAF Fighter Jets
    if (canSpawnCategory(AircraftCategory.militaryFighter) &&
        (_currentLevel >= 3 || (levelData?.levelNumber ?? 0) >= 20) &&
        roll >= 0.20 &&
        roll < 0.38) {
      return AircraftModel(
        id: 'IAF-$_flightCounter',
        callsign: 'IAF Garuda',
        flightNumber: 'IAF $_flightCounter',
        airlineName: 'Indian Air Force',
        aircraftType: 'SU-30',
        category: AircraftCategory.militaryFighter,
        position: Offset(startX, startY),
        heading: targetHeading,
        speed: 62.0,
        maxTurnRate: 2.0,
        wingspan: 22.0,
        primaryColor: const Color(0xFF64748B),
        secondaryColor: const Color(0xFFFF9933),
        assignedRunway: airport.activeRunwayId,
        rolloutTotalDistance: 160.0,
        rolloutSpeed: 62.0,
      );
    }

    // 3. Widebody Heavy B777
    if (canSpawnCategory(AircraftCategory.wideBodyHeavy) &&
        (_currentLevel >= 2 || (levelData?.levelNumber ?? 0) >= 15) &&
        roll >= 0.38 &&
        roll < 0.56) {
      return AircraftModel(
        id: 'AI-$_flightCounter',
        callsign: 'Air India',
        flightNumber: 'AI $_flightCounter',
        airlineName: 'Air India',
        aircraftType: 'B777',
        category: AircraftCategory.wideBodyHeavy,
        position: Offset(startX, startY),
        heading: targetHeading,
        speed: 48.0,
        maxTurnRate: 1.15,
        wingspan: 32.0,
        primaryColor: AtcColors.airIndiaRed,
        secondaryColor: AtcColors.airIndiaGold,
        assignedRunway: '27',
        rolloutTotalDistance: 180.0,
        rolloutSpeed: 48.0,
      );
    }

    // 4. Turboprops (SpiceJet Q400)
    if (canSpawnCategory(AircraftCategory.turboprop) &&
        roll >= 0.56 &&
        roll < 0.76) {
      return AircraftModel(
        id: 'SG-$_flightCounter',
        callsign: 'SpiceJet',
        flightNumber: 'SG $_flightCounter',
        airlineName: 'SpiceJet',
        aircraftType: 'Q400',
        category: AircraftCategory.turboprop,
        position: Offset(startX, startY),
        heading: targetHeading,
        speed: 36.0,
        maxTurnRate: 2.4,
        wingspan: 24.0,
        primaryColor: AtcColors.spiceJetOrange,
        secondaryColor: AtcColors.spiceJetYellow,
        assignedRunway: airport.activeRunwayId,
        rolloutTotalDistance: 120.0,
        rolloutSpeed: 36.0,
      );
    }

    // 5. Commercial Narrowbody (IndiGo A320)
    return AircraftModel(
      id: '6E-$_flightCounter',
      callsign: 'IndiGo',
      flightNumber: '6E $_flightCounter',
      airlineName: 'IndiGo',
      aircraftType: 'A320',
      category: AircraftCategory.narrowBody,
      position: Offset(startX, startY),
      heading: targetHeading,
      speed: 44.0,
      maxTurnRate: 1.6,
      wingspan: 26.0,
      primaryColor: AtcColors.indigoBlue,
      secondaryColor: AtcColors.indigoAccent,
      assignedRunway: airport.activeRunwayId,
      rolloutTotalDistance: 140.0,
      rolloutSpeed: 44.0,
    );
  }
}
