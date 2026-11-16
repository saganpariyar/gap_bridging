import 'package:flutter/material.dart';

class PlatformBlock {
  final Rect rect;
  final bool isHazard;
  const PlatformBlock(this.rect, {this.isHazard = false});
}

class WindThermal {
  final Rect zone;
  final Offset force; // upward & optional horizontal drift
  const WindThermal({required this.zone, required this.force});
}

class AnchorPad {
  final Offset position;
  final String label;
  const AnchorPad(this.position, {this.label = 'ANCHOR'});
}

class EnergyCore {
  final Offset position;
  bool collected;
  EnergyCore(this.position, {this.collected = false});
}

class Particle {
  Offset pos;
  Offset vel;
  Color color;
  double radius;
  double life;
  double maxLife;

  Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.radius,
    required this.maxLife,
  }) : life = maxLife;
}

class GapLevelDefinition {
  final int levelNumber;
  final String title;
  final String subtitle;
  final String hint;
  final Size worldSize;
  final Offset lightSpawn;
  final Offset heavySpawn;
  final Rect goalZone;
  final double parSeconds;
  final List<PlatformBlock> platforms;
  final List<WindThermal> thermals;
  final List<AnchorPad> anchorPads;
  final List<Offset> corePositions;

  const GapLevelDefinition({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.worldSize,
    required this.lightSpawn,
    required this.heavySpawn,
    required this.goalZone,
    required this.parSeconds,
    required this.platforms,
    required this.thermals,
    required this.anchorPads,
    required this.corePositions,
  });
}
