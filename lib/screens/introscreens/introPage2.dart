import 'package:flutter/material.dart';

class IntroPage2 extends StatelessWidget{
  const IntroPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                  children: [
                    TextSpan(text: 'Deine Reise beginnt '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Stack(
                        children: [
                          Text(
                            'hier',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          // Unterstrich-Effekt
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 2,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),

              SizedBox(height: 20),
              //Logo unten, horizontal zentriert
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Image.asset(
                  'assets/images/streax-homepage-screenhot.png',
                  height: 3000,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20),
              Text(
                textAlign: TextAlign.center,
                'Dein Streak informiert dich über deine Konsistenz. Messe dich mit deinen Freunden und verbessert euch gemeinsam!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 20),
              //Logo unter text
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Image.asset(
                  'assets/images/streax-type.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}