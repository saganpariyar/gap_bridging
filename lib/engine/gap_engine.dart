import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customization.dart';
import '../models/game_models.dart';
import '../models/levels.dart';
import '../services/storage_service.dart';

enum ActiveCharacter { light, heavy }

class GapEngine extends ChangeNotifier {
  static const double gravity = 880.0;
  static const double lightRadius = 16.0;
  static const double heavyRadius = 24.0;

  late GapLevelDefinition level;
  int currentLevelIndex = 0;

  // Player states
  Offset lightPos = Offset.zero;
  Offset lightVel = Offset.zero;
  bool lightGrounded = false;
  bool lightGliding = false;
  bool lightAnchored = false;
  double lightFacing = 1.0;

  Offset heavyPos = Offset.zero;
  Offset heavyVel = Offset.zero;
  bool heavyGrounded = false;
  double heavyFacing = 1.0;

  double ropeLength = 220.0;
  double currentTension = 0.0; // 0..1

  ActiveCharacter activeChar = ActiveCharacter.light;
  bool twoPlayerMode = StorageService.twoPlayerMode;

  // Input flags
  double lightMoveInput = 0.0;
  bool lightJumpHeld = false;
  double heavyMoveInput = 0.0;
  bool heavyReelIn = false;
  bool heavySlackOut = false;

  // Aiming drag support for Light launch/glide
  Offset? dragAimStart;
  Offset? dragAimCurrent;

  // Collectibles, particles, camera & game state
  List<EnergyCore> cores = [];
  List<Particle> particles = [];
  double elapsedSeconds = 0.0;
  double animTime = 0.0;
  double shakeIntensity = 0.0;
  String statusBanner = 'Glide Light across the chasm and lock Anchor!';
  double bannerTimer = 3.5;

  bool isLevelComplete = false;
  bool isFailed = false;
  String failReason = '';
  int earnedStars = 0;

  // Smooth camera state
  Offset camCenter = const Offset(400, 320);
  double camZoom = 1.0;

  GapEngine({int initialLevelIndex = 0}) {
    loadLevel(initialLevelIndex);
  }

  void loadLevel(int index) {
    currentLevelIndex = index.clamp(0, GapLevels.all.length - 1);
    level = GapLevels.all[currentLevelIndex];
    lightPos = level.lightSpawn;
    lightVel = Offset.zero;
    lightGrounded = false;
    lightGliding = false;
    lightAnchored = false;
    lightFacing = 1.0;

    heavyPos = level.heavySpawn;
    heavyVel = Offset.zero;
    heavyGrounded = false;
    heavyFacing = 1.0;

    ropeLength = 220.0;
    currentTension = 0.0;
    activeChar = ActiveCharacter.light;

    lightMoveInput = 0.0;
    lightJumpHeld = false;
    heavyMoveInput = 0.0;
    heavyReelIn = false;
    heavySlackOut = false;
    dragAimStart = null;
    dragAimCurrent = null;

    cores = level.corePositions.map((p) => EnergyCore(p)).toList();
    particles = [];
    elapsedSeconds = 0.0;
    shakeIntensity = 0.0;
    statusBanner = level.hint;
    bannerTimer = 5.0;

    isLevelComplete = false;
    isFailed = false;
    failReason = '';
    earnedStars = 0;

    camCenter = Offset(
      (lightPos.dx + heavyPos.dx) * 0.5 + 120,
      (lightPos.dy + heavyPos.dy) * 0.5,
    );
    notifyListeners();
  }

  void resetLevel() => loadLevel(currentLevelIndex);

  void toggleControlMode() {
    twoPlayerMode = !twoPlayerMode;
    StorageService.twoPlayerMode = twoPlayerMode;
    StorageService.save();
    notifyListeners();
  }

  void swapActiveCharacter() {
    activeChar = activeChar == ActiveCharacter.light
        ? ActiveCharacter.heavy
        : ActiveCharacter.light;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void jumpLight() {
    if (isLevelComplete || isFailed) return;
    if (lightAnchored) {
      lightAnchored = false;
      _showBanner('Anchor released!');
    }
    if (lightGrounded) {
      lightVel = Offset(lightVel.dx, -460.0);
      lightGrounded = false;
      _spawnBurst(lightPos + const Offset(0, 14), lightColor, 10);
      HapticFeedback.lightImpact();
    }
    lightJumpHeld = true;
    notifyListeners();
  }

  void jumpHeavy() {
    if (isLevelComplete || isFailed) return;
    if (heavyGrounded) {
      heavyVel = Offset(heavyVel.dx, -260.0);
      heavyGrounded = false;
      _spawnBurst(heavyPos + const Offset(0, 20), heavyColor, 8);
      HapticFeedback.lightImpact();
    }
    notifyListeners();
  }

  void toggleLightAnchor() {
    if (isLevelComplete || isFailed) return;
    if (lightAnchored) {
      lightAnchored = false;
      _showBanner('Anchor unlocked — Light free to move');
      HapticFeedback.selectionClick();
      notifyListeners();
      return;
    }

    // Check if near an AnchorPad or grounded on a platform
    AnchorPad? nearestPad;
    double bestDist = 58.0;
    for (final pad in level.anchorPads) {
      final d = (pad.position - lightPos).distance;
      if (d < bestDist) {
        bestDist = d;
        nearestPad = pad;
      }
    }

    if (nearestPad != null) {
      lightPos = nearestPad.position;
      lightVel = Offset.zero;
      lightAnchored = true;
      lightGliding = false;
      ropeLength = (heavyPos - lightPos).distance.clamp(140.0, 420.0);
      _spawnBurst(lightPos, const Color(0xFF38BDF8), 18);
      shakeIntensity = 4.0;
      _showBanner('Locked onto ${nearestPad.label}! Swing & Reel Heavy across!');
      if (!twoPlayerMode) activeChar = ActiveCharacter.heavy;
      HapticFeedback.mediumImpact();
    } else if (lightGrounded) {
      lightVel = Offset.zero;
      lightAnchored = true;
      lightGliding = false;
      ropeLength = (heavyPos - lightPos).distance.clamp(140.0, 420.0);
      _spawnBurst(lightPos, const Color(0xFF38BDF8), 14);
      _showBanner('Field Anchor locked! Reel Heavy across!');
      if (!twoPlayerMode) activeChar = ActiveCharacter.heavy;
      HapticFeedback.mediumImpact();
    } else {
      _showBanner('Land on a cliff or near an Anchor Pad to lock!');
    }
    notifyListeners();
  }

  void launchLightFromDrag(Offset worldStart, Offset worldEnd) {
    if (isLevelComplete || isFailed) return;
    final delta = worldStart - worldEnd; // slingshot pull or aim vector
    final raw = delta.distance < 12 ? (worldEnd - lightPos) : delta;
    if (raw.distance < 10) return;
    if (lightAnchored) lightAnchored = false;
    final dir = raw / raw.distance;
    final power = (raw.distance * 4.5).clamp(260.0, 560.0);
    lightVel = Offset(dir.dx * power, (dir.dy * power).clamp(-540.0, 140.0));
    lightGrounded = false;
    lightGliding = true;
    lightFacing = lightVel.dx >= 0 ? 1.0 : -1.0;
    _spawnBurst(lightPos, lightColor, 14);
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  Color get lightColor =>
      CustomizationCatalog.lightProfiles[StorageService.lightProfileIndex].primaryColor;
  Color get heavyColor =>
      CustomizationCatalog.heavyProfiles[StorageService.heavyProfileIndex].primaryColor;

  void _showBanner(String text) {
    statusBanner = text;
    bannerTimer = 3.2;
  }

  void step(double dt) {
    final clampedDt = dt.clamp(0.0, 0.033);
    animTime += clampedDt;
    if (bannerTimer > 0) bannerTimer = math.max(0.0, bannerTimer - clampedDt);
    if (shakeIntensity > 0) shakeIntensity = math.max(0.0, shakeIntensity - clampedDt * 18.0);

    _updateParticles(clampedDt);

    if (isLevelComplete || isFailed) {
      notifyListeners();
      return;
    }

    elapsedSeconds += clampedDt;

    // 1. Update Light Player
    if (!lightAnchored) {
      final isGlidingNow = !lightGrounded && lightJumpHeld && lightVel.dy > -40;
      lightGliding = isGlidingNow;

      final targetVx = lightMoveInput * (lightGliding ? 305.0 : 255.0);
      if (lightMoveInput.abs() > 0.05) lightFacing = lightMoveInput.sign;
      final accel = lightGrounded ? 16.0 : (lightGliding ? 7.5 : 10.0);
      lightVel = Offset(
        lightVel.dx + (targetVx - lightVel.dx) * math.min(1.0, accel * clampedDt),
        lightVel.dy,
      );

      final effGravity = lightGliding ? gravity * 0.16 : gravity;
      double vy = lightVel.dy + effGravity * clampedDt;

      // Apply wind thermals
      for (final w in level.thermals) {
        if (w.zone.contains(lightPos)) {
          final glideBoost = lightGliding ? 1.3 : 0.85;
          lightVel = Offset(lightVel.dx + w.force.dx * clampedDt, vy);
          vy += w.force.dy * glideBoost * clampedDt;
          vy = math.max(vy, -280.0);
          if (animTime * 20 % 1 < 0.25) {
            _spawnParticle(lightPos, lightColor, 2.5, 0.45);
          }
        }
      }

      if (lightGliding && vy > 48.0) vy = 48.0;
      lightVel = Offset(lightVel.dx, vy);
      lightPos += lightVel * clampedDt;
      lightGrounded = _resolveCollisions(isLight: true);

      // Trail when gliding
      if (lightGliding && (animTime * 30).floor() % 2 == 0) {
        _spawnParticle(lightPos + Offset(-lightFacing * 10, 0), lightColor, 3.0, 0.35);
      }
    } else {
      lightVel = Offset.zero;
    }

    // 2. Update Heavy Player
    final heavyTargetVx = heavyMoveInput * (heavyGrounded ? 175.0 : 220.0);
    if (heavyMoveInput.abs() > 0.05) heavyFacing = heavyMoveInput.sign;

    if (heavyGrounded) {
      heavyVel = Offset(
        heavyVel.dx + (heavyTargetVx - heavyVel.dx) * math.min(1.0, 12.0 * clampedDt),
        heavyVel.dy + gravity * clampedDt,
      );
    } else {
      // Pendulum swing pump force + gravity
      double vx = heavyVel.dx + heavyMoveInput * 320.0 * clampedDt;
      double vy = heavyVel.dy + gravity * clampedDt;
      vx *= (1.0 - 0.15 * clampedDt);
      heavyVel = Offset(vx, vy);
    }

    // Adjust winch length when reeling or slacking
    if (heavyReelIn) {
      ropeLength = math.max(75.0, ropeLength - 175.0 * clampedDt);
    }
    if (heavySlackOut) {
      ropeLength = math.min(430.0, ropeLength + 175.0 * clampedDt);
    }

    heavyPos += heavyVel * clampedDt;
    heavyGrounded = _resolveCollisions(isLight: false);

    // 3. Apply Tether Constraint
    final diff = heavyPos - lightPos;
    final dist = diff.distance;
    if (lightAnchored) {
      currentTension = (dist / math.max(1.0, ropeLength)).clamp(0.0, 1.0);
      if (dist > ropeLength && dist > 0.001) {
        final dir = diff / dist;
        heavyPos = lightPos + dir * ropeLength;
        final radialVel = heavyVel.dx * dir.dx + heavyVel.dy * dir.dy;
        if (radialVel > 0) {
          heavyVel = Offset(
            heavyVel.dx - dir.dx * radialVel,
            heavyVel.dy - dir.dy * radialVel,
          );
        }
        // Re-resolve in case rope pulled heavy into a platform
        if (_resolveCollisions(isLight: false)) heavyGrounded = true;
      }
    } else {
      // Unanchored soft tether when not gliding across
      final maxUnanchored = lightGliding ? 520.0 : 340.0;
      currentTension = (dist / maxUnanchored).clamp(0.0, 1.0);
      if (dist > maxUnanchored && dist > 0.001) {
        final dir = diff / dist;
        final excess = dist - maxUnanchored;
        if (lightGliding) {
          // Soft elastic tug warning
          lightPos += dir * (excess * 0.25);
        } else {
          lightPos += dir * (excess * 0.65);
          heavyPos -= dir * (excess * 0.35);
          final relVel = lightVel - heavyVel;
          final radial = relVel.dx * dir.dx + relVel.dy * dir.dy;
          if (radial < 0) {
            lightVel -= dir * (radial * 0.6);
            heavyVel += dir * (radial * 0.3);
          }
        }
      }
    }

    // 4. Collect Energy Cores
    for (final core in cores) {
      if (!core.collected &&
          ((core.position - lightPos).distance < lightRadius + 18 ||
              (core.position - heavyPos).distance < heavyRadius + 18)) {
        core.collected = true;
        _spawnBurst(core.position, const Color(0xFFFBBF24), 16);
        HapticFeedback.lightImpact();
      }
    }

    // 5. Check Hazards / Abyss Fall
    if (lightPos.dy > level.worldSize.height + 70 ||
        heavyPos.dy > level.worldSize.height + 70) {
      _triggerFail(
        lightPos.dy > level.worldSize.height + 70
            ? 'Light fell into the canyon abyss!'
            : 'Heavy tumbled into the chasm! Anchor Light first.',
      );
      return;
    }

    // 6. Check Goal Win Condition (both reach exit zone)
    final lightInGoal = level.goalZone.inflate(16).contains(lightPos);
    final heavyInGoal = level.goalZone.inflate(22).contains(heavyPos);
    if (lightInGoal && heavyInGoal) {
      isLevelComplete = true;
      final collectedCount = cores.where((c) => c.collected).length;
      earnedStars = math.max(1, collectedCount);
      if (collectedCount == 3 && elapsedSeconds <= level.parSeconds) {
        earnedStars = 3;
      }
      _spawnBurst(level.goalZone.center, const Color(0xFF34D399), 34);
      shakeIntensity = 6.0;
      _persistWin();
    }

    // 7. Smooth dynamic camera update
    final midX = (lightPos.dx + heavyPos.dx) * 0.5;
    final midY = (lightPos.dy + heavyPos.dy) * 0.5;
    camCenter = Offset(
      camCenter.dx + (midX - camCenter.dx) * math.min(1.0, 5.5 * clampedDt),
      camCenter.dy + (midY - camCenter.dy) * math.min(1.0, 5.5 * clampedDt),
    );

    notifyListeners();
  }

  void _persistWin() {
    final lvl = level.levelNumber;
    final prevStars = StorageService.levelStars[lvl] ?? 0;
    if (earnedStars > prevStars) StorageService.levelStars[lvl] = earnedStars;
    final ms = (elapsedSeconds * 1000).round();
    final prevMs = StorageService.bestTimeMs[lvl];
    if (prevMs == null || ms < prevMs) StorageService.bestTimeMs[lvl] = ms;
    if (lvl >= StorageService.unlockedLevel && lvl < GapLevels.all.length) {
      StorageService.unlockedLevel = lvl + 1;
    }
    StorageService.save();
  }

  void _triggerFail(String reason) {
    isFailed = true;
    failReason = reason;
    shakeIntensity = 9.0;
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  bool _resolveCollisions({required bool isLight}) {
    var pos = isLight ? lightPos : heavyPos;
    var vel = isLight ? lightVel : heavyVel;
    final r = isLight ? lightRadius : heavyRadius;
    bool grounded = false;

    for (final plat in level.platforms) {
      final rect = plat.rect;
      final closestX = pos.dx.clamp(rect.left, rect.right);
      final closestY = pos.dy.clamp(rect.top, rect.bottom);
      final dx = pos.dx - closestX;
      final dy = pos.dy - closestY;
      final distSq = dx * dx + dy * dy;

      if (distSq < r * r) {
        if (plat.isHazard) {
          _triggerFail('Struck a jagged crystal hazard!');
          return false;
        }
        final dist = math.sqrt(distSq);
        if (dist > 0.0001) {
          final nx = dx / dist;
          final ny = dy / dist;
          final overlap = r - dist;
          pos += Offset(nx * overlap, ny * overlap);
          final vn = vel.dx * nx + vel.dy * ny;
          if (vn < 0) {
            vel -= Offset(nx * vn, ny * vn);
          }
          if (ny < -0.65) grounded = true;
        } else {
          // Center inside rect: push out vertically upward
          pos = Offset(pos.dx, rect.top - r);
          if (vel.dy > 0) vel = Offset(vel.dx, 0);
          grounded = true;
        }
      }
    }

    // Clamp horizontally within world bounds
    if (pos.dx < r) {
      pos = Offset(r, pos.dy);
      if (vel.dx < 0) vel = Offset(0, vel.dy);
    } else if (pos.dx > level.worldSize.width - r) {
      pos = Offset(level.worldSize.width - r, pos.dy);
      if (vel.dx > 0) vel = Offset(0, vel.dy);
    }

    if (isLight) {
      lightPos = pos;
      lightVel = vel;
    } else {
      heavyPos = pos;
      heavyVel = vel;
    }
    return grounded;
  }

  void _spawnParticle(Offset pos, Color color, double radius, double life) {
    final rng = math.Random();
    particles.add(Particle(
      pos: pos,
      vel: Offset((rng.nextDouble() - 0.5) * 70, (rng.nextDouble() - 0.5) * 70 - 20),
      color: color,
      radius: radius,
      maxLife: life,
    ));
  }

  void _spawnBurst(Offset pos, Color color, int count) {
    final rng = math.Random();
    for (int i = 0; i < count; i++) {
      final ang = (i / count) * math.pi * 2 + rng.nextDouble() * 0.4;
      final spd = 70 + rng.nextDouble() * 140;
      particles.add(Particle(
        pos: pos,
        vel: Offset(math.cos(ang) * spd, math.sin(ang) * spd),
        color: color,
        radius: 2.5 + rng.nextDouble() * 3.5,
        maxLife: 0.45 + rng.nextDouble() * 0.35,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
      } else {
        p.pos += p.vel * dt;
        p.vel *= (1.0 - 1.5 * dt);
      }
    }
  }
}
