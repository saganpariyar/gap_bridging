import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gap_bridging/engine/gap_engine.dart';
import 'package:gap_bridging/main.dart';
import 'package:gap_bridging/models/customization.dart';
import 'package:gap_bridging/models/levels.dart';

void main() {
  test('Customization catalog provides 4 options per selection', () {
    expect(CustomizationCatalog.lightProfiles.length, 4);
    expect(CustomizationCatalog.heavyProfiles.length, 4);
    expect(CustomizationCatalog.backgrounds.length, 4);
    expect(CustomizationCatalog.tetherStyles.length, 4);
    expect(CustomizationCatalog.pilotBadges.length, 4);
  });

  test('Gap Bridging has 6 distinct levels and simulates glide, anchor, and reel', () {
    expect(GapLevels.all.length, 6);
    final engine = GapEngine(initialLevelIndex: 0);

    // Light steps forward and glides across chasm with jump held
    engine.lightMoveInput = 1.0;
    engine.jumpLight();
    for (int i = 0; i < 120; i++) {
      engine.step(0.016);
    }
    expect(engine.lightPos.dx, greaterThan(engine.level.lightSpawn.dx + 150));

    // Anchor Light onto pad 1 and verify Heavy swings safely without falling
    engine.lightPos = engine.level.anchorPads.first.position;
    engine.lightGrounded = true;
    engine.toggleLightAnchor();
    expect(engine.lightAnchored, isTrue);

    final startRope = engine.ropeLength;
    engine.heavyMoveInput = 1.0;
    engine.heavyReelIn = true;
    for (int i = 0; i < 60; i++) {
      engine.step(0.016);
    }
    expect(engine.ropeLength, lessThan(startRope));
    expect(engine.isFailed, isFalse);
  });

  testWidgets('Gap Bridging HomeScreen renders title, customization, and levels', (tester) async {
    await tester.pumpWidget(const GapBridgingApp());
    await tester.pumpAndSettle();

    expect(find.text('GAP BRIDGING'), findsOneWidget);
    expect(find.text('First Chasm'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(4));
  });
}
