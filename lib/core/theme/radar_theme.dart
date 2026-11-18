import 'package:flutter/material.dart';

/// Base contract defining radar visuals, surfaces, and UI elements.
/// Supports both Daylight Satellite Map mode (Light) and Tactical Night mode (Dark).
abstract class RadarTheme {
  String get name;
  String get description;
  bool get isLightMode;

  // Background & Airspace
  Color get airspaceBackground;
  Color get radarGridColor;
  Color get radarRangeRingsColor;
  Color get sweepGlowColor;

  // City & Terrain Cartography (Mumbai & Indian Airports)
  Color get terrainGrass;
  Color get terrainAirfield;
  Color get riverColor;
  Color get highwayColor;
  Color get cityBlockColor;
  Color get cityRoadColor;

  // Runways & Airport
  Color get runwayAsphalt;
  Color get runwayBorder;
  Color get runwayMarkingWhite;
  Color get terminalBuildingColor;
  Color get taxiwayColor;
  Color get ilsConeColor;
  Color get helipadColor;

  // Flight Paths & Gestures
  Color get activeDrawingPathColor;
  Color get confirmedPathColor;
  Color get selectionHaloColor;

  // UI / HUD Overlays
  Color get hudSurface;
  Color get hudBorder;
  Color get textPrimary;
  Color get textSecondary;
  Color get accentColor;
}

/// Daylight Satellite Map Theme (The New Default Light Mode)
/// Clean, attractive satellite/vector cartography with Mumbai airfield boundary,
/// Mithi River, Western Express Highway, and ultra high-contrast dark asphalt runways.
class DaylightSatelliteRadarTheme implements RadarTheme {
  const DaylightSatelliteRadarTheme();

  @override
  String get name => 'Daylight Satellite (Default)';

  @override
  String get description => 'Clean light satellite map with real airport boundary, Mithi River, and high-contrast runways';

  @override
  bool get isLightMode => true;

  @override
  Color get airspaceBackground => const Color(0xFFE2E8F0); // Clean light urban terrain

  @override
  Color get radarGridColor => const Color(0x140F172A);

  @override
  Color get radarRangeRingsColor => const Color(0x1A0F172A);

  @override
  Color get sweepGlowColor => const Color(0x120284C7);

  // Cartography
  @override
  Color get terrainGrass => const Color(0xFFD1DCD0); // Soft park/hill greenery

  @override
  Color get terrainAirfield => const Color(0xFFE5D8C1); // Authentic sandy-tan grass airfield enclave

  @override
  Color get riverColor => const Color(0xFF0284C7); // Vibrant azure blue Mithi River

  @override
  Color get highwayColor => const Color(0xFFF59E0B); // Arterial gold Western Express Highway

  @override
  Color get cityBlockColor => const Color(0xFFCBD5E1); // Clean suburban blocks

  @override
  Color get cityRoadColor => const Color(0xFFF1F5F9); // White/slate city streets

  // Runways & Airport - ULTRA HIGH CONTRAST & CLEAN
  @override
  Color get runwayAsphalt => const Color(0xFF1E293B); // Deep charcoal asphalt

  @override
  Color get runwayBorder => const Color(0xFF0F172A); // Sharp dark edge

  @override
  Color get runwayMarkingWhite => const Color(0xFFFFFFFF); // Pure crisp white markings

  @override
  Color get terminalBuildingColor => const Color(0xFF475569); // Silver-slate terminal

  @override
  Color get taxiwayColor => const Color(0xFF334155); // Dark asphalt taxiway

  @override
  Color get ilsConeColor => const Color(0xFF10B981); // Emerald green ILS

  @override
  Color get helipadColor => const Color(0xFFEA580C); // Bold orange helipad

  // Flight Paths
  @override
  Color get activeDrawingPathColor => const Color(0xFF0284C7); // Vibrant blue path

  @override
  Color get confirmedPathColor => const Color(0xFF10B981); // Emerald green landing

  @override
  Color get selectionHaloColor => const Color(0xFF0284C7);

  // UI Overlays
  @override
  Color get hudSurface => const Color(0xF2FFFFFF); // Frosted white glass HUD

  @override
  Color get hudBorder => const Color(0xFFCBD5E1);

  @override
  Color get textPrimary => const Color(0xFF0F172A);

  @override
  Color get textSecondary => const Color(0xFF475569);

  @override
  Color get accentColor => const Color(0xFF0284C7);
}

/// Modern tactical dark slate / navy blue radar theme (Dark Mode).
class TacticalNightRadarTheme implements RadarTheme {
  const TacticalNightRadarTheme();

  @override
  String get name => 'Tactical Night (Dark Mode)';

  @override
  String get description => 'Illuminated night airfield with glowing cyan runway edge lights';

  @override
  bool get isLightMode => false;

  @override
  Color get airspaceBackground => const Color(0xFF0A0F1D);

  @override
  Color get radarGridColor => const Color(0x0D38BDF8);

  @override
  Color get radarRangeRingsColor => const Color(0x1A38BDF8);

  @override
  Color get sweepGlowColor => const Color(0x1F38BDF8);

  // Cartography
  @override
  Color get terrainGrass => const Color(0xFF0D1B2A);

  @override
  Color get terrainAirfield => const Color(0xFF131D31);

  @override
  Color get riverColor => const Color(0xFF0369A1);

  @override
  Color get highwayColor => const Color(0xFFD97706);

  @override
  Color get cityBlockColor => const Color(0xFF111827);

  @override
  Color get cityRoadColor => const Color(0xFF1F2937);

  // Runways
  @override
  Color get runwayAsphalt => const Color(0xFF0F172A);

  @override
  Color get runwayBorder => const Color(0xFF475569);

  @override
  Color get runwayMarkingWhite => const Color(0xFFF8FAFC);

  @override
  Color get terminalBuildingColor => const Color(0xFF1E293B);

  @override
  Color get taxiwayColor => const Color(0x4064748B);

  @override
  Color get ilsConeColor => const Color(0xFF10B981);

  @override
  Color get helipadColor => const Color(0xFFF97316);

  // Flight Paths
  @override
  Color get activeDrawingPathColor => const Color(0xFF38BDF8);

  @override
  Color get confirmedPathColor => const Color(0xFF0EA5E9);

  @override
  Color get selectionHaloColor => const Color(0xFF38BDF8);

  // UI
  @override
  Color get hudSurface => const Color(0xE60F172A);

  @override
  Color get hudBorder => const Color(0xFF1E293B);

  @override
  Color get textPrimary => const Color(0xFFF8FAFC);

  @override
  Color get textSecondary => const Color(0xFF94A3B8);

  @override
  Color get accentColor => const Color(0xFF38BDF8);
}

/// Vintage Retro Phosphor Green CRT Radar theme.
class PhosphorGreenRadarTheme implements RadarTheme {
  const PhosphorGreenRadarTheme();

  @override
  String get name => 'Phosphor CRT (Vintage)';

  @override
  String get description => 'Classic green cathode-ray tube monochrome radar';

  @override
  bool get isLightMode => false;

  @override
  Color get airspaceBackground => const Color(0xFF031408);

  @override
  Color get radarGridColor => const Color(0x1A22C55E);

  @override
  Color get radarRangeRingsColor => const Color(0x3322C55E);

  @override
  Color get sweepGlowColor => const Color(0x264ADE80);

  @override
  Color get terrainGrass => const Color(0xFF051C0C);

  @override
  Color get terrainAirfield => const Color(0xFF082810);

  @override
  Color get riverColor => const Color(0xFF15803D);

  @override
  Color get highwayColor => const Color(0xFF22C55E);

  @override
  Color get cityBlockColor => const Color(0xFF051A0B);

  @override
  Color get cityRoadColor => const Color(0xFF0B3314);

  @override
  Color get runwayAsphalt => const Color(0xFF082810);

  @override
  Color get runwayBorder => const Color(0xFF166534);

  @override
  Color get runwayMarkingWhite => const Color(0xFF86EFAC);

  @override
  Color get terminalBuildingColor => const Color(0xFF0D3818);

  @override
  Color get taxiwayColor => const Color(0x4D22C55E);

  @override
  Color get ilsConeColor => const Color(0xFF4ADE80);

  @override
  Color get helipadColor => const Color(0xFFA3E635);

  @override
  Color get activeDrawingPathColor => const Color(0xFF4ADE80);

  @override
  Color get confirmedPathColor => const Color(0xFF22C55E);

  @override
  Color get selectionHaloColor => const Color(0xFF86EFAC);

  @override
  Color get hudSurface => const Color(0xEC031A0B);

  @override
  Color get hudBorder => const Color(0xFF14532D);

  @override
  Color get textPrimary => const Color(0xFF86EFAC);

  @override
  Color get textSecondary => const Color(0xFF4ADE80);

  @override
  Color get accentColor => const Color(0xFF22C55E);
}

/// High-contrast tactical Amber Radar theme.
class AmberTacticalRadarTheme implements RadarTheme {
  const AmberTacticalRadarTheme();

  @override
  String get name => 'Tactical Amber';

  @override
  String get description => 'Warm amber military radar display';

  @override
  bool get isLightMode => false;

  @override
  Color get airspaceBackground => const Color(0xFF150A02);

  @override
  Color get radarGridColor => const Color(0x1AF59E0B);

  @override
  Color get radarRangeRingsColor => const Color(0x33F59E0B);

  @override
  Color get sweepGlowColor => const Color(0x26FBBF24);

  @override
  Color get terrainGrass => const Color(0xFF1F0E04);

  @override
  Color get terrainAirfield => const Color(0xFF2B1405);

  @override
  Color get riverColor => const Color(0xFFB45309);

  @override
  Color get highwayColor => const Color(0xFFF59E0B);

  @override
  Color get cityBlockColor => const Color(0xFF1A0C03);

  @override
  Color get cityRoadColor => const Color(0xFF3B1A06);

  @override
  Color get runwayAsphalt => const Color(0xFF281504);

  @override
  Color get runwayBorder => const Color(0xFF78350F);

  @override
  Color get runwayMarkingWhite => const Color(0xFFFDE68A);

  @override
  Color get terminalBuildingColor => const Color(0xFF381C06);

  @override
  Color get taxiwayColor => const Color(0x4DF59E0B);

  @override
  Color get ilsConeColor => const Color(0xFFFBBF24);

  @override
  Color get helipadColor => const Color(0xFFF97316);

  @override
  Color get activeDrawingPathColor => const Color(0xFFFBBF24);

  @override
  Color get confirmedPathColor => const Color(0xFFF59E0B);

  @override
  Color get selectionHaloColor => const Color(0xFFFDE68A);

  @override
  Color get hudSurface => const Color(0xEC1A0D03);

  @override
  Color get hudBorder => const Color(0xFF78350F);

  @override
  Color get textPrimary => const Color(0xFFFDE68A);

  @override
  Color get textSecondary => const Color(0xFFFBBF24);

  @override
  Color get accentColor => const Color(0xFFF59E0B);
}
