import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/gap_engine.dart';
import '../models/customization.dart';
import '../services/storage_service.dart';

class CameraTransform {
  final double scale;
  final Offset translation;
  const CameraTransform(this.scale, this.translation);

  Offset worldToScreen(Offset world) => world * scale + translation;
  Offset screenToWorld(Offset screen) => (screen - translation) / scale;
}

CameraTransform computeGapCamera(GapEngine engine, Size viewport) {
  final spanX = (engine.lightPos.dx - engine.heavyPos.dx).abs() + 420.0;
  final spanY = (engine.lightPos.dy - engine.heavyPos.dy).abs() + 340.0;
  final fitX = viewport.width / math.max(spanX, 620.0);
  final fitY = viewport.height / math.max(spanY, 440.0);
  final scale = math.min(fitX, fitY).clamp(0.45, 1.35);

  final worldW = engine.level.worldSize.width;
  final worldH = engine.level.worldSize.height;
  double cx = engine.camCenter.dx;
  double cy = engine.camCenter.dy;

  final halfViewW = (viewport.width * 0.5) / scale;
  final halfViewH = (viewport.height * 0.5) / scale;
  if (worldW > halfViewW * 2) {
    cx = cx.clamp(halfViewW, worldW - halfViewW);
  } else {
    cx = worldW * 0.5;
  }
  if (worldH > halfViewH * 2) {
    cy = cy.clamp(halfViewH - 40, worldH - halfViewH + 20);
  } else {
    cy = worldH * 0.5;
  }

  final tx = viewport.width * 0.5 - cx * scale;
  final ty = viewport.height * 0.5 - cy * scale;
  return CameraTransform(scale, Offset(tx, ty));
}

class GapPainter extends CustomPainter {
  final GapEngine engine;
  GapPainter(this.engine) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = CustomizationCatalog.backgrounds[StorageService.backgroundIndex];
    final lightSkin = CustomizationCatalog.lightProfiles[StorageService.lightProfileIndex];
    final heavySkin = CustomizationCatalog.heavyProfiles[StorageService.heavyProfileIndex];
    final tetherSkin = CustomizationCatalog.tetherStyles[StorageService.tetherStyleIndex];

    final cam = computeGapCamera(engine, size);

    // Ambient floating canyon particles in screen space
    _drawAmbientParticles(canvas, size, bg.accentColor);

    canvas.save();
    if (engine.shakeIntensity > 0.1) {
      final sx = math.sin(engine.animTime * 60) * engine.shakeIntensity;
      final sy = math.cos(engine.animTime * 53) * engine.shakeIntensity;
      canvas.translate(sx, sy);
    }
    canvas.translate(cam.translation.dx, cam.translation.dy);
    canvas.scale(cam.scale);

    // 1. Wind Thermals
    for (final thermal in engine.level.thermals) {
      _drawWindThermal(canvas, thermal.zone, bg.accentColor);
    }

    // 2. Platforms & Hazards
    for (final plat in engine.level.platforms) {
      _drawPlatform(canvas, plat.rect, plat.isHazard, bg);
    }

    // 3. Anchor Pads
    for (final pad in engine.level.anchorPads) {
      _drawAnchorPad(canvas, pad.position, pad.label, lightSkin.glowColor);
    }

    // 4. Exit Goal Portal
    _drawGoalPortal(canvas, engine.level.goalZone, bg.accentColor);

    // 5. Energy Cores
    for (final core in engine.cores) {
      if (!core.collected) _drawEnergyCore(canvas, core.position);
    }

    // 6. Tether Cable
    _drawTether(canvas, engine.lightPos, engine.heavyPos, tetherSkin, engine.currentTension, engine.lightAnchored);

    // 7. Aiming Arc Preview (if dragging)
    if (engine.dragAimStart != null && engine.dragAimCurrent != null) {
      _drawAimPreview(canvas, engine.lightPos, engine.dragAimStart!, engine.dragAimCurrent!, lightSkin.glowColor);
    }

    // 8. Heavy & Light Characters
    _drawHeavyCharacter(canvas, engine.heavyPos, heavySkin, engine.heavyFacing, engine.activeChar == ActiveCharacter.heavy && !engine.twoPlayerMode);
    _drawLightCharacter(canvas, engine.lightPos, lightSkin, engine.lightFacing, engine.lightGliding, engine.lightAnchored, engine.activeChar == ActiveCharacter.light && !engine.twoPlayerMode);

    // 9. World-space Particle Bursts
    for (final p in engine.particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.radius * (0.5 + 0.5 * alpha),
        Paint()..color = p.color.withValues(alpha: alpha * 0.9),
      );
    }

    canvas.restore();
  }

  void _drawAmbientParticles(Canvas canvas, Size size, Color accent) {
    final p = Paint()..color = accent.withValues(alpha: 0.25);
    for (int i = 0; i < 18; i++) {
      final x = ((i * 97.3 + engine.animTime * (14 + (i % 5) * 6)) % (size.width + 40)) - 20;
      final y = ((i * 131.7 + math.sin(engine.animTime + i) * 20) % size.height);
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), p);
    }
  }

  void _drawWindThermal(Canvas canvas, Rect zone, Color accent) {
    final grad = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        accent.withValues(alpha: 0.02),
        accent.withValues(alpha: 0.16),
        accent.withValues(alpha: 0.02),
      ],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(zone, const Radius.circular(18)),
      Paint()..shader = grad.createShader(zone),
    );
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final lx = zone.left + zone.width * (0.18 + i * 0.16);
      final offset = (engine.animTime * 140 + i * 52) % zone.height;
      final yBot = zone.bottom - offset;
      final yTop = math.max(zone.top, yBot - 36);
      canvas.drawLine(Offset(lx, yBot), Offset(lx + 4, yTop), linePaint);
    }
  }

  void _drawPlatform(Canvas canvas, Rect rect, bool isHazard, BackgroundThemeOption bg) {
    if (isHazard) {
      final body = Paint()..color = const Color(0xFF450A0A);
      final glow = Paint()
        ..color = const Color(0xFFF43F5E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), body);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), glow);
      // Hazard spikes at bottom/edges
      final spikePaint = Paint()..color = const Color(0xFFFB7185);
      for (double x = rect.left + 8; x < rect.right - 12; x += 22) {
        final path = Path()
          ..moveTo(x, rect.bottom)
          ..lineTo(x + 9, rect.bottom + 14)
          ..lineTo(x + 18, rect.bottom)
          ..close();
        canvas.drawPath(path, spikePaint);
      }
      return;
    }

    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rr, Paint()..color = bg.platformBodyColor);
    // Top glowing ledge trim
    final capRect = Rect.fromLTWH(rect.left, rect.top, rect.width, math.min(14, rect.height));
    canvas.drawRRect(
      RRect.fromRectAndCorners(capRect, topLeft: const Radius.circular(10), topRight: const Radius.circular(10)),
      Paint()..color = bg.platformTopColor,
    );
    canvas.drawLine(
      Offset(rect.left + 6, rect.top + 1.5),
      Offset(rect.right - 6, rect.top + 1.5),
      Paint()
        ..color = bg.accentColor.withValues(alpha: 0.75)
        ..strokeWidth = 2.5,
    );
  }

  void _drawAnchorPad(Canvas canvas, Offset pos, String label, Color glow) {
    final pulse = 0.7 + 0.3 * math.sin(engine.animTime * 4.5);
    canvas.drawCircle(
      pos,
      26,
      Paint()..color = glow.withValues(alpha: 0.16 * pulse),
    );
    canvas.drawCircle(
      pos,
      14,
      Paint()
        ..color = glow.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(pos, 5, Paint()..color = Colors.white);
  }

  void _drawGoalPortal(Canvas canvas, Rect zone, Color accent) {
    final center = zone.center;
    final pulse = 1.0 + 0.08 * math.sin(engine.animTime * 5);
    final outerR = (zone.width * 0.45) * pulse;
    canvas.drawCircle(
      center,
      outerR + 10,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF34D399).withValues(alpha: 0.48),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR + 10)),
    );
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = const Color(0xFF34D399)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      center,
      outerR * 0.65,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.3),
    );
  }

  void _drawEnergyCore(Canvas canvas, Offset pos) {
    final bob = math.sin(engine.animTime * 4 + pos.dx * 0.03) * 5;
    final p = pos + Offset(0, bob);
    canvas.drawCircle(p, 16, Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.22));
    final path = Path()
      ..moveTo(p.dx, p.dy - 11)
      ..lineTo(p.dx + 9, p.dy)
      ..lineTo(p.dx, p.dy + 11)
      ..lineTo(p.dx - 9, p.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawTether(Canvas canvas, Offset a, Offset b, TetherStyleOption style, double tension, bool anchored) {
    final color = tension > 0.88
        ? Color.lerp(style.primaryColor, const Color(0xFFFB7185), (tension - 0.88) / 0.12)!
        : style.primaryColor;

    // Glow aura
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color.withValues(alpha: anchored ? 0.38 : 0.20)
        ..strokeWidth = anchored ? 9.0 : 6.0
        ..strokeCap = StrokeCap.round,
    );

    if (style.pattern == TetherPattern.plasma || style.pattern == TetherPattern.runic) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
      final dist = (b - a).distance;
      final steps = math.max(3, (dist / 24).floor());
      for (int i = 1; i < steps; i++) {
        final t = ((i / steps) + engine.animTime * 0.6) % 1.0;
        final pt = Offset.lerp(a, b, t)!;
        canvas.drawCircle(pt, style.pattern == TetherPattern.runic ? 3.5 : 2.6, Paint()..color = style.pulseColor);
      }
    } else if (style.pattern == TetherPattern.steel) {
      canvas.drawLine(a, b, Paint()..color = color..strokeWidth = 4.0);
      final dist = (b - a).distance;
      final steps = math.max(2, (dist / 16).floor());
      for (int i = 0; i <= steps; i++) {
        final pt = Offset.lerp(a, b, i / steps)!;
        canvas.drawCircle(pt, 2.2, Paint()..color = style.pulseColor);
      }
    } else {
      // Mag-chain capsules
      final dist = (b - a).distance;
      final steps = math.max(3, (dist / 20).floor());
      for (int i = 0; i <= steps; i++) {
        final pt = Offset.lerp(a, b, i / steps)!;
        canvas.drawCircle(pt, 3.8, Paint()..color = color);
        canvas.drawCircle(pt, 1.8, Paint()..color = style.pulseColor);
      }
    }
  }

  void _drawAimPreview(Canvas canvas, Offset origin, Offset start, Offset current, Color color) {
    final delta = start - current;
    if (delta.distance < 10) return;
    final dir = delta / delta.distance;
    final power = (delta.distance * 4.5).clamp(260.0, 560.0);
    final v0 = Offset(dir.dx * power, (dir.dy * power).clamp(-540.0, 140.0));
    final dotPaint = Paint()..color = color.withValues(alpha: 0.85);
    for (int i = 1; i <= 10; i++) {
      final t = i * 0.08;
      final pt = Offset(
        origin.dx + v0.dx * t,
        origin.dy + v0.dy * t + 0.5 * (GapEngine.gravity * 0.25) * t * t,
      );
      canvas.drawCircle(pt, 4.0 - i * 0.25, dotPaint);
    }
  }

  void _drawLightCharacter(
    Canvas canvas,
    Offset pos,
    LightProfile skin,
    double facing,
    bool gliding,
    bool anchored,
    bool isSelected,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    if (isSelected) {
      canvas.drawCircle(
        Offset.zero,
        24 + math.sin(engine.animTime * 6) * 2,
        Paint()
          ..color = skin.glowColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Anchor tripod spikes when locked
    if (anchored) {
      final legPaint = Paint()
        ..color = skin.glowColor
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-6, 8), const Offset(-18, 22), legPaint);
      canvas.drawLine(const Offset(6, 8), const Offset(18, 22), legPaint);
      canvas.drawCircle(Offset.zero, 20, Paint()..color = skin.glowColor.withValues(alpha: 0.22));
    }

    // Deployed aerodynamic wings when gliding
    if (gliding) {
      final wingPath = Path()
        ..moveTo(0, -4)
        ..lineTo(-facing * 32, -16)
        ..lineTo(-facing * 20, 4)
        ..close();
      canvas.drawPath(wingPath, Paint()..color = skin.glowColor.withValues(alpha: 0.88));
      canvas.drawPath(
        wingPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Body aura & sphere
    canvas.drawCircle(Offset.zero, 19, Paint()..color = skin.glowColor.withValues(alpha: 0.24));
    canvas.drawCircle(Offset.zero, GapEngine.lightRadius, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(
      Offset.zero,
      GapEngine.lightRadius,
      Paint()
        ..color = skin.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    // Sleek glowing visor
    final visor = Rect.fromCenter(center: Offset(facing * 4, -2), width: 14, height: 8);
    canvas.drawRRect(RRect.fromRectAndRadius(visor, const Radius.circular(4)), Paint()..color = skin.glowColor);
    canvas.restore();
  }

  void _drawHeavyCharacter(
    Canvas canvas,
    Offset pos,
    HeavyProfile skin,
    double facing,
    bool isSelected,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    if (isSelected) {
      canvas.drawCircle(
        Offset.zero,
        32 + math.sin(engine.animTime * 5) * 2,
        Paint()
          ..color = skin.glowColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    // Armored mech silhouette
    canvas.drawCircle(Offset.zero, 28, Paint()..color = skin.primaryColor.withValues(alpha: 0.22));
    canvas.drawCircle(Offset.zero, GapEngine.heavyRadius, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(
      Offset.zero,
      GapEngine.heavyRadius,
      Paint()
        ..color = skin.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2,
    );

    // Shoulder armor caps & chest core
    canvas.drawCircle(const Offset(-18, -4), 8, Paint()..color = skin.primaryColor);
    canvas.drawCircle(const Offset(18, -4), 8, Paint()..color = skin.primaryColor);
    canvas.drawCircle(const Offset(0, 7), 6, Paint()..color = skin.glowColor);

    // Friendly curved visor
    final visor = Rect.fromCenter(center: Offset(facing * 3, -5), width: 22, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(visor, const Radius.circular(5)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(facing * 3 - 4, -5), 2.5, Paint()..color = skin.glowColor);
    canvas.drawCircle(Offset(facing * 3 + 4, -5), 2.5, Paint()..color = skin.glowColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GapPainter oldDelegate) => true;
}
