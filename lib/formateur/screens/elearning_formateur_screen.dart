import 'package:flutter/material.dart';

import '../widgets/formateur_colors.dart';

class ElearningFormateurScreen extends StatelessWidget {
  const ElearningFormateurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 56,
                color: FormateurColors.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'E-Learning',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: FormateurColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La gestion des contenus pédagogiques sera disponible ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FormateurColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
