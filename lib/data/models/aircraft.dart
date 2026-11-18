import 'package:flutter/material.dart';

enum AircraftCategory {
  narrowBody,
  wideBodyHeavy,
  turboprop,
  helicopter,
  militaryFighter, // Indian Air Force (IAF) Fighter Jet
}

enum AircraftFlightState {
  airborne,
  followingPath,
  ilsLocalizerCapture,
  landingRollout, // Rolling down the runway, decelerating
  landed,
  takingOff, // Rolling down the takeoff runway, accelerating
  departing, // Airborne outbound, climbing out towards airspace boundary
  crashed,
}

class AircraftModel {
  final String id;
  final String callsign;
  final String flightNumber;
  final String airlineName;
  final String aircraftType;
  final AircraftCategory category;
  
  Offset position;
  double heading; // In radians
  double speed; // In px per second
  final double maxTurnRate; // Max angular change per second in radians
  final double wingspan; // In px for realistic proportions
  final Color primaryColor;
  final Color secondaryColor;
  
  String assignedRunway;
  List<Offset> path;
  AircraftFlightState state;
  bool tcasAlert;
  
  /// True if the assigned route matches a valid landing approach (colored green).
  /// False if it's a neutral/holding vector (colored white).
  bool isLandingRoute;

  /// True when the drawn path has reached and locked onto the runway threshold.
  bool isLockedToRunway;

  /// True if this is an outbound departure aircraft taking off from the 3rd runway
  final bool isDeparture;

  /// Rollout physics parameters
  double rolloutTraveled;
  double rolloutTotalDistance;
  double rolloutSpeed;
  double opacity;

  AircraftModel({
    required this.id,
    required this.callsign,
    required this.flightNumber,
    required this.airlineName,
    required this.aircraftType,
    required this.category,
    required this.position,
    required this.heading,
    required this.speed,
    required this.maxTurnRate,
    required this.wingspan,
    required this.primaryColor,
    required this.secondaryColor,
    required this.assignedRunway,
    List<Offset>? path,
    this.state = AircraftFlightState.airborne,
    this.tcasAlert = false,
    this.isLandingRoute = false,
    this.isLockedToRunway = false,
    this.isDeparture = false,
    this.rolloutTraveled = 0.0,
    this.rolloutTotalDistance = 140.0,
    this.rolloutSpeed = 65.0,
    this.opacity = 1.0,
  }) : path = path ?? [];

  bool get isHelicopter => category == AircraftCategory.helicopter;
  bool get isFighterJet => category == AircraftCategory.militaryFighter;
  bool get isTurboprop => category == AircraftCategory.turboprop;
  bool get isWideBody => category == AircraftCategory.wideBodyHeavy;
}
