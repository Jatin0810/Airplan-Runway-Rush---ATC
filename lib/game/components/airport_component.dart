import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/atc_colors.dart';
import '../../core/theme/radar_theme.dart';
import '../../data/models/airport.dart';

/// Renders the airport using a real satellite photo background (Mumbai CSMIA).
/// The satellite image is drawn first, then runways are highlighted on top
/// with clean high-contrast markings, entry-point indicators, and helipads.
/// NO filled ILS gradient cone — only a thin dashed approach centerline.
class AirportComponent extends PositionComponent {
  final AirportData airport;
  RadarTheme theme;

  double _beaconTimer = 0.0;
  bool _beaconOn = true;
  ui.Image? _satelliteImage;
  bool _imageLoaded = false;
  Vector2 _viewportSize = Vector2(800, 800);

  AirportComponent({
    required this.airport,
    required this.theme,
    required Vector2 position,
    Vector2? viewportSize,
  }) : super(position: position, anchor: Anchor.center) {
    if (viewportSize != null) {
      _viewportSize = viewportSize.clone();
    } else {
      _viewportSize = position * 2;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewportSize = size.clone();
    position = size / 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final data = await rootBundle.load('assets/images/mumbai_satellite.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _satelliteImage = frame.image;
      _imageLoaded = true;
    } catch (_) {
      _imageLoaded = false;
    }
  }

  void updateTheme(RadarTheme newTheme) {
    theme = newTheme;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _beaconTimer += dt;
    if (_beaconTimer >= 0.9) {
      _beaconTimer = 0.0;
      _beaconOn = !_beaconOn;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Satellite background image (the real CSMIA photo)
    _renderSatelliteBackground(canvas);

    // 2. Subtle radar range rings on top
    _renderRadarRings(canvas);

    // 3. High-contrast clean runways with entry-point highlights (no filled ILS cone)
    _renderHighContrastRunways(canvas);

    // 4. Helipads H1 & H2
    _renderHelipads(canvas);

    // 5. ATC Tower beacon
    _renderAtcControlTower(canvas);
  }

  /// Draw the satellite image stretched to fill the full screen,
  /// with a soft Gaussian blur applied ONLY to the background image.
  /// Runways, markings, and aircraft are rendered separately on top and stay razor sharp!
  void _renderSatelliteBackground(Canvas canvas) {
    final screenW = _viewportSize.x > 0 ? _viewportSize.x : 800.0;
    final screenH = _viewportSize.y > 0 ? _viewportSize.y : 800.0;
    // Stretch to full screen with a tiny overscan buffer to avoid subpixel seams
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: screenW + 4,
      height: screenH + 4,
    );

    if (!_imageLoaded || _satelliteImage == null) {
      // Fallback: sandy airfield color if image not loaded
      final fallbackPaint = Paint()..color = const Color(0xFFD4B896);
      canvas.drawRect(dst, fallbackPaint);
      return;
    }

    final img = _satelliteImage!;
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    
    // Smooth photographic blur applied exclusively to the satellite background:
    // sigmaX: 4.5, sigmaY: 4.5 softly blurs distracting background houses/streets,
    // making the clean runways and aircraft pop with high contrast.
    final imgPaint = Paint()
      ..filterQuality = FilterQuality.medium
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: 4.5,
        sigmaY: 4.5,
        tileMode: TileMode.clamp,
      );
    canvas.drawImageRect(img, src, dst, imgPaint);
  }

  void _renderRadarRings(Canvas canvas) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final radius in [70.0, 140.0, 210.0]) {
      canvas.drawCircle(Offset.zero, radius, ringPaint);
    }
  }

  /// HIGH-CONTRAST CLEAN RUNWAYS:
  /// Rendered on top of the satellite image so users clearly see them.
  /// Entry-point (threshold) is highlighted with a glowing pulsing marker.
  /// ILS approach is shown ONLY as a thin dashed centerline extension — no filled cone.
  void _renderHighContrastRunways(Canvas canvas) {
    for (final rwy in airport.runways) {
      canvas.save();
      canvas.translate(rwy.centerOffset.dx, rwy.centerOffset.dy);
      final rad = rwy.headingDeg * (pi / 180.0);
      canvas.rotate(rad);

      final halfLen = rwy.lengthPixels / 2;
      final halfWidth = rwy.widthPixels / 2;
      final isMain = rwy.id == '09/27';

      // 1. Bright asphalt shoulder — high contrast against satellite image
      final shoulderPaint = Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-halfLen - 5, -halfWidth - 2.5, halfLen + 5, halfWidth + 2.5),
          const Radius.circular(2),
        ),
        shoulderPaint,
      );

      // 2. Dark charcoal runway surface
      final asphaltPaint = Paint()..color = const Color(0xFF1A2232).withValues(alpha: 0.92);
      canvas.drawRect(Rect.fromLTRB(-halfLen, -halfWidth, halfLen, halfWidth), asphaltPaint);

      // 3. Bright white border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(Rect.fromLTRB(-halfLen, -halfWidth, halfLen, halfWidth), borderPaint);

      // 4. ICAO Piano Keys (Threshold zebra stripes) — bright white
      final zebraPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
      const int stripeCount = 6;
      final stripeSpacing = (halfWidth * 2 - 4) / stripeCount;
      for (int i = 0; i < stripeCount; i++) {
        final sy = -halfWidth + 2 + i * stripeSpacing;
        canvas.drawRect(Rect.fromLTWH(-halfLen + 2.5, sy, 9, stripeSpacing * 0.55), zebraPaint);
        canvas.drawRect(Rect.fromLTWH(halfLen - 11.5, sy, 9, stripeSpacing * 0.55), zebraPaint);
      }

      // 5. Touchdown aiming blocks (500 ft marks)
      final aimPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawRect(Rect.fromLTWH(-halfLen + 26, -halfWidth + 2, 14, 2.6), aimPaint);
      canvas.drawRect(Rect.fromLTWH(-halfLen + 26, halfWidth - 4.6, 14, 2.6), aimPaint);
      canvas.drawRect(Rect.fromLTWH(halfLen - 40, -halfWidth + 2, 14, 2.6), aimPaint);
      canvas.drawRect(Rect.fromLTWH(halfLen - 40, halfWidth - 4.6, 14, 2.6), aimPaint);

      // 6. White centerline dashes
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      for (double x = -halfLen + 18; x <= halfLen - 18; x += 12) {
        canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), dashPaint);
      }

      // 7. ENTRY & TAKEOFF MARKINGS
      if (rwy.isTakeoffOnly) {
        // Dedicated 3rd Runway: Take-Off Departure Markings
        final takeoffStartX = -halfLen;
        final takeoffEnd = halfLen;

        // Glowing Amber Departure Launchpad Threshold
        final amberBar = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.95)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(takeoffStartX, -halfWidth - 1.5),
          Offset(takeoffStartX, halfWidth + 1.5),
          amberBar,
        );

        final launchGlow = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: _beaconOn ? 0.6 : 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(Offset(takeoffStartX, 0), 9.0, launchGlow);
        canvas.drawCircle(Offset(takeoffStartX, 0), 5.0, Paint()..color = const Color(0xFFF59E0B));

        // Directional Take-off Outbound Chevrons (>>>)
        final chevronPaint = Paint()
          ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        for (double cx = -halfLen + 30; cx <= halfLen - 20; cx += 32) {
          final cPath = Path()
            ..moveTo(cx - 5, -halfWidth * 0.5)
            ..lineTo(cx + 4, 0)
            ..lineTo(cx - 5, halfWidth * 0.5);
          canvas.drawPath(cPath, chevronPaint);
        }

        // Outbound departure climb dashes extending into airspace
        final climbDash = Paint()
          ..color = const Color(0xFFF59E0B).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (double x = takeoffEnd + 10; x <= takeoffEnd + 110; x += 14) {
          canvas.drawLine(Offset(x, 0), Offset(x + 7, 0), climbDash);
        }
      } else {
        // Standard Arrival Runway: Pulsing green threshold bar + glowing entry marker
        final thresholdX = isMain ? halfLen : -halfLen;
        final greenBar = Paint()
          ..color = AtcColors.ilsActiveGreen.withValues(alpha: 0.95)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(thresholdX, -halfWidth - 1.5),
          Offset(thresholdX, halfWidth + 1.5),
          greenBar,
        );

        // Glowing entry-point circle at threshold centre
        final entryGlow = Paint()
          ..color = AtcColors.ilsActiveGreen.withValues(alpha: _beaconOn ? 0.55 : 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(Offset(thresholdX, 0), 9.0, entryGlow);
        canvas.drawCircle(
          Offset(thresholdX, 0),
          5.0,
          Paint()..color = AtcColors.ilsActiveGreen,
        );

        // 8. Rollout end: Red stop bar
        final stopX = isMain ? -halfLen : halfLen;
        final redBar = Paint()
          ..color = AtcColors.tcasCriticalRed.withValues(alpha: 0.9)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(stopX, -halfWidth - 1),
          Offset(stopX, halfWidth + 1),
          redBar,
        );

        // 10. ILS approach: thin dashed centerline ONLY (no filled cone shadow)
        _renderIlsDashedCenterline(canvas, thresholdX);
      }

      // Runway ID stencil numbers
      final ids = rwy.id.split('/');
      if (ids.length == 2) {
        _drawRunwayId(canvas, ids[0], Offset(-halfLen + 16, 0));
        _drawRunwayId(canvas, ids[1], Offset(halfLen - 16, 0));
      }

      canvas.restore();
    }
  }

  void _drawRunwayId(Canvas canvas, String id, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: id,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  /// Thin dashed approach centerline — no filled cone, no shadow.
  void _renderIlsDashedCenterline(Canvas canvas, double thresholdX) {
    const ilsLength = 130.0;
    final directionSign = thresholdX > 0 ? 1 : -1;

    final ilsLinePaint = Paint()
      ..color = AtcColors.ilsActiveGreen.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 4; x < ilsLength; x += 9) {
      canvas.drawLine(
        Offset(thresholdX + x * directionSign, 0),
        Offset(thresholdX + (x + 5) * directionSign, 0),
        ilsLinePaint,
      );
    }
  }

  /// Central ATC Control Tower with flashing beacon
  void _renderAtcControlTower(Canvas canvas) {
    const towerPos = Offset(-14, -36);
    canvas.save();
    canvas.translate(towerPos.dx, towerPos.dy);

    canvas.drawCircle(Offset.zero, 7.0, Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.85));
    canvas.drawCircle(Offset.zero, 5.0, Paint()..color = const Color(0xFF64748B));
    canvas.drawCircle(Offset.zero, 3.0, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(Offset.zero, 1.8, Paint()..color = Colors.white);

    if (_beaconOn) {
      canvas.drawCircle(
        Offset.zero,
        4.0,
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.85),
      );
      canvas.drawCircle(Offset.zero, 1.0, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(Offset.zero, 1.3, Paint()..color = const Color(0xFF7F1D1D));
    }

    final towerLabel = TextPainter(
      text: const TextSpan(
        text: 'ATC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 5.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    towerLabel.paint(canvas, Offset(-towerLabel.width / 2, 7));

    canvas.restore();
  }

  void _renderHelipads(Canvas canvas) {
    for (final pad in airport.helipads) {
      canvas.save();
      canvas.translate(pad.offset.dx, pad.offset.dy);

      // Dark pad with green border
      canvas.drawCircle(Offset.zero, pad.radius, Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.85));
      canvas.drawCircle(
        Offset.zero,
        pad.radius,
        Paint()
          ..color = theme.helipadColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Pulsing entry glow for helipads too
      canvas.drawCircle(
        Offset.zero,
        pad.radius + 3,
        Paint()
          ..color = theme.helipadColor.withValues(alpha: _beaconOn ? 0.4 : 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: 'H',
          style: TextStyle(
            color: theme.helipadColor,
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }
}
