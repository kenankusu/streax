import 'package:flutter/material.dart';
import 'package:streax/Models/user.dart';
import 'package:streax/Services/database.dart';
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
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  bool _milestoneActive = false;
  double _lastKnownProgress = -1.0; // Tracking für Änderungen

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateProgress(double newProgress, int streak) {  // Parameter hinzufügen
    if (_milestoneActive || newProgress == _lastKnownProgress) return;
    
    _lastKnownProgress = newProgress;
    
    double oldP = _currentProgress;
    double newP = newProgress;
    
    // Falls wir "nach vorne überlappen"
    if (newP < oldP) {
      newP += 1.0;
    }

    setState(() {
      _currentProgress = oldP;
      _targetProgress = newP;
    });

    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _currentProgress = _targetProgress % 1.0;
      });
      // Falls 100% und kein aktiver Meilenstein
      if (_currentProgress >= 1.0 && !_milestoneActive) {
        _startMilestoneAnimation(streak);  // streak übergeben
      }
    });
  }

  void _startMilestoneAnimation(int streak) {  // Parameter hinzufügen
    _milestoneActive = true;
    
    // Nach kurzer Pause neues Ziel setzen
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _currentProgress = 0.0;
        
        if (streak >= 365) {
          _targetProgress = (streak % 365) / 365.0;
        } else {
          // Normaler Fall: neuer Meilenstein
          final List<int> ziele = [3, 7, 14, 30, 60, 100, 365];
          int naechstesZiel = ziele.firstWhere((ziel) => streak < ziel, orElse: () => 365);
          _targetProgress = streak / naechstesZiel;
        }
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

  Widget Willkommen(String firstName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Schriftstil definieren
        final textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // TextPainter zum Messen der exakten Textbreite
        final textSpan = TextSpan(
          text: firstName,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        final textWidth = textPainter.size.width;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Hallo," in bisheriger Größe
            Text(
              "Hallo,",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Name mit exakt passenden Unterstrich
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: textStyle,
                ),
                // Unterstrich mit exakter Textbreite
                Container(
                  height: 4,
                  width: textWidth, // Exakte Breite des Textes
                  margin: EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1C499E), Color(0xFFB1D43A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget streakAnzeige(int streak) {
    final List<int> ziele = [3, 7, 14, 30, 60, 100, 365, 500, 1000]; // zunächst werden nur Streax bis 1000 behandelt (Was danach passiert schauen wir wenn es einer erreicht)
    int naechstesZiel;
    double rawProgress;
    
    if (streak >= 1000) {
      naechstesZiel = 1000;
      rawProgress = (streak % 1000) / 1000.0;
    } else {
      // Normaler Fall: nächstes Ziel finden
      naechstesZiel = ziele.firstWhere((ziel) => streak < ziel, orElse: () => 1000);
      rawProgress = streak / naechstesZiel;
    }
    
    if (rawProgress > 1.0) rawProgress = 1.0;

    // NUR bei Änderung aktualisieren
    if (rawProgress != _lastKnownProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateProgress(rawProgress, streak);
      });
    }

    final zielText = Text(
      '$naechstesZiel',
      style: TextStyle(fontSize: 20, color: Colors.white),
      textAlign: TextAlign.center,
    );

    double getFontSize(int value) {
      int digits = value.toString().length;
      switch (digits) {
        case 1: return 50.0; 
        case 2: return 46.0; 
        case 3: return 42.0; 
        case 4: return 38.0; 
        default: return 34.0; 
      }
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double animatedValue = _currentProgress +
            (_targetProgress - _currentProgress) * _animationController.value;

        double displayValue = animatedValue % 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            zielText,
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                GradientCircularProgress(
                  progress: displayValue,
                  size: 120,
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
        String firstName = "Unbekannt";
        int streak = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          streak = userData['streak'] ?? 0;
          firstName = userData['firstName'] ?? 'Unbekannt'; // Nur Vorname laden
        }

        return Column(
          children: [
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Willkommen(firstName), 
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 20), // Weniger Padding: top: 20->10, right: 30->20
                  child: streakAnzeige(streak),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Fall in love with the process, and the results will come.",
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
