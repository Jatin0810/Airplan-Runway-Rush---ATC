import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/audio/atc_sound_manager.dart';
import '../../core/math/catmull_rom.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/aircraft.dart';
import '../../data/models/airport.dart';
import '../../data/models/level_data.dart';
import '../../data/repositories/level_repository.dart';
import 'components/aircraft_component.dart';
import 'components/airport_component.dart';
import 'components/flight_path_component.dart';
import 'controllers/wave_spawner.dart';

/// Central Flame game loop supporting:
/// 1. Classic Game Mode (Endless survival with infinite planes and dynamic difficulty)
/// 2. Level Game Mode (Levels 1 to 100 with targets, stars, and unlock progression)
/// 3. 3rd Runway for Take-Off & automatic departure management
/// 4. 1x / 2x Game Speed toggle
/// 5. Ultra-smooth silky vector path drawing matching the reference design
class IndianAtcGame extends FlameGame {
  final AirportData airport;
  final GameMode gameMode;
  final LevelData? levelData;
  RadarTheme theme;

  final void Function(int landings, int score) onStatsChanged;
  final void Function(String message) onAtcRadioBroadcast;
  final void Function(String reason) onGameOver;
  final void Function(int stars, int score) onLevelCompleted;

  late AirportComponent airportComponent;
  late FlightPathComponent pathComponent;
  late WaveSpawner spawner;

  final List<AircraftModel> aircraftList = [];
  final Map<String, AircraftComponent> aircraftComponents = {};

  AircraftModel? selectedAircraft;
  final List<Offset> activeDrawingPoints = [];
  bool isDrawing = false;
  bool isLiveDrawingMatchedLanding = false;

  int successfulLandings = 0;
  int currentScore = 0;
  bool isGameOver = false;
  bool isPaused = false;
  double gameSpeed = 1.0;
  double _tcasAudioCooldown = 0.0;

  final Random _random = Random();

  IndianAtcGame({
    required this.airport,
    required this.theme,
    this.gameMode = GameMode.classic,
    this.levelData,
    required this.onStatsChanged,
    required this.onAtcRadioBroadcast,
    required this.onGameOver,
    required this.onLevelCompleted,
  });

  @override
  Color backgroundColor() => theme.airspaceBackground;

  void toggleGameSpeed() {
    gameSpeed = gameSpeed == 1.0 ? 2.0 : 1.0;
  }

  void setGameSpeed(double speed) {
    gameSpeed = speed;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final center = size / 2;

    // 1. Airport Geometry Component
    airportComponent = AirportComponent(
      airport: airport,
      theme: theme,
      position: center,
      viewportSize: size,
    );
    add(airportComponent);

    // 2. Flight Path Renderer Component (Ultra-smooth Spline Curves)
    pathComponent = FlightPathComponent(
      getAircraftList: () => aircraftList,
      getSelectedAircraft: () => selectedAircraft,
      getActiveDrawingPath: () => activeDrawingPoints,
      isCurrentPathLandingMatch: () => isLiveDrawingMatchedLanding,
      theme: theme,
    );
    add(pathComponent);

    // 3. Progressive Wave Spawner (Supports Level 1-100 & Infinite Classic)
    spawner = WaveSpawner(
      airport: airport,
      gameMode: gameMode,
      levelData: levelData,
      onDifficultyLevelUp: (level, title) {
        broadcastAndSpeak('SECTOR ALERT: $title');
        AtcSoundManager().playVectorAssigned();
      },
    );

    // Initial starting traffic
    _spawnRandomInitialAircraft();

    final modeTitle = gameMode == GameMode.level
        ? 'Level ${levelData?.levelNumber ?? 1}: ${airport.iata} Radar Contact.'
        : 'Classic Airspace: Bombay Radar Contact. Infinite sector active.';
    broadcastAndSpeak(modeTitle);
  }

  void broadcastAndSpeak(String message, {bool speak = true}) {
    onAtcRadioBroadcast(message);
    if (speak) {
      AtcSoundManager().speakAtcCallout(message);
    }
  }

  /// Generates completely unique, randomized starting positions along the airspace boundary
  void _spawnRandomInitialAircraft() {
    // 1. Initial Commercial Jet
    final edge1 = _random.nextInt(2);
    final startX1 = edge1 == 0 ? _random.nextDouble() * size.x * 0.6 + 20 : -15.0;
    final startY1 = edge1 == 0 ? -15.0 : _random.nextDouble() * size.y * 0.4 + 40;
    final heading1 = atan2(size.y / 2 - startY1, size.x / 2 - startX1) +
        (_random.nextDouble() - 0.5) * 0.3;

    final plane1 = AircraftModel(
      id: '6E-${100 + _random.nextInt(899)}',
      callsign: 'IndiGo',
      flightNumber: '6E ${100 + _random.nextInt(899)}',
      airlineName: 'IndiGo',
      aircraftType: 'A320',
      category: AircraftCategory.narrowBody,
      position: Offset(startX1, startY1),
      heading: heading1,
      speed: 44.0,
      maxTurnRate: 1.6,
      wingspan: 26.0,
      primaryColor: AtcColors.indigoBlue,
      secondaryColor: AtcColors.indigoAccent,
      assignedRunway: airport.activeRunwayId,
    );
    addAircraft(plane1);

    // 2. Initial Helicopter (if airport has helipad and level permits)
    final canHelo = levelData == null ||
        levelData!.allowedCategories.contains(AircraftCategory.helicopter);
    if (airport.helipads.isNotEmpty && canHelo) {
      final edge2 = _random.nextInt(2);
      final startX2 = edge2 == 0 ? size.x + 15 : _random.nextDouble() * size.x * 0.5 + size.x * 0.4;
      final startY2 = edge2 == 0 ? _random.nextDouble() * size.y * 0.5 + size.y * 0.4 : size.y + 15;
      final heading2 = atan2(size.y / 2 - startY2, size.x / 2 - startX2) +
          (_random.nextDouble() - 0.5) * 0.3;

      final helo = AircraftModel(
        id: 'PH-${10 + _random.nextInt(89)}',
        callsign: 'Pawan Hans',
        flightNumber: 'VT-PH${_random.nextInt(9)}',
        airlineName: 'Pawan Hans',
        aircraftType: 'Copter',
        category: AircraftCategory.helicopter,
        position: Offset(startX2, startY2),
        heading: heading2,
        speed: 24.0,
        maxTurnRate: 4.5,
        wingspan: 18.0,
        primaryColor: AtcColors.pawanHansOrange,
        secondaryColor: AtcColors.helicopterWhite,
        assignedRunway: 'H1',
        rolloutTotalDistance: 10.0,
      );
      addAircraft(helo);
    }
  }

  void addAircraft(AircraftModel model) {
    aircraftList.add(model);
    final comp = AircraftComponent(
      model: model,
      theme: theme,
      onRolloutCompleted: (plane) {
        _finalizeLandingSuccess(plane);
      },
    );
    aircraftComponents[model.id] = comp;
    add(comp);
  }

  void removeAircraft(AircraftModel model) {
    aircraftList.remove(model);
    final comp = aircraftComponents.remove(model.id);
    if (comp != null) {
      remove(comp);
    }
  }

  void updateTheme(RadarTheme newTheme) {
    theme = newTheme;
    airportComponent.updateTheme(newTheme);
    pathComponent.updateTheme(newTheme);
    for (final comp in aircraftComponents.values) {
      comp.updateTheme(newTheme);
    }
  }

  void pauseGame() {
    isPaused = true;
    paused = true;
  }

  void resumeGame() {
    isPaused = false;
    paused = false;
  }

  @override
  void update(double dt) {
    final effectiveDt = dt * gameSpeed;
    super.update(effectiveDt);
    if (isGameOver || isPaused) return;

    if (_tcasAudioCooldown > 0) {
      _tcasAudioCooldown = max(0.0, _tcasAudioCooldown - effectiveDt);
    }

    // Spawner tick with active count (Supports Arrivals and 3rd Runway Departures)
    spawner.update(
      effectiveDt,
      Size(size.x, size.y),
      aircraftList.length,
      (newPlane) {
        addAircraft(newPlane);
        final arrivalMsg = AtcSoundManager().buildArrivalCallout(
          airline: newPlane.airlineName,
          flightNumber: newPlane.flightNumber,
        );
        broadcastAndSpeak(arrivalMsg);
      },
      onSpawnTakeoff: (departurePlane) {
        addAircraft(departurePlane);
        broadcastAndSpeak(
          'Departure: ${departurePlane.airlineName} ${departurePlane.flightNumber} taking off Runway ${departurePlane.assignedRunway}. Direct out of sector.',
        );
      },
    );

    _evaluateCollisionsAndProximity();
    _evaluateRunwayLandings(effectiveDt);
    _evaluateDeparturesExit();
  }

  void _evaluateCollisionsAndProximity() {
    bool hasActiveTcasWarning = false;

    for (int i = 0; i < aircraftList.length; i++) {
      aircraftList[i].tcasAlert = false;
      if (aircraftList[i].state == AircraftFlightState.landingRollout) continue;

      for (int j = i + 1; j < aircraftList.length; j++) {
        final p1 = aircraftList[i];
        final p2 = aircraftList[j];
        if (p2.state == AircraftFlightState.landingRollout) continue;

        final dist = (p1.position - p2.position).distance;

        // TCAS Warning (< 52 px)
        if (dist < 52.0) {
          p1.tcasAlert = true;
          p2.tcasAlert = true;
          hasActiveTcasWarning = true;

          // Fatal Mid-Air Collision (< 18 px)
          if (dist < 18.0) {
            _triggerCollision(p1, p2);
            return;
          }
        }
      }
    }

    // Throttle TCAS audible and haptic warnings so they don't fire every tick
    if (hasActiveTcasWarning && _tcasAudioCooldown <= 0.0) {
      AtcSoundManager().playTcasWarning();
      _tcasAudioCooldown = 1.8;
    }
  }

  void _triggerCollision(AircraftModel p1, AircraftModel p2) {
    isGameOver = true;
    p1.state = AircraftFlightState.crashed;
    p2.state = AircraftFlightState.crashed;
    AtcSoundManager().playTcasWarning();

    if (gameMode == GameMode.classic) {
      GameProgressManager().recordClassicScore(currentScore, successfulLandings);
    }

    final message = 'DISASTER! Collision between ${p1.flightNumber} and ${p2.flightNumber}. Airspace closed.';
    broadcastAndSpeak(message);
    onGameOver(message);
  }

  // --- Runway & Helipad Landing Target Calculations ---
  Offset getRunwayThresholdPoint(RunwayData rwy) {
    final airportCenter = Offset(size.x / 2, size.y / 2);
    final halfLen = rwy.lengthPixels / 2;
    final rad = rwy.headingDeg * (pi / 180.0);
    final isMain = rwy.id == '09/27';
    final sign = isMain ? 1.0 : -1.0;
    return airportCenter + rwy.centerOffset + Offset(cos(rad) * halfLen * sign, sin(rad) * halfLen * sign);
  }

  double getRunwayLandingHeading(RunwayData rwy) {
    final rad = rwy.headingDeg * (pi / 180.0);
    final isMain = rwy.id == '09/27';
    return isMain ? CatmullRomSplineUtil.normalizeAngle(rad + pi) : rad;
  }

  /// Checks if a touch position matches ANY valid arrival runway or helipad
  (bool isMatch, String targetId, Offset targetPos, double heading) evaluateLandingMatch(
    AircraftModel plane,
    Offset tipPos,
    double? approachHeading,
  ) {
    // Departure aircraft are outbound and CANNOT land on arrival runways!
    if (plane.isDeparture) {
      return (false, '', Offset.zero, 0.0);
    }

    final airportCenter = Offset(size.x / 2, size.y / 2);

    // 1. Helicopter Landing check on H1 or H2
    if (plane.isHelicopter) {
      for (final pad in airport.helipads) {
        final padPos = airportCenter + pad.offset;
        if ((tipPos - padPos).distance <= 28.0) {
          return (true, pad.id, padPos, 0.0);
        }
      }
      return (false, '', Offset.zero, 0.0);
    }

    // 2. Airplanes: Check against arrival runways (Takeoff runway is prohibited for landing)
    for (final rwy in airport.runways) {
      if (rwy.isTakeoffOnly) continue; // 3rd Take-Off runway strictly forbidden for landings!

      final thresholdPos = getRunwayThresholdPoint(rwy);
      final dist = (tipPos - thresholdPos).distance;

      if (dist <= 35.0) {
        // Enforce Runway Specialization
        if (!rwy.allowedCategories.contains(plane.category)) {
          return (false, '', Offset.zero, 0.0);
        }

        if (approachHeading != null) {
          final targetHeading = getRunwayLandingHeading(rwy);
          final diff = CatmullRomSplineUtil.normalizeAngle(approachHeading - targetHeading).abs();
          if (diff <= 0.90) {
            return (true, rwy.activeThresholdId, thresholdPos, targetHeading);
          }
        } else {
          return (true, rwy.activeThresholdId, thresholdPos, getRunwayLandingHeading(rwy));
        }
      }
    }

    return (false, '', Offset.zero, 0.0);
  }

  void _evaluateRunwayLandings(double dt) {
    final airportCenter = Offset(size.x / 2, size.y / 2);
    final toRemoveHelos = <AircraftModel>[];

    for (final plane in aircraftList) {
      if (plane.isDeparture) continue;

      // 1. Helicopter touchdown
      if (plane.isHelicopter) {
        for (final pad in airport.helipads) {
          final padWorldPos = airportCenter + pad.offset;
          if ((plane.position - padWorldPos).distance < 22.0) {
            plane.position = padWorldPos;
            final comp = aircraftComponents[plane.id];
            if (comp != null) {
              comp.position = Vector2(padWorldPos.dx, padWorldPos.dy);
            }
            _finalizeLandingSuccess(plane);
            toRemoveHelos.add(plane);
            break;
          }
        }
        continue;
      }

      // 2. Airplanes Touchdown -> Rollout
      if (plane.state != AircraftFlightState.landingRollout && plane.isLandingRoute) {
        for (final rwy in airport.runways) {
          if (rwy.isTakeoffOnly) continue;

          final thresholdPoint = getRunwayThresholdPoint(rwy);
          if ((plane.position - thresholdPoint).distance < 28.0) {
            plane.state = AircraftFlightState.landingRollout;
            plane.path.clear();

            plane.position = thresholdPoint;
            final comp = aircraftComponents[plane.id];
            if (comp != null) {
              comp.position = Vector2(thresholdPoint.dx, thresholdPoint.dy);
            }

            plane.heading = getRunwayLandingHeading(rwy);
            plane.rolloutSpeed = plane.speed;
            plane.rolloutTraveled = 0.0;
            plane.rolloutTotalDistance = rwy.id == '09/27' ? 180.0 : 140.0;

            AtcSoundManager().playTouchdownSuccess();
            final callout = AtcSoundManager().buildTouchdownCallout(
              airline: plane.airlineName,
              flightNumber: plane.flightNumber,
            );
            broadcastAndSpeak(callout);
            break;
          }
        }
      }
    }

    for (final h in toRemoveHelos) {
      removeAircraft(h);
    }
  }

  /// Evaluates 3rd Runway Departures exiting the airspace
  void _evaluateDeparturesExit() {
    final toRemoveDepartures = <AircraftModel>[];

    for (final plane in aircraftList) {
      if (plane.isDeparture && plane.state == AircraftFlightState.departing) {
        // If plane exits screen bounds safely, award success!
        const margin = 35.0;
        final isOffScreen = plane.position.dx < -margin ||
            plane.position.dx > size.x + margin ||
            plane.position.dy < -margin ||
            plane.position.dy > size.y + margin;

        if (isOffScreen) {
          toRemoveDepartures.add(plane);
        }
      }
    }

    for (final dep in toRemoveDepartures) {
      removeAircraft(dep);
      successfulLandings++;
      currentScore += 250;
      spawner.onLandingRecorded(successfulLandings);
      onStatsChanged(successfulLandings, currentScore);

      AtcSoundManager().playTouchdownSuccess();
      broadcastAndSpeak(
        '${dep.airlineName} ${dep.flightNumber}, leaving sector. Radar service terminated.',
        speak: false,
      );

      _checkVictoryCondition();
    }
  }

  void _finalizeLandingSuccess(AircraftModel plane) {
    removeAircraft(plane);

    successfulLandings++;
    final bonus = plane.isFighterJet
        ? 300
        : (plane.category == AircraftCategory.wideBodyHeavy ? 250 : 150);
    currentScore += bonus;

    AtcSoundManager().playTouchdownSuccess();
    spawner.onLandingRecorded(successfulLandings);
    onStatsChanged(successfulLandings, currentScore);

    _checkVictoryCondition();
  }

  void _checkVictoryCondition() {
    if (gameMode == GameMode.level && !isGameOver) {
      final target = levelData?.targetLandings ?? airport.targetLandings;
      if (successfulLandings >= target) {
        isGameOver = true;
        final lvl = levelData?.levelNumber ?? 1;
        final stars = currentScore >= (target * 180) ? 3 : 2;
        GameProgressManager().completeLevel(lvl, stars, currentScore);
        onLevelCompleted(stars, currentScore);
      }
    } else if (gameMode == GameMode.classic) {
      // In Classic mode, continuously track high score
      GameProgressManager().recordClassicScore(currentScore, successfulLandings);
    }
  }

  // --- Real-time Interactive Route Drawing ---
  void handlePanDown(Offset screenPos) {
    if (isGameOver || isPaused) return;

    for (final plane in aircraftList) {
      if (plane.state == AircraftFlightState.landingRollout ||
          plane.state == AircraftFlightState.takingOff) {
        continue;
      }

      final dist = (plane.position - screenPos).distance;
      if (dist < max(plane.wingspan * 2.4, 32.0)) {
        selectedAircraft = plane;
        final comp = aircraftComponents[plane.id];
        comp?.isSelected = true;

        isDrawing = true;
        isLiveDrawingMatchedLanding = false;
        selectedAircraft!.isLockedToRunway = false;
        selectedAircraft!.isLandingRoute = false;

        selectedAircraft!.path.clear();
        selectedAircraft!.state = AircraftFlightState.followingPath;

        activeDrawingPoints.clear();
        activeDrawingPoints.add(plane.position);

        AtcSoundManager().playAircraftSelected();
        onAtcRadioBroadcast('${plane.airlineName} ${plane.flightNumber}, route initiated.');
        return;
      }
    }
  }

  void handlePanUpdate(Offset screenPos) {
    if (isGameOver || isPaused) return;
    if (!isDrawing || selectedAircraft == null) return;
    if (selectedAircraft!.isLockedToRunway) return;

    final last = activeDrawingPoints.last;
    // Minimum 10px spacing prevents micro-tremor jitter
    if ((screenPos - last).distance < 10.0) return;

    final approachHeading = atan2(screenPos.dy - last.dy, screenPos.dx - last.dx);
    final (isMatch, targetId, targetPos, _) =
        evaluateLandingMatch(selectedAircraft!, screenPos, approachHeading);

    if (isMatch) {
      activeDrawingPoints.add(targetPos);
      selectedAircraft!.path.add(targetPos);

      selectedAircraft!.assignedRunway = targetId;
      selectedAircraft!.isLockedToRunway = true;
      selectedAircraft!.isLandingRoute = true;
      isLiveDrawingMatchedLanding = true;

      AtcSoundManager().playVectorAssigned();

      final clearance = AtcSoundManager().buildClearanceCallout(
        airline: selectedAircraft!.airlineName,
        flightNumber: selectedAircraft!.flightNumber,
        runway: targetId,
      );
      broadcastAndSpeak(clearance);
      return;
    }

    isLiveDrawingMatchedLanding = false;
    activeDrawingPoints.add(screenPos);
    selectedAircraft!.path.add(screenPos);
  }

  void handlePanEnd() {
    if (isGameOver || isPaused) return;
    if (isDrawing && selectedAircraft != null) {
      if (selectedAircraft!.path.isNotEmpty) {
        if (selectedAircraft!.isLockedToRunway) {
          selectedAircraft!.isLandingRoute = true;
        } else if (!selectedAircraft!.isDeparture) {
          final last = selectedAircraft!.path.last;
          final prev = selectedAircraft!.path.length > 1
              ? selectedAircraft!.path[selectedAircraft!.path.length - 2]
              : selectedAircraft!.position;
          final approachHeading = (last == prev) ? null : atan2(last.dy - prev.dy, last.dx - prev.dx);
          final (matches, targetId, _, _) = evaluateLandingMatch(selectedAircraft!, last, approachHeading);

          selectedAircraft!.isLandingRoute = matches;
          if (matches) {
            selectedAircraft!.assignedRunway = targetId;
          }
        }

        // Apply Catmull-Rom spline curve smoothing for silky smooth aeronautical lines
        if (selectedAircraft!.path.length > 2) {
          final smoothed = CatmullRomSplineUtil.smoothPoints(
            selectedAircraft!.path,
            subdivisions: 5,
            minDistance: 12.0,
          );
          selectedAircraft!.path = List<Offset>.from(smoothed);
        }

        if (selectedAircraft!.isLandingRoute) {
          AtcSoundManager().playVectorAssigned();
        }
      }

      final comp = aircraftComponents[selectedAircraft!.id];
      comp?.isSelected = false;

      isDrawing = false;
      isLiveDrawingMatchedLanding = false;
      selectedAircraft = null;
      activeDrawingPoints.clear();
    }
  }
}
