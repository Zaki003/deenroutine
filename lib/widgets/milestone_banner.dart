import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../providers/habit_provider.dart';
import '../theme/deen_colors.dart';
import '../utils/milestone_messages.dart';
import 'star_pattern.dart';

const _dismissDelay = Duration(milliseconds: 3100);

class _Tier {
  final int sparkCount;
  final double spread;
  final double glow;
  final double texture;
  final double iconSize;
  final double fireAmp;
  final Duration fireSpeed;
  final int emberCount;
  final Duration emberSpeed;
  final double emberMix;
  final double titleFontSize;

  const _Tier({
    required this.sparkCount,
    required this.spread,
    required this.glow,
    required this.texture,
    required this.iconSize,
    required this.fireAmp,
    required this.fireSpeed,
    required this.emberCount,
    required this.emberSpeed,
    required this.emberMix,
    required this.titleFontSize,
  });
}

/// Visual escalation across [kMilestoneDays] — more sparks, a hotter/faster
/// flame, and bigger type at longer streaks, so a 365-day banner reads as a
/// bigger moment than a 3-day one without changing the mechanism.
const Map<int, _Tier> _tiers = {
  3: _Tier(
    sparkCount: 6, spread: 30, glow: 0.30, texture: 0.05, iconSize: 40,
    fireAmp: 0.05, fireSpeed: Duration(milliseconds: 2200),
    emberCount: 3, emberSpeed: Duration(milliseconds: 1600), emberMix: 0.1,
    titleFontSize: 16.5,
  ),
  7: _Tier(
    sparkCount: 9, spread: 36, glow: 0.42, texture: 0.06, iconSize: 43,
    fireAmp: 0.08, fireSpeed: Duration(milliseconds: 1800),
    emberCount: 5, emberSpeed: Duration(milliseconds: 1400), emberMix: 0.3,
    titleFontSize: 17,
  ),
  30: _Tier(
    sparkCount: 14, spread: 44, glow: 0.55, texture: 0.08, iconSize: 46,
    fireAmp: 0.12, fireSpeed: Duration(milliseconds: 1400),
    emberCount: 7, emberSpeed: Duration(milliseconds: 1150), emberMix: 0.5,
    titleFontSize: 18,
  ),
  100: _Tier(
    sparkCount: 19, spread: 52, glow: 0.68, texture: 0.10, iconSize: 49,
    fireAmp: 0.17, fireSpeed: Duration(milliseconds: 1050),
    emberCount: 9, emberSpeed: Duration(milliseconds: 950), emberMix: 0.7,
    titleFontSize: 18.5,
  ),
  365: _Tier(
    sparkCount: 26, spread: 62, glow: 0.85, texture: 0.13, iconSize: 53,
    fireAmp: 0.24, fireSpeed: Duration(milliseconds: 800),
    emberCount: 12, emberSpeed: Duration(milliseconds: 800), emberMix: 0.9,
    titleFontSize: 20,
  ),
};

class _Spark {
  final double angle;
  final double distance;
  final double rotation;
  const _Spark({required this.angle, required this.distance, required this.rotation});
}

/// The streak-milestone banner: slides in above today's habits, its flame
/// flickers and throws embers for as long as it's shown, then it
/// auto-dismisses (or dismisses early on tap) and calls [onDismissed] so the
/// caller can advance [HabitProvider]'s milestone queue.
class MilestoneBanner extends StatefulWidget {
  final MilestoneEvent event;
  final VoidCallback onDismissed;

  const MilestoneBanner({super.key, required this.event, required this.onDismissed});

  @override
  State<MilestoneBanner> createState() => _MilestoneBannerState();
}

class _MilestoneBannerState extends State<MilestoneBanner> with TickerProviderStateMixin {
  _Tier get _tier => _tiers[widget.event.days] ?? _tiers[3]!;

  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final Animation<double> _entranceCurve =
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);

  late final AnimationController _sparkBurst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
  late final AnimationController _flame = AnimationController(vsync: this, duration: _tier.fireSpeed);
  late final AnimationController _embers = AnimationController(vsync: this, duration: _tier.emberSpeed);
  late final AnimationController _timerBar = AnimationController(vsync: this, duration: _dismissDelay);

  late final Animation<double> _flickerScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0 + _tier.fireAmp), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0 + _tier.fireAmp, end: 1.0 - _tier.fireAmp * 0.4), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0 - _tier.fireAmp * 0.4, end: 1.0 + _tier.fireAmp * 0.7), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0 + _tier.fireAmp * 0.7, end: 1.0 - _tier.fireAmp * 0.2), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0 - _tier.fireAmp * 0.2, end: 1.0), weight: 20),
  ]).animate(_flame);

  late final List<_Spark> _sparks = _generateSparks();
  late final List<double> _emberPhase;
  late final List<double> _emberDrift;

  Timer? _dismissTimer;
  bool _reduceMotion = false;
  bool _started = false;

  List<_Spark> _generateSparks() {
    final rng = Random(widget.event.days);
    return List.generate(_tier.sparkCount, (i) {
      final angle = (2 * pi * i / _tier.sparkCount) + (rng.nextDouble() - 0.5) * 0.5;
      final distance = _tier.spread * (0.6 + rng.nextDouble() * 0.6);
      final rotation = (rng.nextDouble() - 0.5) * 2.4;
      return _Spark(angle: angle, distance: distance, rotation: rotation);
    });
  }

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.event.days * 31 + widget.event.habitId.hashCode);
    _emberPhase = List.generate(_tier.emberCount, (_) => rng.nextDouble());
    _emberDrift = List.generate(_tier.emberCount, (_) => (rng.nextDouble() - 0.5) * 20);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_started) return;
    _started = true;

    if (_reduceMotion) {
      _entrance.value = 1;
      _timerBar.value = 1;
    } else {
      _entrance.forward();
      _sparkBurst.forward();
      _flame.repeat();
      _embers.repeat();
      _timerBar.forward();
    }
    _dismissTimer = Timer(_dismissDelay, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (_reduceMotion) {
      widget.onDismissed();
      return;
    }
    _flame.stop();
    _embers.stop();
    _entrance.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _entrance.dispose();
    _sparkBurst.dispose();
    _flame.dispose();
    _embers.dispose();
    _timerBar.dispose();
    super.dispose();
  }

  double _emberOpacity(double progress) {
    if (progress < 0.15) return progress / 0.15;
    return (1 - (progress - 0.15) / 0.85).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tier = _tier;
    final msg = milestoneMessage(l10n, widget.event.days, widget.event.habitTitle);
    final emberColor = Color.lerp(DeenColors.goldSoft, DeenColors.rust, tier.emberMix)!;

    return AnimatedBuilder(
      animation: _entranceCurve,
      builder: (context, child) {
        final t = _entranceCurve.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, -36 * (1 - t)), child: child),
        );
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Material(
          color: Colors.transparent,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: DeenColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DeenColors.gold.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Stack(
              children: [
                StarPattern(opacity: tier.texture, color: DeenColors.goldSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _flameIcon(tier, emberColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.title,
                              style: GoogleFonts.amiri(
                                fontSize: tier.titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: DeenColors.paper,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              msg.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: DeenColors.goldSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.55)),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _timerBar,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _timerBar.value.clamp(0.0, 1.0),
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [DeenColors.gold, DeenColors.goldSoft]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _flameIcon(_Tier tier, Color emberColor) {
    return SizedBox(
      width: tier.iconSize + 24,
      height: tier.iconSize + 24,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flame, _embers, _sparkBurst]),
        builder: (context, _) {
          final pulse = _reduceMotion ? 0.5 : (sin(2 * pi * _flame.value) + 1) / 2;
          final glowOpacity = tier.glow * (0.65 + 0.35 * pulse);
          final ct = _sparkBurst.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              if (!_reduceMotion)
                Container(
                  width: tier.iconSize * 1.7,
                  height: tier.iconSize * 1.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      DeenColors.rust.withValues(alpha: glowOpacity * 0.65),
                      DeenColors.gold.withValues(alpha: glowOpacity * 0.35),
                      Colors.transparent,
                    ]),
                  ),
                ),
              if (ct > 0)
                ..._sparks.map((spark) {
                  final opacity = (1 - ct).clamp(0.0, 1.0);
                  final scale = (0.3 + 0.7 * ct);
                  final dist = spark.distance * ct;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(cos(spark.angle) * dist, sin(spark.angle) * dist),
                      child: Transform.rotate(
                        angle: spark.rotation * ct,
                        child: Transform.scale(
                          scale: scale,
                          child: Icon(Icons.auto_awesome, size: 9, color: DeenColors.goldSoft),
                        ),
                      ),
                    ),
                  );
                }),
              if (!_reduceMotion)
                ...List.generate(tier.emberCount, (i) {
                  final progress = (_embers.value + _emberPhase[i]) % 1.0;
                  return Opacity(
                    opacity: _emberOpacity(progress),
                    child: Transform.translate(
                      offset: Offset(_emberDrift[i] * progress, -30 * progress),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: emberColor),
                      ),
                    ),
                  );
                }),
              Container(
                width: tier.iconSize,
                height: tier.iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DeenColors.gold.withValues(alpha: 0.16),
                  border: Border.all(color: DeenColors.goldSoft.withValues(alpha: 0.4)),
                ),
                child: Transform.scale(
                  scale: _reduceMotion ? 1.0 : _flickerScale.value,
                  child: Icon(
                    Icons.local_fire_department,
                    size: tier.iconSize * 0.52,
                    color: Color.lerp(DeenColors.gold, DeenColors.rust, tier.emberMix * 0.6),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
