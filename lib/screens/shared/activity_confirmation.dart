import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Particle ─────────────────────────────────────────────────────────────────
class _P {
  double x, y, vx, vy, life, decay, r;
  final Color color;
  _P({required this.x, required this.y, required this.vx, required this.vy,
      required this.life, required this.decay, required this.r, required this.color});
  void tick() {
    x += vx; y += vy;
    vy += 0.0025; vx *= 0.979;
    life -= decay;
  }
}

// ─── Particle painter ─────────────────────────────────────────────────────────
class _PPainter extends CustomPainter {
  final List<_P> ps;
  _PPainter(this.ps);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 0.4;
    for (final p in ps) {
      final a = p.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      canvas.drawCircle(
        Offset(cx + p.x * size.width, cy + p.y * size.height),
        p.r * size.width * a,
        Paint()..color = p.color.withValues(alpha: a),
      );
    }
  }
  @override
  bool shouldRepaint(_PPainter old) => true;
}

// ─── Arrow painter ────────────────────────────────────────────────────────────
class _ArrowPainter extends CustomPainter {
  final double reveal, glow;
  _ArrowPainter(this.reveal, this.glow);

  static const _pts = [
    Offset(2.57, 55.08), Offset(0, 55.08),    Offset(19.57, 17.61),
    Offset(26.64, 29.33), Offset(42.69, 8.88), Offset(34.77, 8.82),
    Offset(61.17, 0),     Offset(25.38, 43.94), Offset(18.04, 32.6),
  ];
  static const _vW = 61.17, _vH = 55.08;

  static const _cols = [
    Color(0xFF110b79), Color(0xFF10137d), Color(0xFF0c3e93), Color(0xFF0861a6),
    Color(0xFF057db4), Color(0xFF0390be), Color(0xFF019cc4), Color(0xFF01a0c6),
    Color(0xFF33afab), Color(0xFF5ebc95), Color(0xFF7fc683), Color(0xFF97cd76),
    Color(0xFFa5d26f), Color(0xFFaad36c),
  ];
  static const _stops = [
    0.0, 0.02, 0.12, 0.22, 0.33, 0.43,
    0.53, 0.64, 0.71, 0.77, 0.84, 0.90, 0.95, 1.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vW, sy = size.height / _vH;
    final path = Path()
      ..moveTo(_pts[0].dx * sx, _pts[0].dy * sy);
    for (int i = 1; i < _pts.length; i++) {
      path.lineTo(_pts[i].dx * sx, _pts[i].dy * sy);
    }
    path.close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = LinearGradient(colors: _cols, stops: _stops).createShader(rect);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-2, -8, size.width * reveal + 2, size.height + 16));

    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()..shader = shader
               ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * glow),
      );
    }
    canvas.drawPath(path, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.reveal != reveal || old.glow != glow;
}

// ─── EaseOutBack curve ────────────────────────────────────────────────────────
class _EaseOutBack extends Curve {
  const _EaseOutBack();
  @override
  double transformInternal(double t) {
    const c1 = 1.5, c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon, value, label;
  final List<Color> colors;
  const _StatCard({required this.icon, required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.barlowCondensed(
                  fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: GoogleFonts.barlow(
                  fontSize: 10, color: Colors.white38, letterSpacing: 0.3, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Main widget ──────────────────────────────────────────────────────────────
class ActivityConfirmation extends StatefulWidget {
  final int xp;
  final int streak;
  final int? friendRank;

  const ActivityConfirmation({
    super.key,
    required this.xp,
    required this.streak,
    this.friendRank,
  });

  @override
  State<ActivityConfirmation> createState() => _ActivityConfirmationState();
}

class _ActivityConfirmationState extends State<ActivityConfirmation>
    with TickerProviderStateMixin {

  late final AnimationController _arrowCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _uiCtrl;
  late final AnimationController _dismissCtrl;
  late final Ticker _pTicker;

  late final Animation<double> _reveal;
  late final Animation<Offset> _slide;
  late final Animation<double> _glow;
  late final Animation<double> _screenFade;

  final _ps = <_P>[];
  final _rng = Random();
  bool _arrowDone = false;

  static const _pColors = [
    Color(0xFF110b79), Color(0xFF0861a6), Color(0xFF019cc4),
    Color(0xFF33afab), Color(0xFF7fc683), Color(0xFFaad36c),
    Color(0xFFffffff), Color(0xFFb0eeff), Color(0xFFd4ffb0),
  ];

  @override
  void initState() {
    super.initState();

    _arrowCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _glowCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _uiCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _dismissCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _reveal = CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeOutCubic);
    _slide  = Tween<Offset>(begin: const Offset(0.85, 0.55), end: Offset.zero)
        .animate(CurvedAnimation(parent: _arrowCtrl, curve: const _EaseOutBack()));
    _glow   = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    _screenFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeIn));

    _pTicker = createTicker((_) {
      if (_ps.isEmpty) return;
      setState(() {
        for (final p in _ps) { p.tick(); }
        _ps.removeWhere((p) => p.life <= 0);
      });
    });

    _startSequence();
  }

  void _startSequence() {
    _arrowCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _arrowDone = true);
      _glowCtrl.repeat(reverse: true);
      _pTicker.start();

      _burst(Offset.zero, 38, 0.025, 0.095);
      Future.delayed(const Duration(milliseconds: 110), () => _burst(const Offset(-0.27, -0.22), 24, 0.020, 0.070));
      Future.delayed(const Duration(milliseconds: 200), () => _burst(const Offset( 0.26, -0.20), 24, 0.020, 0.070));
      Future.delayed(const Duration(milliseconds: 300), () => _burst(const Offset(-0.20,  0.18), 20, 0.018, 0.060));
      Future.delayed(const Duration(milliseconds: 380), () => _burst(const Offset( 0.27,  0.16), 20, 0.018, 0.060));

      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _uiCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 3800), () {
        if (mounted) {
          _dismissCtrl.forward().then((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      });
    });
  }

  void _burst(Offset center, int n, double sMin, double sMax) {
    if (!mounted) return;
    for (int i = 0; i < n; i++) {
      final angle = (pi * 2 / n) * i + (_rng.nextDouble() - 0.5) * 0.5;
      final speed = sMin + _rng.nextDouble() * (sMax - sMin);
      _ps.add(_P(
        x: center.dx, y: center.dy,
        vx: cos(angle) * speed, vy: sin(angle) * speed,
        life: 1.0,
        decay: 0.011 + _rng.nextDouble() * 0.013,
        r:    0.006 + _rng.nextDouble() * 0.010,
        color: _pColors[_rng.nextInt(_pColors.length)],
      ));
    }
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    _glowCtrl.dispose();
    _uiCtrl.dispose();
    _dismissCtrl.dispose();
    _pTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_arrowCtrl, _glowCtrl, _uiCtrl, _dismissCtrl]),
      builder: (context, _) {
        final fade = _screenFade.value;
        return Scaffold(
          backgroundColor: Color.fromRGBO(9, 9, 12, fade * 0.96),
          body: Stack(
            children: [
              // Particles
              if (_ps.isNotEmpty)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _PPainter(List.from(_ps)),
                ),

              // Content
              Opacity(
                opacity: fade,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Arrow
                      SizedBox(
                        width: 200, height: 180,
                        child: SlideTransition(
                          position: _slide,
                          child: CustomPaint(
                            painter: _ArrowPainter(
                              _reveal.value,
                              _arrowDone ? _glow.value : 0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Labels + Stats
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _uiCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
                              .animate(CurvedAnimation(parent: _uiCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut))),
                          child: Column(
                            children: [
                              Text(
                                'Aktivität erstellt!',
                                style: GoogleFonts.barlow(
                                    fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Weiter so — du bist auf Kurs 🔥',
                                style: GoogleFonts.barlow(fontSize: 14, color: Colors.white38),
                              ),
                              const SizedBox(height: 18),
                              _buildStats(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    Widget stat(String icon, String value, String label, List<Color> colors, double start) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: _uiCtrl,
          curve: Interval(start, (start + 0.45).clamp(0, 1), curve: Curves.easeOutBack),
        ),
        child: _StatCard(icon: icon, value: value, label: label, colors: colors),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stat('⚡', '+${widget.xp} XP', 'Punkte',
            [const Color(0x8D110b79), const Color(0x5901a0c6)], 0.15),
        const SizedBox(width: 10),
        stat('🔥', '${widget.streak}', 'Tage Streak',
            [const Color(0x80B45000), const Color(0x4DF08C00)], 0.35),
        if (widget.friendRank != null) ...[
          const SizedBox(width: 10),
          stat('🏆', '#${widget.friendRank}', 'Freunde',
              [const Color(0x80500A64), const Color(0x40aad36c)], 0.55),
        ],
      ],
    );
  }
}
