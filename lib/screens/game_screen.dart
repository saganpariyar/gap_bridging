import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../engine/gap_engine.dart';
import '../models/customization.dart';
import '../models/levels.dart';
import '../painters/gap_painter.dart';
import '../services/storage_service.dart';
import '../widgets/customization_sheet.dart';

class GameScreen extends StatefulWidget {
  final int initialLevelIndex;
  const GameScreen({super.key, this.initialLevelIndex = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GapEngine _engine;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _keysPressed = {};
  Size _canvasSize = const Size(400, 500);

  @override
  void initState() {
    super.initState();
    _engine = GapEngine(initialLevelIndex: widget.initialLevelIndex);
    _ticker = createTicker((elapsed) {
      final dt = _lastTick == Duration.zero
          ? 0.016
          : (elapsed - _lastTick).inMicroseconds / 1e6;
      _lastTick = elapsed;
      _applyKeyboardInputs();
      _engine.step(dt);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _applyKeyboardInputs() {
    if (_keysPressed.isEmpty) return;
    double lMove = 0;
    if (_keysPressed.contains(LogicalKeyboardKey.keyA)) lMove -= 1;
    if (_keysPressed.contains(LogicalKeyboardKey.keyD)) lMove += 1;
    _engine.lightMoveInput = lMove;
    _engine.lightJumpHeld = _keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.space);

    double hMove = 0;
    if (_keysPressed.contains(LogicalKeyboardKey.arrowLeft)) hMove -= 1;
    if (_keysPressed.contains(LogicalKeyboardKey.arrowRight)) hMove += 1;
    _engine.heavyMoveInput = hMove;
    _engine.heavyReelIn = _keysPressed.contains(LogicalKeyboardKey.arrowUp);
    _engine.heavySlackOut = _keysPressed.contains(LogicalKeyboardKey.arrowDown);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _keysPressed.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.space) {
        _engine.jumpLight();
      } else if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.keyE) {
        _engine.toggleLightAnchor();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _engine.jumpHeavy();
      } else if (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.keyQ) {
        _engine.swapActiveCharacter();
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _engine.resetLevel();
      }
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.keyD) {
        _engine.lightMoveInput = 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.space) {
        _engine.lightJumpHeld = false;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _engine.heavyMoveInput = 0;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) _engine.heavyReelIn = false;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) _engine.heavySlackOut = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openCustomization() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomizationSheet(onChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _engine,
          builder: (context, _) {
            final bg = CustomizationCatalog.backgrounds[StorageService.backgroundIndex];
            final lightSkin = CustomizationCatalog.lightProfiles[StorageService.lightProfileIndex];
            final heavySkin = CustomizationCatalog.heavyProfiles[StorageService.heavyProfileIndex];
            final badge = CustomizationCatalog.pilotBadges[StorageService.pilotBadgeIndex];

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    bg.assetPath,
                    key: ValueKey(bg.assetPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Container(color: const Color(0x44020617)),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopHud(bg, lightSkin, heavySkin, badge),
                      if (_engine.bannerTimer > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: bg.accentColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _engine.statusBanner,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onPanStart: (details) {
                                final cam = computeGapCamera(_engine, _canvasSize);
                                _engine.dragAimStart = cam.screenToWorld(details.localPosition);
                                _engine.dragAimCurrent = _engine.dragAimStart;
                              },
                              onPanUpdate: (details) {
                                final cam = computeGapCamera(_engine, _canvasSize);
                                _engine.dragAimCurrent = cam.screenToWorld(details.localPosition);
                              },
                              onPanEnd: (_) {
                                if (_engine.dragAimStart != null && _engine.dragAimCurrent != null) {
                                  _engine.launchLightFromDrag(_engine.dragAimStart!, _engine.dragAimCurrent!);
                                }
                                _engine.dragAimStart = null;
                                _engine.dragAimCurrent = null;
                              },
                              child: CustomPaint(
                                size: _canvasSize,
                                painter: GapPainter(_engine),
                              ),
                            );
                          },
                        ),
                      ),
                      _buildControlsBar(bg, lightSkin, heavySkin),
                    ],
                  ),
                ),

                if (_engine.isLevelComplete) _buildVictoryOverlay(bg),
                if (_engine.isFailed) _buildFailOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHud(
    BackgroundThemeOption bg,
    LightProfile lightSkin,
    HeavyProfile heavySkin,
    PilotBadgeOption badge,
  ) {
    final collected = _engine.cores.where((c) => c.collected).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            ClipOval(child: Image.asset(lightSkin.assetPath, width: 26, height: 26, fit: BoxFit.cover)),
            const SizedBox(width: 4),
            Icon(badge.icon, color: badge.badgeColor, size: 16),
            const SizedBox(width: 4),
            ClipOval(child: Image.asset(heavySkin.assetPath, width: 26, height: 26, fit: BoxFit.cover)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'L${_engine.level.levelNumber}: ${_engine.level.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFBBF24)),
                      Text('$collected/3', style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(
                        '${_engine.elapsedSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: _engine.twoPlayerMode
                    ? const Color(0xFF34D399).withValues(alpha: 0.2)
                    : bg.accentColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _engine.toggleControlMode,
              child: Text(
                _engine.twoPlayerMode ? '2P SPLIT' : 'SOLO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _engine.twoPlayerMode ? const Color(0xFF34D399) : bg.accentColor,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Customize',
              onPressed: _openCustomization,
              icon: Icon(Icons.palette_rounded, color: bg.accentColor, size: 20),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Restart',
              onPressed: _engine.resetLevel,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar(BackgroundThemeOption bg, LightProfile lightSkin, HeavyProfile heavySkin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xDD090D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: _engine.twoPlayerMode
          ? _buildTwoPlayerControls(lightSkin, heavySkin)
          : _buildSoloControls(lightSkin, heavySkin),
    );
  }

  Widget _buildSoloControls(LightProfile lightSkin, HeavyProfile heavySkin) {
    final isLight = _engine.activeChar == ActiveCharacter.light;
    final activeColor = isLight ? lightSkin.primaryColor : heavySkin.primaryColor;
    return Row(
      children: [
        _HoldButton(
          icon: Icons.arrow_left_rounded,
          color: activeColor,
          onDown: () {
            if (isLight) {
              _engine.lightMoveInput = -1;
            } else {
              _engine.heavyMoveInput = -1;
            }
          },
          onUp: () {
            if (isLight) {
              _engine.lightMoveInput = 0;
            } else {
              _engine.heavyMoveInput = 0;
            }
          },
        ),
        const SizedBox(width: 6),
        _HoldButton(
          icon: Icons.arrow_right_rounded,
          color: activeColor,
          onDown: () {
            if (isLight) {
              _engine.lightMoveInput = 1;
            } else {
              _engine.heavyMoveInput = 1;
            }
          },
          onUp: () {
            if (isLight) {
              _engine.lightMoveInput = 0;
            } else {
              _engine.heavyMoveInput = 0;
            }
          },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _engine.swapActiveCharacter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: activeColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                Text(
                  isLight ? 'LIGHT' : 'HEAVY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: activeColor),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        if (isLight) ...[
          _HoldButton(
            label: 'GLIDE',
            icon: Icons.flight_takeoff_rounded,
            color: lightSkin.primaryColor,
            onDown: _engine.jumpLight,
            onUp: () => _engine.lightJumpHeld = false,
          ),
          const SizedBox(width: 6),
          _TapActionButton(
            label: _engine.lightAnchored ? 'UNLOCK' : 'ANCHOR',
            icon: Icons.anchor_rounded,
            color: _engine.lightAnchored ? const Color(0xFF34D399) : lightSkin.glowColor,
            onTap: _engine.toggleLightAnchor,
          ),
        ] else ...[
          _HoldButton(
            label: 'SLACK',
            icon: Icons.south_rounded,
            color: const Color(0xFF94A3B8),
            onDown: () => _engine.heavySlackOut = true,
            onUp: () => _engine.heavySlackOut = false,
          ),
          const SizedBox(width: 6),
          _HoldButton(
            label: 'REEL',
            icon: Icons.north_rounded,
            color: heavySkin.primaryColor,
            onDown: () => _engine.heavyReelIn = true,
            onUp: () => _engine.heavyReelIn = false,
          ),
          const SizedBox(width: 6),
          _TapActionButton(
            label: 'HOP',
            icon: Icons.upload_rounded,
            color: heavySkin.glowColor,
            onTap: _engine.jumpHeavy,
          ),
        ],
      ],
    );
  }

  Widget _buildTwoPlayerControls(LightProfile lightSkin, HeavyProfile heavySkin) {
    return Row(
      children: [
        // P1 Light Cluster
        _HoldButton(
          icon: Icons.arrow_left_rounded,
          color: lightSkin.primaryColor,
          compact: true,
          onDown: () => _engine.lightMoveInput = -1,
          onUp: () => _engine.lightMoveInput = 0,
        ),
        const SizedBox(width: 3),
        _HoldButton(
          icon: Icons.arrow_right_rounded,
          color: lightSkin.primaryColor,
          compact: true,
          onDown: () => _engine.lightMoveInput = 1,
          onUp: () => _engine.lightMoveInput = 0,
        ),
        const SizedBox(width: 3),
        _HoldButton(
          label: 'GLD',
          color: lightSkin.primaryColor,
          compact: true,
          onDown: _engine.jumpLight,
          onUp: () => _engine.lightJumpHeld = false,
        ),
        const SizedBox(width: 3),
        _TapActionButton(
          label: _engine.lightAnchored ? 'UNL' : 'LCK',
          color: lightSkin.glowColor,
          compact: true,
          onTap: _engine.toggleLightAnchor,
        ),
        const Spacer(),
        // P2 Heavy Cluster
        _HoldButton(
          label: 'REEL',
          color: heavySkin.primaryColor,
          compact: true,
          onDown: () => _engine.heavyReelIn = true,
          onUp: () => _engine.heavyReelIn = false,
        ),
        const SizedBox(width: 3),
        _TapActionButton(
          label: 'HOP',
          color: heavySkin.glowColor,
          compact: true,
          onTap: _engine.jumpHeavy,
        ),
        const SizedBox(width: 3),
        _HoldButton(
          icon: Icons.arrow_left_rounded,
          color: heavySkin.primaryColor,
          compact: true,
          onDown: () => _engine.heavyMoveInput = -1,
          onUp: () => _engine.heavyMoveInput = 0,
        ),
        const SizedBox(width: 3),
        _HoldButton(
          icon: Icons.arrow_right_rounded,
          color: heavySkin.primaryColor,
          compact: true,
          onDown: () => _engine.heavyMoveInput = 1,
          onUp: () => _engine.heavyMoveInput = 0,
        ),
      ],
    );
  }

  Widget _buildVictoryOverlay(BackgroundThemeOption bg) {
    final hasNext = _engine.currentLevelIndex < GapLevels.all.length - 1;
    return Container(
      color: const Color(0xBB020617),
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF34D399), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 48),
              const SizedBox(height: 8),
              const Text(
                'CHASM BRIDGED!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text(
                'Cleared in ${_engine.elapsedSeconds.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 34,
                    color: i < _engine.earnedStars ? const Color(0xFFFBBF24) : const Color(0xFF334155),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _engine.resetLevel,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Replay'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                      onPressed: () {
                        if (hasNext) {
                          _engine.loadLevel(_engine.currentLevelIndex + 1);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(hasNext ? 'Next Level' : 'Finish', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailOverlay() {
    return Container(
      color: const Color(0xBB020617),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF43F5E), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 46),
              const SizedBox(height: 8),
              const Text(
                'TETHER LOST',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                _engine.failReason,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white),
                  onPressed: _engine.resetLevel,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Level', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final Color color;
  final bool compact;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _HoldButton({
    this.icon,
    this.label,
    required this.color,
    this.compact = false,
    required this.onDown,
    required this.onUp,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onPointerCancel: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: Container(
        height: widget.compact ? 42 : 48,
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 9 : 13),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withValues(alpha: 0.38) : widget.color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: widget.color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) Icon(widget.icon, color: Colors.white, size: widget.compact ? 18 : 22),
            if (widget.label != null) ...[
              if (widget.icon != null) const SizedBox(width: 4),
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: widget.compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _TapActionButton({
    required this.label,
    this.icon,
    required this.color,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: compact ? 42 : 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: compact ? 15 : 18),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
