import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/math/catmull_rom.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/aircraft.dart';

/// Renders confirmed flight paths (pure white, green for landing, amber for departures)
/// and live touch trajectories with silky-smooth Bézier curves matching the reference design.
class FlightPathComponent extends Component {
  final List<AircraftModel> Function() getAircraftList;
  final AircraftModel? Function() getSelectedAircraft;
  final List<Offset> Function() getActiveDrawingPath;
  final bool Function() isCurrentPathLandingMatch;
  RadarTheme theme;

  FlightPathComponent({
    required this.getAircraftList,
    required this.getSelectedAircraft,
    required this.getActiveDrawingPath,
    required this.isCurrentPathLandingMatch,
    required this.theme,
  });

  void updateTheme(RadarTheme newTheme) {
    theme = newTheme;
  }

  Path _buildSmoothSplinePath(Offset startPos, List<Offset> points) {
    return CatmullRomSplineUtil.buildSmoothSplinePath(startPos, points);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final selected = getSelectedAircraft();
    final aircraftList = getAircraftList();

    // 1. Render assigned paths for all aircraft (except the one actively being drawn)
    for (final aircraft in aircraftList) {
      if (aircraft == selected) continue;
      if (aircraft.path.isEmpty) continue;

      // Color logic: Green for landing, Amber for departure climb, Crisp White for flight vectors
      final Color routeColor = aircraft.isLandingRoute
          ? AtcColors.ilsActiveGreen
          : (aircraft.isDeparture
              ? const Color(0xFFFBBF24)
              : (theme.isLightMode ? const Color(0xFF0F172A) : Colors.white));

      final smoothPath = _buildSmoothSplinePath(aircraft.position, aircraft.path);

      // Subtle soft atmospheric glow
      final glowPaint = Paint()
        ..color = routeColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Razor-sharp continuous vector curve matching reference image
      final pathPaint = Paint()
        ..color = routeColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(smoothPath, glowPaint);
      canvas.drawPath(smoothPath, pathPaint);

      // End Pin / Dot indicator (like the red/green/white dot in user reference)
      final last = aircraft.path.last;
      if (aircraft.isLandingRoute) {
        canvas.drawCircle(
          last,
          4.5,
          Paint()..color = AtcColors.ilsActiveGreen.withValues(alpha: 0.4),
        );
        canvas.drawCircle(
          last,
          2.5,
          Paint()..color = AtcColors.ilsActiveGreen,
        );
      } else {
        canvas.drawCircle(
          last,
          2.0,
          Paint()..color = routeColor,
        );
      }
    }

    // 2. Render live finger-drawing stroke dynamically anchored to the selected aircraft
    final activePoints = getActiveDrawingPath();
    if (selected != null && activePoints.isNotEmpty) {
      final isLanding = isCurrentPathLandingMatch();
      final Color activeColor = isLanding
          ? AtcColors.ilsActiveGreen
          : (selected.isDeparture
              ? const Color(0xFFFBBF24)
              : (theme.isLightMode ? const Color(0xFF0284C7) : Colors.white));

      final smoothActivePath = _buildSmoothSplinePath(selected.position, activePoints);

      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final strokePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(smoothActivePath, glowPaint);
      canvas.drawPath(smoothActivePath, strokePaint);

      // Clean touch tip point
      final tipGlow = Paint()
        ..color = activeColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(activePoints.last, 6.0, tipGlow);
      canvas.drawCircle(activePoints.last, 3.5, Paint()..color = activeColor);
      canvas.drawCircle(activePoints.last, 1.8, Paint()..color = Colors.white);
    }
  }
}
