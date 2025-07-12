import 'package:flutter/material.dart';
import 'package:streax/screens/shared/user.dart';
import 'package:streax/services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Hauptheader der Home-Seite mit Begrüßung, Streak-Anzeige und täglichem Zitat
class Header extends StatefulWidget {
  final int streakValue;

  const Header({
    required this.streakValue,
    super.key,
  });

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  bool _milestoneActive = false;
  double _lastKnownProgress = -1.0;

  String? quote;
  String? author; 

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

  // Lädt ein zufälliges motivierendes Zitat aus der Firebase-Datenbank
  Future<void> _loadQuote() async {
    final user = Provider.of<StreaxUser?>(context, listen: false);
    if (user != null) {
      final quoteData = await DatabaseService(uid: user.uid).getRandomQuoteWithAuthor();
      if (mounted) {
        setState(() {
          quote = quoteData['text'];
          author = quoteData['author'];
        });
      }
    }
  }

  // Aktualisiert den Fortschrittsbalken mit flüssiger Animation
  void _updateProgress(double newProgress, int streak) {
    if (_milestoneActive || newProgress == _lastKnownProgress) return;
    
    _lastKnownProgress = newProgress;
    
    double previousProgress = _currentProgress;
    double newTargetProgress = newProgress;
    
    // Verhindert Rückwärts-Sprünge in der Animation
    if (newTargetProgress < previousProgress) {
      newTargetProgress += 1.0;
    }

    setState(() {
      _currentProgress = previousProgress;
      _targetProgress = newTargetProgress;
    });

    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _currentProgress = _targetProgress % 1.0;
      });
      // mögliche Implementation einer Animation bei erreichen eines Ziels
      if (_currentProgress >= 1.0 && !_milestoneActive) {
        _startMilestoneAnimation(streak);
      }
    });
  }

  void _startMilestoneAnimation(int streak) {
    _milestoneActive = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _currentProgress = 0.0;
        
        if (streak >= 365) {
          _targetProgress = (streak % 365) / 365.0;
        } else {
          // Berechnet das nächste Streak-Ziel
          final List<int> milestones = [3, 7, 14, 30, 60, 100, 365];
          int nextMilestone = milestones.firstWhere((milestone) => streak < milestone, orElse: () => 365);
          _targetProgress = streak / nextMilestone;
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

  // Erstellt die personalisierte Begrüßung mit dynamischer Schriftgröße
  Widget welcomeWidget(String firstName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Passt die Schriftgröße an die Länge des Namens an
        double getNameFontSize(String name) {
          int length = name.length;
          if (length <= 6) {
            return 48.0;
          } else if (length <= 8) {
            return 44.0;
          } else if (length <= 10) {
            return 40.0;
          } else if (length <= 12) {
            return 36.0;
          } else if (length <= 15) {
            return 32.0;
          } else {
            return 28.0;
          }
        }

        // Textstile für Begrüßung und Namen
        final helloStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 32,
          color: Colors.white,
        );

        final nameStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: getNameFontSize(firstName),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // Berechnet die exakte Textbreite für den passenden Unterstrich
        final textSpan = TextSpan(
          text: firstName,
          style: nameStyle,
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
            Text(
              "Hallo,",
              style: helloStyle,
            ),
            // Name mit Gradient-Unterstrich
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: nameStyle,
                ),
                // Gradient-Unterstrich der sich an die Textbreite anpasst
                Container(
                  height: 4,
                  width: textWidth,
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

  // Zeigt die animierte Streak-Anzeige mit Fortschrittskreis
  Widget streakDisplay(int streak) {
    final List<int> milestones = [3, 7, 14, 30, 60, 100, 365, 500, 1000];
    int nextMilestone;
    double rawProgress;
    
    // Berechnet Fortschritt basierend auf aktueller Streak
    if (streak >= 1000) {
      nextMilestone = 1000;
      rawProgress = (streak % 1000) / 1000.0;
    } else {
      nextMilestone = milestones.firstWhere((milestone) => streak < milestone, orElse: () => 1000);
      rawProgress = streak / nextMilestone;
    }
    
    if (rawProgress > 1.0) rawProgress = 1.0;

    if (rawProgress != _lastKnownProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateProgress(rawProgress, streak);
      });
    }

    // Passt Schriftgröße an die Anzahl der Streak-Tage an
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
            Stack(
              alignment: Alignment.center,
              children: [
                GradientCircularProgress(
                  progress: displayValue,
                  size: 120,
                ),
                // Zentrierte Anzeige "aktuelle Streak / Ziel"
                Positioned(
                  top: 35,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: getFontSize(streak),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '/ $nextMilestone',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Prüft ob ein Autor für das Zitat vorhanden ist
  bool _hasAuthor() {
    return author != null && author!.isNotEmpty;
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
          firstName = userData['firstName'] ?? 'Unbekannt';
        }

        return Column(
          children: [
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: welcomeWidget(firstName),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 20),
                  child: streakDisplay(streak),
                ),
              ],
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    // Standard-Zitat falls laden nicht klappt
                    quote ?? "Fall in love with the process, and the results will come.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Autor-Anzeige (falls verfügbar)
                  if (_hasAuthor()) ...[
                    SizedBox(height: 8),
                    Text(
                      "— $author",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.normal,
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Kreisförmiger Fortschrittsbalken mit Gradient-Farben
class GradientCircularProgress extends StatelessWidget {
  final double progress;
  final double size;

  const GradientCircularProgress({
    super.key,
    required this.progress,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientCirclePainter(
        progress,
        Theme.of(context).colorScheme.surfaceContainer, // << Hintergrundfarbe direkt aus dem Theme
      ),
    );
  }
}

class _GradientCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;

  _GradientCirclePainter(this.progress, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Hintergrund-Kreis (immer voll)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect,
      0,
      2 * 3.141592653589793,
      false,
      backgroundPaint,
    );

    // Gradient-Arc für den Fortschritt
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
      oldDelegate.progress != progress ||
      oldDelegate.backgroundColor != backgroundColor;
}
