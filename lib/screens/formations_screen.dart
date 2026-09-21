import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/formation_model.dart';
import '../providers/formation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'formation_detail_screen.dart';

/// Onglet Formations : catalogue du YMS avec recherche locale.
class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (context.read<FormationProvider>().formations.isEmpty) {
      context.read<FormationProvider>().loadFormations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormationProvider>();
    final filtered = provider.formations
        .where((f) =>
            _query.isEmpty ||
            f.titre.toLowerCase().contains(_query.toLowerCase()) ||
            f.categorie.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 28),
      children: [
        Text('Formations', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Catalogue des programmes YMS',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.brown700),
            hintText: 'Rechercher une formation…',
          ),
        ),
        const SizedBox(height: 14),
        if (provider.isLoading && provider.formations.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: AppLoading())
        else if (provider.errorMessage != null && provider.formations.isEmpty)
          AppErrorState(message: provider.errorMessage!, onRetry: provider.loadFormations)
        else if (filtered.isEmpty)
          const AppEmptyState(
            icon: Icons.search_off,
            title: 'Aucun résultat',
            subtitle: 'Essayez un autre mot-clé.',
          )
        else
          ...filtered.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FormationCard(formation: f),
            ),
          ),
      ],
    );
  }
}

class _FormationCard extends StatelessWidget {
  final FormationModel formation;
  const _FormationCard({required this.formation});

  (IconData, Color) get _categorieIcon => switch (formation.categorie) {
        'Informatique' => (Icons.computer, AppColors.brown700),
        'Communication' => (Icons.campaign_outlined, AppColors.warn),
        'Management' => (Icons.fact_check_outlined, AppColors.ok),
        _ => (Icons.school_outlined, AppColors.muted),
      };

  String get _dates {
    if (formation.dateDebut == null || formation.dateFin == null) return '—';
    return '${AppFormat.date(formation.dateDebut!)} → ${AppFormat.date(formation.dateFin!)}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _categorieIcon;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FormationDetailScreen(formation: formation),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(icon: icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formation.titre,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formation.categorie,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FormationStatusChip(statut: formation.statut),
                ],
              ),
              if (formation.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  formation.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 15, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text(_dates, style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (formation.tarif > 0) ...[
                    Text(
                      AppFormat.ar(formation.tarif),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontFamily: 'Cormorant Garamond',
                          ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.people_outline, size: 15, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    '${formation.placesRestantes} places',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}