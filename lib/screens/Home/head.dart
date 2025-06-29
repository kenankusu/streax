import 'package:flutter/material.dart';
import 'package:flutter_application_1/Models/user.dart';
import 'package:flutter_application_1/Services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Kopfzeile extends StatefulWidget {
  final int streakWert;

  const Kopfzeile({
    required this.streakWert,
    super.key,
  });

  @override
  _KopfzeileState createState() => _KopfzeileState();
}

class _KopfzeileState extends State<Kopfzeile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  double _currentProgress = 0.0; // "Von"-Wert
  double _targetProgress = 0.0;  // "Bis"-Wert

  String? quote;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadQuote(); // Beim Starten Zitat laden
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    // User UID holen damit wir DatabaseService benutzen können
    final user = Provider.of<StreaxUser?>(context, listen: false);
    if (user != null) {
      // Zufälliges Zitat von DatabaseService abfragen
      String randomQuote = await DatabaseService(uid: user.uid).getRandomQuote();
      setState(() {
        quote = randomQuote; // UI updaten mit dem neuen Zitat
      });
    }
  }

  /// Hier statt der alten 2-Phasen-Logik:
  /// - Wenn newProgress < oldProgress, dann addiere +1.0,
  ///   damit ein "Überlauf" im Uhrzeigersinn entsteht.
  void _updateProgress(double newProgress) {
    if (newProgress == _targetProgress) return;

    double oldProgress = _currentProgress;
    double effectiveTarget = newProgress;

    // Falls wir ein neues Ziel haben (z.B. alter Fortschritt 0.8, neuer nur 0.2),
    // drehen wir einmal weiter:
    if (effectiveTarget < oldProgress) {
      effectiveTarget += 1.0; 
    }

    setState(() {
      _currentProgress = oldProgress;
      _targetProgress = effectiveTarget;
    });
    _animationController.forward(from: 0.0);
  }

  Widget Willkommen(String name) {
    return Text(
      "Hallo,\n$name!",
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget streakAnzeige(int streak) {
    final List<int> ziele = [3, 7, 14, 30, 60, 100, 365];
    int naechstesZiel = ziele.firstWhere((ziel) => streak < ziel, orElse: () => ziele.last + 365);

    // Neuer Fortschritt: 0.0 .. 1.0
    double rawProgress = streak / naechstesZiel;
    if (rawProgress > 1.0) rawProgress = 1.0;

    // Damit das Update nur ausgeführt wird, wenn sich rawProgress ändert:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateProgress(rawProgress);
    });

    // Überschrift für das Ziel in Schriftgröße 25
    final zielText = Text(
      '$naechstesZiel',
      style: TextStyle(fontSize: 25, color: Colors.white),
      textAlign: TextAlign.center,
    );

    double getFontSize(int value) {
      int digits = value.toString().length;
      switch (digits) {
        case 1: return 32.0;
        case 2: return 28.0;
        case 3: return 24.0;
        case 4: return 20.0;
        default: return 18.0;
      }
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        // Animation in [0..1], Interpolation zwischen _currentProgress und _targetProgress
        double animatedValue = _currentProgress +
            (_targetProgress - _currentProgress) * _progressAnimation.value;

        // Wir übergeben dem Painter nur (animatedValue % 1.0),
        // sodass z.B. 1.2 => 0.2 (einmal "rum")
        double displayValue = animatedValue % 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            zielText, // Aktuelles Ziel oben anzeigen
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                GradientCircularProgress(
                  progress: displayValue,
                  size: 100,
                ),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: getFontSize(streak),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context)!;

    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        String name = "Benutzer";
        int streak = 0;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          streak = userData['streak'] ?? 0;
          String fullName = userData['name'] ?? 'Benutzer';
          // Nur Vorname anzeigen
          name = fullName.split(' ').first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Willkommen(name),
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 30),
                  child: streakAnzeige(streak),
                ),
              ],
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                // Falls das Zitat noch lädt, Fallback anzeigen
                quote ?? "Fall in love with the process, and the results will come.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dein Gradient-Painter, aber mit dem Wissen, dass progress jetzt z.B. 0.0 .. 1.2 etc. sein kann.
/// Wir nehmen einfach (progress % 1.0) und zeichnen nur diesen Anteil.
class GradientCircularProgress extends StatelessWidget {
  final double progress; // Wert zwischen 0.0 und 1.0 (nach Modulo)
  final double size;     // Durchmesser des Kreises

  const GradientCircularProgress({
    super.key,
    required this.progress,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientCirclePainter(progress),
    );
  }
}

class _GradientCirclePainter extends CustomPainter {
  final double progress; // 0.0 bis knapp < 1.0

  _GradientCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = SweepGradient(
      colors: [Color(0xFF1C499E), Color(0xFFB1D43A)],
      stops: [0.0, 1.0],
      transform: GradientRotation(-3.1415926535 / 2), 
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;

    // Volle Kreisumfang = 2π, wir zeichnen progress * 2π
    final sweepAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      rect,
      -3.141592653589793 / 2, 
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
