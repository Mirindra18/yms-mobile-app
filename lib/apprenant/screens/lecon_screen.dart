import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/elearning_models.dart';
import '../../providers/elearning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Lecteur d'une leçon : contenu + ressources + validation.
/// Retourne `true` quand la leçon a été terminée.
class LeconScreen extends StatefulWidget {
  final int formationId;
  final LeconModel lecon;

  const LeconScreen({
    super.key,
    required this.formationId,
    required this.lecon,
  });

  @override
  State<LeconScreen> createState() => _LeconScreenState();
}

class _LeconScreenState extends State<LeconScreen> {
  bool _isBusy = false;

  Future<void> _terminer() async {
    setState(() => _isBusy = true);
    try {
      await context
          .read<ElearningProvider>()
          .terminerLecon(widget.formationId, widget.lecon.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecon = widget.lecon;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(lecon.titre)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Row(
            children: [
              StatusChip(
                label: 'Leçon ${lecon.ordre}',
                color: AppColors.warn,
                background: AppColors.warnBg,
                icon: Icons.play_circle_outline,
              ),
              if (lecon.dureeLabel.isNotEmpty) ...[
                const SizedBox(width: 10),
                StatusChip(
                  label: lecon.dureeLabel,
                  color: AppColors.muted,
                  background: AppColors.mutedBg,
                  icon: Icons.schedule,
                ),
              ],
            ],
          ),
          if (lecon.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(lecon.description, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SelectableText(
                lecon.contenu.isEmpty ? 'Contenu en préparation…' : lecon.contenu,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
            ),
          ),
          if (lecon.ressources.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionHeader(title: 'Ressources', subtitle: 'Documents complémentaires'),
            const SizedBox(height: 10),
            ...lecon.ressources.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RessourceTile(ressource: r),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : _terminer,
              icon: _isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cream,
                      ),
                    )
                  : const Icon(Icons.done_all),
              label: const Text('Terminer la leçon'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RessourceTile extends StatelessWidget {
  final RessourceModel ressource;
  const _RessourceTile({required this.ressource});

  (IconData, Color) get _type => switch (ressource.type) {
        'PDF' => (Icons.picture_as_pdf, AppColors.danger),
        'VIDEO' => (Icons.play_circle_outline, AppColors.brown700),
        'DOCUMENT' => (Icons.description_outlined, AppColors.ok),
        'LINK' => (Icons.link, AppColors.warn),
        _ => (Icons.insert_drive_file_outlined, AppColors.muted),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _type;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconTile(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ressource.titre, style: Theme.of(context).textTheme.titleSmall),
                  if (ressource.description != null &&
                      ressource.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ressource.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (ressource.tailleLabel.isNotEmpty)
              Text(ressource.tailleLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}