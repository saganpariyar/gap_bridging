import 'package:flutter/material.dart';
import 'game_models.dart';

class GapLevels {
  static const List<GapLevelDefinition> all = [
    GapLevelDefinition(
      levelNumber: 1,
      title: 'First Chasm',
      subtitle: 'Glide, Lock & Swing Across',
      hint: 'Hold GLIDE with Light to cross the chasm, press ANCHOR on the far pad, then swap to Heavy and swing + REEL IN!',
      worldSize: Size(1240, 640),
      lightSpawn: Offset(165, 360),
      heavySpawn: Offset(95, 355),
      goalZone: Rect.fromLTWH(1060, 290, 96, 110),
      parSeconds: 28,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 400, 290, 240)),
        PlatformBlock(Rect.fromLTWH(780, 400, 440, 240)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(450, 200, 170, 260), force: Offset(35, -720)),
      ],
      anchorPads: [
        AnchorPad(Offset(835, 384), label: 'CLIFF LOCK'),
      ],
      corePositions: [
        Offset(535, 250),
        Offset(535, 440),
        Offset(950, 345),
      ],
    ),
    GapLevelDefinition(
      levelNumber: 2,
      title: 'Thermal Drift',
      subtitle: 'Ride the Updraft Above the Spire',
      hint: 'Ride the glowing Wind Thermal high with Light to reach the upper ledge, then swing Heavy below the rock arch!',
      worldSize: Size(1320, 680),
      lightSpawn: Offset(170, 430),
      heavySpawn: Offset(95, 425),
      goalZone: Rect.fromLTWH(1140, 210, 96, 110),
      parSeconds: 34,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 470, 280, 210)),
        PlatformBlock(Rect.fromLTWH(590, 0, 110, 260)), // hanging rock arch
        PlatformBlock(Rect.fromLTWH(580, 520, 130, 160)), // mid chasm tooth
        PlatformBlock(Rect.fromLTWH(880, 320, 420, 360)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(380, 180, 160, 330), force: Offset(55, -800)),
      ],
      anchorPads: [
        AnchorPad(Offset(930, 304), label: 'HIGH LOCK'),
      ],
      corePositions: [
        Offset(460, 230),
        Offset(645, 390),
        Offset(1030, 265),
      ],
    ),
    GapLevelDefinition(
      levelNumber: 3,
      title: 'Twin Cliffs',
      subtitle: 'Two Chasms, One Central Spire',
      hint: 'Anchor on the center spire to bring Heavy onto the island, unlock Light, then bridge the second chasm!',
      worldSize: Size(1460, 660),
      lightSpawn: Offset(155, 380),
      heavySpawn: Offset(85, 375),
      goalZone: Rect.fromLTWH(1290, 250, 96, 110),
      parSeconds: 45,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 420, 250, 240)),
        PlatformBlock(Rect.fromLTWH(610, 400, 230, 260)),
        PlatformBlock(Rect.fromLTWH(1140, 360, 300, 300)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(360, 210, 140, 240), force: Offset(30, -720)),
        WindThermal(zone: Rect.fromLTWH(920, 190, 140, 240), force: Offset(40, -760)),
      ],
      anchorPads: [
        AnchorPad(Offset(665, 384), label: 'RELAY 1'),
        AnchorPad(Offset(1185, 344), label: 'SUMMIT LOCK'),
      ],
      corePositions: [
        Offset(430, 270),
        Offset(725, 340),
        Offset(990, 250),
      ],
    ),
    GapLevelDefinition(
      levelNumber: 4,
      title: 'Stalactite Arch',
      subtitle: 'Slacken Low, Reel High',
      hint: 'After locking Light past the cavern wall, SLACK rope slightly so Heavy swings under the stalactites, then REEL IN!',
      worldSize: Size(1380, 680),
      lightSpawn: Offset(165, 330),
      heavySpawn: Offset(90, 325),
      goalZone: Rect.fromLTWH(1210, 250, 96, 110),
      parSeconds: 38,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 370, 270, 310)),
        PlatformBlock(Rect.fromLTWH(560, 0, 180, 355), isHazard: true), // jagged crystal stalactite
        PlatformBlock(Rect.fromLTWH(960, 360, 400, 320)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(360, 260, 150, 280), force: Offset(60, -760)),
        WindThermal(zone: Rect.fromLTWH(780, 190, 140, 290), force: Offset(45, -780)),
      ],
      anchorPads: [
        AnchorPad(Offset(1010, 344), label: 'CAVERN LOCK'),
      ],
      corePositions: [
        Offset(435, 390),
        Offset(650, 470),
        Offset(1090, 305),
      ],
    ),
    GapLevelDefinition(
      levelNumber: 5,
      title: 'Crosswind Gorge',
      subtitle: 'Thread the Storm Currents',
      hint: 'Use the twin updrafts to soar past the floating hazard pylon, lock onto the upper cliff, and reel Heavy clear!',
      worldSize: Size(1480, 700),
      lightSpawn: Offset(155, 440),
      heavySpawn: Offset(85, 435),
      goalZone: Rect.fromLTWH(1310, 190, 96, 110),
      parSeconds: 46,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 480, 240, 220)),
        PlatformBlock(Rect.fromLTWH(560, 270, 90, 150), isHazard: true),
        PlatformBlock(Rect.fromLTWH(800, 490, 150, 210)),
        PlatformBlock(Rect.fromLTWH(1160, 300, 300, 400)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(330, 210, 150, 320), force: Offset(50, -820)),
        WindThermal(zone: Rect.fromLTWH(980, 140, 140, 320), force: Offset(40, -820)),
      ],
      anchorPads: [
        AnchorPad(Offset(855, 474), label: 'MID PAD'),
        AnchorPad(Offset(1200, 284), label: 'PEAK LOCK'),
      ],
      corePositions: [
        Offset(410, 210),
        Offset(875, 420),
        Offset(1050, 220),
      ],
    ),
    GapLevelDefinition(
      levelNumber: 6,
      title: 'Grand Abyss',
      subtitle: 'Three-Stage Chasm Gauntlet',
      hint: 'Master gliding, anchor relays, and timed Heavy swings across three towering canyon chasms!',
      worldSize: Size(1660, 720),
      lightSpawn: Offset(150, 460),
      heavySpawn: Offset(80, 455),
      goalZone: Rect.fromLTWH(1490, 170, 96, 110),
      parSeconds: 62,
      platforms: [
        PlatformBlock(Rect.fromLTWH(20, 500, 230, 220)),
        PlatformBlock(Rect.fromLTWH(520, 430, 190, 290)),
        PlatformBlock(Rect.fromLTWH(950, 360, 190, 360)),
        PlatformBlock(Rect.fromLTWH(780, 0, 95, 220), isHazard: true),
        PlatformBlock(Rect.fromLTWH(1350, 280, 290, 440)),
      ],
      thermals: [
        WindThermal(zone: Rect.fromLTWH(300, 230, 140, 290), force: Offset(40, -790)),
        WindThermal(zone: Rect.fromLTWH(740, 220, 150, 270), force: Offset(50, -780)),
        WindThermal(zone: Rect.fromLTWH(1165, 130, 140, 290), force: Offset(45, -840)),
      ],
      anchorPads: [
        AnchorPad(Offset(565, 414), label: 'STEP 1'),
        AnchorPad(Offset(995, 344), label: 'STEP 2'),
        AnchorPad(Offset(1390, 264), label: 'SUMMIT'),
      ],
      corePositions: [
        Offset(370, 300),
        Offset(815, 320),
        Offset(1235, 200),
      ],
    ),
  ];
}
