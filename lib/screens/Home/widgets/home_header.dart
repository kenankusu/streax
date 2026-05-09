import 'package:flutter/material.dart';
import 'package:streax/models/user.dart';
import 'package:streax/services/database.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  bool _milestoneActive = false;
  double _lastKnownProgress = -1.0;
  String? _quote;
  String? _author;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadQuote();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    final user = Provider.of<StreaxUser?>(context, listen: false);
    if (user != null) {
      final data = await DatabaseService(uid: user.uid).getRandomQuoteWithAuthor();
      if (mounted) {
        setState(() {
          _quote = data['text'];
          _author = data['author'];
        });
      }
    }
  }

  void _updateProgress(double newProgress, int streak) {
    if (_milestoneActive || newProgress == _lastKnownProgress) return;
    _lastKnownProgress = newProgress;
    double prev = _currentProgress;
    double next = newProgress;
    if (next < prev) next += 1.0;
    setState(() {
      _currentProgress = prev;
      _targetProgress = next;
    });
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _currentProgress = _targetProgress % 1.0;
      });
      if (_currentProgress >= 1.0 && !_milestoneActive) {
        _startMilestoneAnimation(streak);
      }
    });
  }

  void _startMilestoneAnimation(int streak) {
    _milestoneActive = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      const milestones = [3, 7, 14, 30, 60, 100, 365];
      final next = milestones.firstWhere((m) => streak < m, orElse: () => 365);
      setState(() {
        _currentProgress = 0.0;
        _targetProgress = streak >= 365 ? (streak % 365) / 365.0 : streak / next.toDouble();
      });
      _animationController.reset();
      _animationController.forward().then((_) {
        setState(() {
          _currentProgress = _targetProgress;
          _milestoneActive = false;
        });
      });
    });
  }

  Widget _greeting(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hallo,',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [kBlue, kGreen],
          ).createShader(bounds),
          child: Text(
            firstName.toUpperCase(),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kBlue, kGreen]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _streakRing(int streak) {
    const milestones = [3, 7, 14, 30, 60, 100, 365, 500, 1000];
    int next;
    double raw;
    if (streak >= 1000) {
      next = 1000;
      raw = (streak % 1000) / 1000.0;
    } else {
      next = milestones.firstWhere((m) => streak < m, orElse: () => 1000);
      raw = streak / next;
    }
    raw = raw.clamp(0.0, 1.0);

    if (raw != _lastKnownProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateProgress(raw, streak));
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final animated = (_currentProgress +
                (_targetProgress - _currentProgress) * _animationController.value) %
            1.0;
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(100, 100),
                painter: _StreakRingPainter(animated),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16, height: 1)),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Streak',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF884020),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quoteCard() {
    final text = _quote ?? 'Fall in love with the process, and the results will come.';
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(left: BorderSide(color: kBlue, width: 2)),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFCCCCCC),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          if (_author != null && _author!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '— ${_author!.toUpperCase()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6A9ABA),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context)!;
    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        String firstName = 'Unbekannt';
        int streak = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          firstName = data['firstName'] ?? 'Unbekannt';
          streak = data['streak'] ?? 0;
        }
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _greeting(firstName),
                _streakRing(streak),
              ],
            ),
            const SizedBox(height: 20),
            _quoteCard(),
          ],
        );
      },
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  final double progress;
  const _StreakRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawArc(
      rect,
      0,
      2 * 3.141592653589793,
      false,
      Paint()
        ..color = const Color(0xFF1E2228)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    if (progress > 0) {
      final gradient = SweepGradient(
        colors: const [kBlue, kGreen],
        transform: const GradientRotation(-3.1415926535 / 2),
      );
      canvas.drawArc(
        rect,
        -3.1415926535 / 2,
        2 * 3.1415926535 * progress,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StreakRingPainter old) => old.progress != progress;
}
