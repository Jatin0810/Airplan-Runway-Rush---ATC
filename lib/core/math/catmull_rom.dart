import 'dart:math';
import 'package:flutter/material.dart';

/// Pure math utilities for path interpolation, spline smoothing, and angular kinematics.
class CatmullRomSplineUtil {
  /// Downsamples points so they maintain a minimum distance, eliminating finger jitter
  static List<Offset> decimatePoints(List<Offset> points, {double minDistance = 14.0}) {
    if (points.length < 3) return List<Offset>.from(points);
    final List<Offset> result = [points.first];
    for (int i = 1; i < points.length - 1; i++) {
      if ((points[i] - result.last).distance >= minDistance) {
        result.add(points[i]);
      }
    }
    result.add(points.last);
    return result;
  }

  /// Evaluates Catmull-Rom spline points between control points.
  /// Converts a rough list of touch points into a silky smooth curve.
  static List<Offset> smoothPoints(List<Offset> rawPoints, {int subdivisions = 6, double minDistance = 12.0}) {
    if (rawPoints.length < 3) return rawPoints;

    final filtered = decimatePoints(rawPoints, minDistance: minDistance);
    if (filtered.length < 3) return filtered;

    final List<Offset> smoothed = [];

    // Duplicate end points for boundary condition
    final List<Offset> pts = [
      filtered.first,
      ...filtered,
      filtered.last,
    ];

    for (int i = 0; i < pts.length - 3; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final p2 = pts[i + 2];
      final p3 = pts[i + 3];

      for (int step = 0; step < subdivisions; step++) {
        final t = step / subdivisions;
        final t2 = t * t;
        final t3 = t2 * t;

        // Centripetal / Uniform Catmull-Rom matrix coefficients
        final x = 0.5 *
            ((2 * p1.dx) +
                (-p0.dx + p2.dx) * t +
                (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

        final y = 0.5 *
            ((2 * p1.dy) +
                (-p0.dy + p2.dy) * t +
                (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

        smoothed.add(Offset(x, y));
      }
    }

    smoothed.add(filtered.last);
    return smoothed;
  }

  /// Builds an ultra-smooth Flutter Path through points using midpoint quadratic Bézier splines
  static Path buildSmoothSplinePath(Offset startPos, List<Offset> points) {
    final path = Path()..moveTo(startPos.dx, startPos.dy);
    if (points.isEmpty) return path;

    if (points.length == 1) {
      path.lineTo(points[0].dx, points[0].dy);
      return path;
    }

    final allPoints = [startPos, ...points];
    for (int i = 0; i < allPoints.length - 1; i++) {
      final p0 = allPoints[i];
      final p1 = allPoints[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      if (i == 0) {
        path.lineTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(allPoints.last.dx, allPoints.last.dy);
    return path;
  }

  /// Calculates shortest angular difference wrapped into [-pi, pi].
  static double normalizeAngle(double angle) {
    while (angle < -pi) {
      angle += 2 * pi;
    }
    while (angle > pi) {
      angle -= 2 * pi;
    }
    return angle;
  }

  /// Clamps angular rotation to realistic civil aircraft bank angle turn rates.
  static double steerTowards({
    required double currentHeading,
    required double targetHeading,
    required double maxTurnRate,
  }) {
    final diff = normalizeAngle(targetHeading - currentHeading);
    if (diff.abs() <= maxTurnRate) {
      return targetHeading;
    }
    return normalizeAngle(currentHeading + diff.sign * maxTurnRate);
  }
}

