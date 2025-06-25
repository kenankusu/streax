import 'package:flutter/material.dart';

class AktivitaetSheet extends StatelessWidget {
  const AktivitaetSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Neue Aktivität', style: Theme.of(context).textTheme.headlineMedium),
          // ... weitere Felder/Widgets ...
        ],
      ),
    );
  }
}