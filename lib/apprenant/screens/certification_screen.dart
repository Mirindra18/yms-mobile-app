import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../providers/formation_provider.dart';
import '../../providers/presence_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Onglet Certificat : suivre les conditions d'obtention et consulter
/// les certificats acquis (dérivé des données réelles de l'apprenant).
class CertificationScreen extends StatelessWidget {
  const CertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formations = context.watch<FormationProvider>();
    final finance = context.watch<FinanceProvider>();
    final presence = context.watch<PresenceProvider>();

    final entries = _buildEntries(context, formations, finance, presence);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 28),
      children: [
        Text('Certificat', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Formation suivie, écolage à jour et assiduité : vos clés YMS.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        _ReglesCard(tauxPresence: presence.tauxAssiduite),
        const SizedBox(height: 22),
        SectionHeader(title: 'Mes certificats'),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const AppEmptyState(
            icon: Icons.workspace_premium_outlined,
            title: 'Aucun certificat en cours',
            subtitle:
                'Inscrivez-vous à une formation : votre certificat se prépare automatiquement.',
          )
        else
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CertificatCard(entry: e),
            ),
          ),
      ],
    );
  }

  /// Construit une fiche par formation pour laquelle un écolage existe.
  List<_CertEntry> _buildEntries(
    BuildContext context,
    FormationProvider formations,
    FinanceProvider finance,
    PresenceProvider presence,
  ) {
    final taux = presence.tauxAssiduite;
    final entries = <_CertEntry>[];

    for (final ecolage in finance.ecolages) {
      final formation = formations.formationById(ecolage.formationId);
      if (formation == null) continue;

      final terminee = formation.estTerminee;
      final solder = ecolage.estSolder;
      final assiduiteOk = taux != null && taux >= 75;

      entries.add(_CertEntry(
        formationTitre: formation.titre,
        categorie: formation.categorie,
        terminee: terminee,
        solder: solder,
        assiduiteOk: assiduiteOk,
        taux: taux,
      ));
    }

    entries.sort((a, b) {
      if (a.obtenu == b.obtenu) return 0;
      return a.obtenu ? -1 : 1;
    });
    return entries;
  }
}

class _CertEntry {
  final String formationTitre;
  final String categorie;
  final bool terminee;
  final bool solder;
  final bool assiduiteOk;
  final double? taux;

  const _CertEntry({
    required this.formationTitre,
    required this.categorie,
    required this.terminee,
    required this.solder,
    required this.assiduiteOk,
    required this.taux,
  });

  bool get obtenu => terminee && solder && assiduiteOk;
}

class _ReglesCard extends StatelessWidget {
  final double? tauxPresence;
  const _ReglesCard({required this.tauxPresence});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconTile(
              icon: Icons.workspace_premium_outlined,
              color: AppColors.gold,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assiduité actuelle', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    tauxPresence == null
                        ? 'Aucune séance enregistrée pour le moment.'
                        : '${tauxPresence!.round()} % · objectif fixé à 75 %',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ((tauxPresence ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.cardBorder,
                      color: (tauxPresence ?? 0) >= 75
                          ? AppColors.ok
                          : AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            if (tauxPresence != null)
              Text(
                '${tauxPresence!.round()} %',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Cormorant Garamond',
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CertificatCard extends StatelessWidget {
  final _CertEntry entry;
  const _CertificatCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.obtenu) return _obtenuCard(context);
    return _enCoursCard(context);
  }

  Widget _obtenuCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brown800, AppColors.brown950],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.gold, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Certificat obtenu',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.formationTitre,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.categorie,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppToast.show(context, 'Exemple de certificat (démo)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Télécharger le certificat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enCoursCard(BuildContext context) {
    final items = [
      ('Formation suivie et terminée', entry.terminee),
      ('Écolage intégralement payé', entry.solder),
      ('Assiduité d\'au moins 75 %', entry.assiduiteOk),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.formationTitre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(
                  label: 'En préparation',
                  color: AppColors.warn,
                  background: AppColors.warnBg,
                  icon: Icons.hourglass_top,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.categorie, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: i.$2 ? AppColors.ok : AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        i.$1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: i.$2 ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}