import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Toast premium partagé (SnackBar flottant arrondi).
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isOk = false,
  }) {
    final color = isError
        ? AppColors.danger
        : isOk
            ? AppColors.ok
            : AppColors.brown950;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : isOk
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                color: AppColors.cream,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
        ),
      );
  }
}

/// Petit en-tête de section.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brown900,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastiche premium d'un statut (En cours / Terminée / Payée...).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statut d'une formation du catalogue.
class FormationStatusChip extends StatelessWidget {
  final String statut;
  const FormationStatusChip({super.key, required this.statut});

  (String, Color, IconData) get _meta => switch (statut) {
        'A_VENIR' => ('À venir', AppColors.ok, Icons.schedule),
        'EN_COURS' => ('En cours', AppColors.warn, Icons.bolt),
        'TERMINEE' => ('Terminée', AppColors.muted, Icons.check_circle_outline),
        'ANNULEE' => ('Annulée', AppColors.danger, Icons.cancel_outlined),
        _ => (statut, AppColors.muted, Icons.info_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _meta;
    return StatusChip(label: label, color: color, icon: icon);
  }
}

/// Petite tuile d'icône brune (utilisée par les cartes).
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const IconTile({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.iconBgBrown,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: AppColors.brown700),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AppErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}