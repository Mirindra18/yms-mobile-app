import 'package:flutter/material.dart';

import '../widgets/formateur_colors.dart';
import '../../routing/formateur_routes.dart';

class PlaceholderScreen extends StatelessWidget {
  final FormateurRoute route;
  final String description;

  const PlaceholderScreen({
    super.key,
    required this.route,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurColors.bg,
      appBar: AppBar(title: Text(route.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(route.icon, size: 56, color: FormateurColors.gold),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FormateurColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
