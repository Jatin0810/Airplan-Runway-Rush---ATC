import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/math/catmull_rom.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/aircraft.dart';

/// Top-down vector aircraft component with authentic aeronautical blueprints,
/// realistic cockpit glass, wing navigation strobes, engine cowlings, spinning turboprops,
/// and Indian Air Force (IAF) fighter jets.
class AircraftComponent extends PositionComponent {
  final AircraftModel model;
  final void Function(AircraftModel plane)? onRolloutCompleted;
  RadarTheme theme;
  bool isSelected = false;
  double _rotorAngle = 0.0;
  double _rolloutTimer = 0.0;
  double _strobeTimer = 0.0;
  bool _strobeOn = false;

  AircraftComponent({
    required this.model,
    required this.theme,
    this.onRolloutCompleted,
  }) : super(
          position: Vector2(model.position.dx, model.position.dy),
          anchor: Anchor.center,
        );

  void updateTheme(RadarTheme newTheme) {
    theme = newTheme;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (model.state == AircraftFlightState.landed ||
        model.state == AircraftFlightState.crashed) {
      return;
    }

    _rotorAngle += dt * 32.0; // Spin helicopter rotor & turboprop blades
    _strobeTimer += dt;
    if (_strobeTimer >= 0.8) {
      _strobeTimer = 0.0;
      _strobeOn = !_strobeOn;
    }

    // 1. Runway Rollout Physics (Touchdown -> Running down the runway -> Complete)
    if (model.state == AircraftFlightState.landingRollout) {
      _rolloutTimer += dt;
      model.rolloutSpeed = max(14.0, model.rolloutSpeed - dt * 26.0);
      final moveDist = model.rolloutSpeed * dt;
      model.rolloutTraveled += moveDist;

      position.x += cos(model.heading) * moveDist;
      position.y += sin(model.heading) * moveDist;

      if (model.rolloutTraveled >= model.rolloutTotalDistance * 0.75) {
        model.opacity = max(
          0.0,
          1.0 - (model.rolloutTraveled - model.rolloutTotalDistance * 0.75) /
              (model.rolloutTotalDistance * 0.25),
        );
      }

      if (model.rolloutTraveled >= model.rolloutTotalDistance || _rolloutTimer >= 3.2) {
        model.state = AircraftFlightState.landed;
        onRolloutCompleted?.call(model);
      }

      model.position = Offset(position.x, position.y);
      return;
    }

    // 1b. Runway Take-Off Physics (Accelerating down the 3rd runway -> Lift-off into departures)
    if (model.state == AircraftFlightState.takingOff) {
      model.rolloutSpeed = min(model.speed, model.rolloutSpeed + dt * 28.0);
      final moveDist = model.rolloutSpeed * dt;
      model.rolloutTraveled += moveDist;

      position.x += cos(model.heading) * moveDist;
      position.y += sin(model.heading) * moveDist;

      if (model.rolloutTraveled >= model.rolloutTotalDistance) {
        model.state = AircraftFlightState.departing;
      }
      model.position = Offset(position.x, position.y);
      return;
    }

    // 2. Exact Pixel-to-Pixel Path Following Logic
    // Aircraft follows the drawn flight path precisely from waypoint to waypoint
    if (model.path.isNotEmpty) {
      double remainingDist = model.speed * dt;

      while (remainingDist > 0 && model.path.isNotEmpty) {
        final target = model.path.first;
        final dx = target.dx - position.x;
        final dy = target.dy - position.y;
        final dist = hypot(dx, dy);

        if (dist <= remainingDist) {
          position.x = target.dx;
          position.y = target.dy;
          remainingDist -= dist;
          model.path.removeAt(0);

          if (model.path.isNotEmpty) {
            final next = model.path.first;
            final targetAngle = atan2(next.dy - position.y, next.dx - position.x);
            model.heading = CatmullRomSplineUtil.steerTowards(
              currentHeading: model.heading,
              targetHeading: targetAngle,
              maxTurnRate: model.maxTurnRate * dt * 4.0,
            );
          }
        } else {
          final desiredHeading = atan2(dy, dx);
          model.heading = CatmullRomSplineUtil.steerTowards(
            currentHeading: model.heading,
            targetHeading: desiredHeading,
            maxTurnRate: model.maxTurnRate * dt * 4.0,
          );
          position.x += (dx / dist) * remainingDist;
          position.y += (dy / dist) * remainingDist;
          remainingDist = 0;
        }
      }

      if (model.path.isEmpty &&
          model.state == AircraftFlightState.followingPath &&
          !isSelected) {
        model.state = model.isDeparture
            ? AircraftFlightState.departing
            : AircraftFlightState.airborne;
        model.isLandingRoute = false;
        model.isLockedToRunway = false;
      }
    } else {
      // Free straight flight along current heading
      position.x += cos(model.heading) * model.speed * dt;
      position.y += sin(model.heading) * model.speed * dt;
    }

    model.position = Offset(position.x, position.y);
  }

  static double hypot(double x, double y) => sqrt(x * x + y * y);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (model.opacity < 1.0) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: model.opacity));
    }

    // 1. Rollout Tire Smoke Effect
    if (model.state == AircraftFlightState.landingRollout) {
      _renderRolloutSmoke(canvas);
    }

    // 2. TCAS Proximity Alert Halo (Yellow dashed ring)
    if (model.tcasAlert && model.state != AircraftFlightState.landingRollout) {
      final tcasPaint = Paint()
        ..color = AtcColors.tcasWarningYellow.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      for (double a = 0; a < 2 * pi; a += 0.4) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 22),
          a,
          0.2,
          false,
          tcasPaint,
        );
      }
    }

    // 3. Selection Halo
    if (isSelected) {
      final selectPaint = Paint()
        ..color = theme.selectionHaloColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, model.wingspan * 0.9, selectPaint);
    }

    // 4. Data Tag
    if (model.state != AircraftFlightState.landingRollout) {
      _renderDataTag(canvas);
    }

    // 5. Authentic Vector Silhouette Drawing
    canvas.save();
    canvas.rotate(model.heading);

    if (model.isHelicopter) {
      _renderRealisticHelicopter(canvas);
    } else if (model.isFighterJet) {
      _renderRealisticIafFighter(canvas);
    } else if (model.isTurboprop) {
      _renderRealisticTurboprop(canvas);
    } else if (model.isWideBody) {
      _renderRealisticHeavyAirliner(canvas);
    } else {
      _renderRealisticAirliner(canvas);
    }

    canvas.restore();

    if (model.opacity < 1.0) {
      canvas.restore();
    }
  }

  void _renderRolloutSmoke(Canvas canvas) {
    final smokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(-10, 0), 5.0, smokePaint);
    canvas.drawCircle(const Offset(-18, 0), 7.0, smokePaint);
  }

  void _renderDataTag(Canvas canvas) {
    const double offsetX = 12.0;
    const double offsetY = -16.0;

    final tagText = model.isDeparture
        ? '🛫 ${model.flightNumber}'
        : '${model.flightNumber} ${model.aircraftType}';
    final textSpan = TextSpan(
      text: tagText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );

    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offsetX, offsetY, tp.width + 6, tp.height + 4),
      const Radius.circular(3),
    );

    final bgPaint = Paint()..color = theme.hudSurface.withValues(alpha: 0.9);
    final borderPaint = Paint()
      ..color = model.isDeparture
          ? const Color(0xFFF59E0B)
          : (model.isLandingRoute ? AtcColors.ilsActiveGreen : model.primaryColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(bgRect, bgPaint);
    canvas.drawRRect(bgRect, borderPaint);

    tp.paint(canvas, const Offset(offsetX + 3, offsetY + 2));
  }

  /// 1. Commercial Narrowbody Airliner (IndiGo A320 / Vistara A321)
  /// Twin-engine swept wings with sharklets, underwing turbofans, radome nose
  void _renderRealisticAirliner(Canvas canvas) {
    final s = model.wingspan;

    // Wing Root Fairings
    final fairingPaint = Paint()..color = const Color(0xFFCBD5E1);
    final fairingPath = Path()
      ..moveTo(s * 0.16, -s * 0.16)
      ..lineTo(s * 0.02, -s * 0.32)
      ..lineTo(-s * 0.18, -s * 0.16)
      ..lineTo(-s * 0.18, s * 0.16)
      ..lineTo(s * 0.02, s * 0.32)
      ..lineTo(s * 0.16, s * 0.16)
      ..close();
    canvas.drawPath(fairingPath, fairingPaint);

    // Main Swept Wings with realistic chord taper
    final wingPaint = Paint()..color = model.primaryColor;
    final wingPath = Path()
      ..moveTo(-s * 0.12, -s * 0.50) // Left wingtip
      ..lineTo(s * 0.14, -s * 0.14)  // Left wing root
      ..lineTo(s * 0.14, s * 0.14)   // Right wing root
      ..lineTo(-s * 0.12, s * 0.50)  // Right wingtip
      ..lineTo(-s * 0.22, s * 0.46)  // Trailing edge
      ..lineTo(-s * 0.04, 0)
      ..lineTo(-s * 0.22, -s * 0.46)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Trailing edge flap track fairings
    final flapPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRect(Rect.fromLTWH(-s * 0.16, -s * 0.36, s * 0.06, s * 0.03), flapPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, -s * 0.24, s * 0.06, s * 0.03), flapPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.16, s * 0.33, s * 0.06, s * 0.03), flapPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, s * 0.21, s * 0.06, s * 0.03), flapPaint);

    // Wingtip Sharklets
    final sharkletPaint = Paint()..color = model.secondaryColor;
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, -s * 0.52, s * 0.06, s * 0.04), sharkletPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, s * 0.48, s * 0.06, s * 0.04), sharkletPaint);

    // Fuselage
    final fuselagePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.94, height: s * 0.22),
      fuselagePaint,
    );

    // Dark Radar Radome Nose
    final radomePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.44, 0), width: s * 0.12, height: s * 0.12),
      radomePaint,
    );

    // Cockpit Windshield (4 dark aeronautical glass panels)
    final glassPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(s * 0.32, -s * 0.06, s * 0.05, s * 0.05), glassPaint);
    canvas.drawRect(Rect.fromLTWH(s * 0.32, s * 0.01, s * 0.05, s * 0.05), glassPaint);

    // Horizontal Stabilizer & Vertical Tail Fin in Airline Livery
    final tailPaint = Paint()..color = model.secondaryColor;
    final tailPath = Path()
      ..moveTo(-s * 0.34, -s * 0.28)
      ..lineTo(-s * 0.24, 0)
      ..lineTo(-s * 0.34, s * 0.28)
      ..lineTo(-s * 0.46, 0)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // High-Bypass Turbofan Jet Engines on Pylons with Spinner Cones
    final cowlPaint = Paint()..color = const Color(0xFF475569);
    final spinnerPaint = Paint()..color = Colors.white;

    // Left engine
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.04, -s * 0.24), width: s * 0.16, height: s * 0.08), cowlPaint);
    canvas.drawCircle(Offset(s * 0.10, -s * 0.24), 1.5, spinnerPaint);
    // Right engine
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.04, s * 0.24), width: s * 0.16, height: s * 0.08), cowlPaint);
    canvas.drawCircle(Offset(s * 0.10, s * 0.24), 1.5, spinnerPaint);

    // Wing Navigation Lights
    canvas.drawCircle(Offset(-s * 0.12, -s * 0.50), 1.5, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(-s * 0.12, s * 0.50), 1.5, Paint()..color = const Color(0xFF22C55E));
    if (_strobeOn) {
      canvas.drawCircle(Offset(-s * 0.46, 0), 2.0, Paint()..color = Colors.white);
    }
  }

  /// 2. Widebody Heavy Airliner (Air India B777 / B747 Heavy)
  /// Massive widebody fuselage, 4 engine nacelles or massive twin GE90s, Maharaja red & sun gold livery
  void _renderRealisticHeavyAirliner(Canvas canvas) {
    final s = model.wingspan;

    // Wing Root Fairings
    final fairingPaint = Paint()..color = const Color(0xFFCBD5E1);
    final fairingPath = Path()
      ..moveTo(s * 0.20, -s * 0.18)
      ..lineTo(s * 0.04, -s * 0.34)
      ..lineTo(-s * 0.20, -s * 0.18)
      ..lineTo(-s * 0.20, s * 0.18)
      ..lineTo(s * 0.04, s * 0.34)
      ..lineTo(s * 0.20, s * 0.18)
      ..close();
    canvas.drawPath(fairingPath, fairingPaint);

    // Large Swept Wings
    final wingPaint = Paint()..color = const Color(0xFFF1F5F9);
    final wingPath = Path()
      ..moveTo(-s * 0.14, -s * 0.52) // Left tip
      ..lineTo(s * 0.16, -s * 0.16)
      ..lineTo(s * 0.16, s * 0.16)
      ..lineTo(-s * 0.14, s * 0.52)  // Right tip
      ..lineTo(-s * 0.25, s * 0.48)
      ..lineTo(-s * 0.06, 0)
      ..lineTo(-s * 0.25, -s * 0.48)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Air India Red Wingtips
    final tipPaint = Paint()..color = AtcColors.airIndiaRed;
    canvas.drawRect(Rect.fromLTWH(-s * 0.16, -s * 0.53, s * 0.06, s * 0.04), tipPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.16, s * 0.49, s * 0.06, s * 0.04), tipPaint);

    // 4 Underwing Turbofan Engines
    final cowlPaint = Paint()..color = const Color(0xFF334155);
    final goldRim = Paint()..color = AtcColors.airIndiaGold;

    // Outer left
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.02, -s * 0.36), width: s * 0.14, height: s * 0.07), cowlPaint);
    canvas.drawCircle(Offset(s * 0.03, -s * 0.36), 1.5, goldRim);
    // Inner left
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.05, -s * 0.22), width: s * 0.17, height: s * 0.09), cowlPaint);
    canvas.drawCircle(Offset(s * 0.11, -s * 0.22), 1.8, goldRim);
    // Inner right
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.05, s * 0.22), width: s * 0.17, height: s * 0.09), cowlPaint);
    canvas.drawCircle(Offset(s * 0.11, s * 0.22), 1.8, goldRim);
    // Outer right
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.02, s * 0.36), width: s * 0.14, height: s * 0.07), cowlPaint);
    canvas.drawCircle(Offset(s * 0.03, s * 0.36), 1.5, goldRim);

    // Wide Fuselage
    final fuselagePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 1.05, height: s * 0.28),
      fuselagePaint,
    );

    // Maharaja Red Cheatline along fuselage
    final cheatline = Paint()..color = AtcColors.airIndiaRed..strokeWidth = 1.2;
    canvas.drawLine(Offset(-s * 0.25, -s * 0.09), Offset(s * 0.30, -s * 0.09), cheatline);
    canvas.drawLine(Offset(-s * 0.25, s * 0.09), Offset(s * 0.30, s * 0.09), cheatline);

    // Radome
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.49, 0), width: s * 0.13, height: s * 0.13), Paint()..color = const Color(0xFF1E293B));

    // Cockpit Glazing
    final glassPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(s * 0.36, -s * 0.07, s * 0.06, s * 0.06), glassPaint);
    canvas.drawRect(Rect.fromLTWH(s * 0.36, s * 0.01, s * 0.06, s * 0.06), glassPaint);

    // Maharaja Red & Sun Gold Tail Fin
    final tailPaint = Paint()..color = AtcColors.airIndiaRed;
    final tailPath = Path()
      ..moveTo(-s * 0.38, -s * 0.30)
      ..lineTo(-s * 0.26, 0)
      ..lineTo(-s * 0.38, s * 0.30)
      ..lineTo(-s * 0.50, 0)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // Sun Gold Maharaja Crest on tail
    canvas.drawCircle(Offset(-s * 0.38, 0), s * 0.06, Paint()..color = AtcColors.airIndiaGold);

    // Nav lights
    canvas.drawCircle(Offset(-s * 0.14, -s * 0.52), 1.5, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(-s * 0.14, s * 0.52), 1.5, Paint()..color = const Color(0xFF22C55E));
    if (_strobeOn) {
      canvas.drawCircle(Offset(-s * 0.50, 0), 2.2, Paint()..color = Colors.white);
    }
  }

  /// 3. Twin-Turboprop Regional Aircraft (SpiceJet Q400 / IndiGo ATR-72)
  /// Straight high wings, 2 turboprop nacelles with spinning propeller discs, T-tail
  void _renderRealisticTurboprop(Canvas canvas) {
    final s = model.wingspan;

    // High Straight Wings (Distinctive straight chord)
    final wingPaint = Paint()..color = Colors.white;
    final wingPath = Path()
      ..moveTo(s * 0.02, -s * 0.50)
      ..lineTo(s * 0.05, 0)
      ..lineTo(s * 0.02, s * 0.50)
      ..lineTo(-s * 0.10, s * 0.50)
      ..lineTo(-s * 0.08, 0)
      ..lineTo(-s * 0.10, -s * 0.50)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    // Wingtips in Livery Color (SpiceJet Red/Orange)
    final tipPaint = Paint()..color = model.primaryColor;
    canvas.drawRect(Rect.fromLTWH(-s * 0.10, -s * 0.51, s * 0.12, s * 0.03), tipPaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.10, s * 0.48, s * 0.12, s * 0.03), tipPaint);

    // Fuselage (Slender tube)
    final fuselagePaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.98, height: s * 0.18),
      fuselagePaint,
    );

    // Radome
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.46, 0), width: s * 0.10, height: s * 0.10), Paint()..color = const Color(0xFF1E293B));

    // Cockpit Glazing
    final glassPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(s * 0.34, -s * 0.05, s * 0.05, s * 0.04), glassPaint);
    canvas.drawRect(Rect.fromLTWH(s * 0.34, s * 0.01, s * 0.05, s * 0.04), glassPaint);

    // 2 Turboprop Engine Nacelles
    final nacellePaint = Paint()..color = const Color(0xFF475569);
    // Left nacelle
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.04, -s * 0.22), width: s * 0.24, height: s * 0.08), nacellePaint);
    // Right nacelle
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.04, s * 0.22), width: s * 0.24, height: s * 0.08), nacellePaint);

    // Spinning Twin Propeller Discs!
    _renderSpinningPropeller(canvas, Offset(s * 0.16, -s * 0.22), s * 0.16);
    _renderSpinningPropeller(canvas, Offset(s * 0.16, s * 0.22), s * 0.16);

    // T-Tail Horizontal Stabilizer atop Vertical Fin
    final tailPaint = Paint()..color = model.primaryColor;
    canvas.drawRect(Rect.fromCenter(center: Offset(-s * 0.42, 0), width: s * 0.08, height: s * 0.32), tailPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(-s * 0.35, 0), width: s * 0.14, height: s * 0.06), Paint()..color = model.secondaryColor);

    // Nav lights
    canvas.drawCircle(Offset(-s * 0.04, -s * 0.50), 1.5, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(-s * 0.04, s * 0.50), 1.5, Paint()..color = const Color(0xFF22C55E));
    if (_strobeOn) {
      canvas.drawCircle(Offset(-s * 0.42, 0), 2.0, Paint()..color = Colors.white);
    }
  }

  void _renderSpinningPropeller(Canvas canvas, Offset center, double radius) {
    // Semi-transparent blur disc
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    // Rotating 4-blade propeller
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotorAngle * 1.5);

    final bladePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.85)
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(0, -radius), Offset(0, radius), bladePaint);
    canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), bladePaint);

    // Yellow tips
    final yellowTip = Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 1.5;
    canvas.drawCircle(Offset(0, -radius), 1.0, yellowTip);
    canvas.drawCircle(Offset(0, radius), 1.0, yellowTip);
    canvas.drawCircle(Offset(-radius, 0), 1.0, yellowTip);
    canvas.drawCircle(Offset(radius, 0), 1.0, yellowTip);

    // Spinner hub
    canvas.drawCircle(Offset.zero, 2.0, Paint()..color = Colors.white);
    canvas.restore();
  }

  /// 4. Indian Air Force (IAF) Fighter Jet (Sukhoi Su-30MKI / Rafale)
  /// Twin afterburners, delta wings, forward canards, Astra missiles, Tricolor Roundels
  void _renderRealisticIafFighter(Canvas canvas) {
    final s = model.wingspan;

    // Twin Titanium Afterburner Exhaust Nozzles with Glowing Blue/Orange Trails
    final burnerGlow = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(Offset(-s * 0.44, -s * 0.10), 3.2, burnerGlow);
    canvas.drawCircle(Offset(-s * 0.44, s * 0.10), 3.2, burnerGlow);
    final coreGlow = Paint()..color = const Color(0xFFFFA500);
    canvas.drawCircle(Offset(-s * 0.44, -s * 0.10), 1.6, coreGlow);
    canvas.drawCircle(Offset(-s * 0.44, s * 0.10), 1.6, coreGlow);

    // Aggressive Airframe: Slender needle nose, LERX, forward Canards, and Delta Wings
    final jetBodyPaint = Paint()..color = const Color(0xFF64748B); // IAF Air Superiority Grey
    final jetPath = Path()
      ..moveTo(s * 0.62, 0) // Pitot Probe
      ..lineTo(s * 0.48, s * 0.08)
      ..lineTo(s * 0.22, s * 0.14) // LERX
      ..lineTo(s * 0.15, s * 0.26) // Forward Canard
      ..lineTo(s * 0.05, s * 0.14)
      ..lineTo(-s * 0.05, s * 0.54) // Wingtip Missile Rail Right
      ..lineTo(-s * 0.12, s * 0.54)
      ..lineTo(-s * 0.26, s * 0.48) // Trailing delta
      ..lineTo(-s * 0.18, s * 0.20)
      ..lineTo(-s * 0.42, s * 0.18) // Twin canted rudder right
      ..lineTo(-s * 0.38, 0)        // Exhaust separation
      ..lineTo(-s * 0.42, -s * 0.18) // Twin canted rudder left
      ..lineTo(-s * 0.18, -s * 0.20)
      ..lineTo(-s * 0.26, -s * 0.48)
      ..lineTo(-s * 0.12, -s * 0.54)
      ..lineTo(-s * 0.05, -s * 0.54) // Wingtip Missile Rail Left
      ..lineTo(s * 0.05, -s * 0.14)
      ..lineTo(s * 0.15, -s * 0.26) // Forward Canard
      ..lineTo(s * 0.22, -s * 0.14)
      ..lineTo(s * 0.48, -s * 0.08)
      ..close();
    canvas.drawPath(jetPath, jetBodyPaint);

    // Wingtip Air-to-Air Missiles (White Astra / R-73 missiles on rails)
    final missilePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, -s * 0.56, s * 0.18, s * 0.03), missilePaint);
    canvas.drawRect(Rect.fromLTWH(-s * 0.14, s * 0.53, s * 0.18, s * 0.03), missilePaint);

    // Teardrop Bubble Cockpit Canopy
    final canopyPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.20, 0), width: s * 0.28, height: s * 0.09),
      canopyPaint,
    );

    // Indian Air Force Tricolor Roundel (Saffron, White, Green concentric circles on wings)
    _renderIafRoundel(canvas, Offset(-s * 0.08, -s * 0.32), 3.5);
    _renderIafRoundel(canvas, Offset(-s * 0.08, s * 0.32), 3.5);
  }

  void _renderIafRoundel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFF9933));
    canvas.drawCircle(center, radius * 0.66, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.33, Paint()..color = const Color(0xFF138808));
  }

  /// 5. Helicopter (Pawan Hans / IAF ALH Dhruv)
  /// Landing skids, teardrop cabin, tail boom, spinning rotor disc & blades
  void _renderRealisticHelicopter(Canvas canvas) {
    const r = 8.5;

    // Dual Tubular Landing Skids
    final skidPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(-12, -7), const Offset(10, -7), skidPaint);
    canvas.drawLine(const Offset(-12, 7), const Offset(10, 7), skidPaint);

    // Streamlined Cabin Fuselage
    final bodyPaint = Paint()..color = model.primaryColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 1.5),
      bodyPaint,
    );

    // White cabin roof stripe
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 0.7),
      Paint()..color = model.secondaryColor,
    );

    // Wrap-Around Cockpit Windshield (Dark glazing)
    final windshieldPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(6.5, 0), width: 6.0, height: 9.0),
      windshieldPaint,
    );

    // Tail Boom with High-Mounted Vertical Fin
    final tailPaint = Paint()
      ..color = model.primaryColor
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset.zero, const Offset(-18, 0), tailPaint);

    // Tail Rotor Fin & Spinning Tail Rotor
    canvas.drawRect(const Rect.fromLTWH(-19, -4, 3, 8), Paint()..color = const Color(0xFF1E293B));
    canvas.drawLine(const Offset(-18, -6), const Offset(-18, 6), Paint()..color = Colors.white);

    // 4-Blade Main Rotor with Motion Blur Disc
    canvas.save();
    canvas.rotate(_rotorAngle);
    // Rotor Disc Blur
    canvas.drawCircle(
      Offset.zero,
      17.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    // 4 Blades
    final bladePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(-16, 0), const Offset(16, 0), bladePaint);
    canvas.drawLine(const Offset(0, -16), const Offset(0, 16), bladePaint);
    // Rotor Mast Hub
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = const Color(0xFF1E293B));
    canvas.restore();
  }
}
