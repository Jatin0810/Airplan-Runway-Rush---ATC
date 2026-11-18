import 'package:flutter/material.dart';
import 'aircraft.dart';

class RunwayData {
  final String id; // e.g. "09/27"
  final String activeThresholdId; // e.g. "27"
  final double headingDeg; // Magnetic heading, e.g. 90.0 for 09/27
  final double lengthMeters;
  final Offset centerOffset; // Normalized relative to airport center [-1 to 1]
  final double lengthPixels;
  final double widthPixels;
  final double ilsConeLength;
  final double ilsCaptureAngleDeg;
  final List<AircraftCategory> allowedCategories;
  final bool isTakeoffOnly;

  const RunwayData({
    required this.id,
    required this.activeThresholdId,
    required this.headingDeg,
    required this.lengthMeters,
    this.centerOffset = Offset.zero,
    this.lengthPixels = 220.0,
    this.widthPixels = 16.0,
    this.ilsConeLength = 150.0,
    this.ilsCaptureAngleDeg = 28.0,
    this.isTakeoffOnly = false,
    this.allowedCategories = const [
      AircraftCategory.narrowBody,
      AircraftCategory.wideBodyHeavy,
      AircraftCategory.turboprop,
    ],
  });
}

class HelipadData {
  final String id;
  final Offset offset;
  final double radius;

  const HelipadData({
    required this.id,
    required this.offset,
    this.radius = 16.0,
  });
}

class AirportData {
  final String code; // ICAO, e.g. "VABB"
  final String iata; // IATA, e.g. "BOM"
  final String name;
  final String city;
  final int stageNumber;
  final int targetLandings;
  final double windHeadingDeg;
  final double windSpeedKnots;
  final List<RunwayData> runways;
  final List<HelipadData> helipads;
  final String activeRunwayId;
  final String description;
  final bool hasTakeoffRunway;

  const AirportData({
    required this.code,
    required this.iata,
    required this.name,
    required this.city,
    required this.stageNumber,
    required this.targetLandings,
    required this.windHeadingDeg,
    required this.windSpeedKnots,
    required this.runways,
    this.helipads = const [],
    required this.activeRunwayId,
    required this.description,
    this.hasTakeoffRunway = false,
  });

  AirportData copyWith({
    String? code,
    String? iata,
    String? name,
    String? city,
    int? stageNumber,
    int? targetLandings,
    double? windHeadingDeg,
    double? windSpeedKnots,
    List<RunwayData>? runways,
    List<HelipadData>? helipads,
    String? activeRunwayId,
    String? description,
    bool? hasTakeoffRunway,
  }) {
    return AirportData(
      code: code ?? this.code,
      iata: iata ?? this.iata,
      name: name ?? this.name,
      city: city ?? this.city,
      stageNumber: stageNumber ?? this.stageNumber,
      targetLandings: targetLandings ?? this.targetLandings,
      windHeadingDeg: windHeadingDeg ?? this.windHeadingDeg,
      windSpeedKnots: windSpeedKnots ?? this.windSpeedKnots,
      runways: runways ?? this.runways,
      helipads: helipads ?? this.helipads,
      activeRunwayId: activeRunwayId ?? this.activeRunwayId,
      description: description ?? this.description,
      hasTakeoffRunway: hasTakeoffRunway ?? this.hasTakeoffRunway,
    );
  }
}

