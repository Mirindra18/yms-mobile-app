import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/elearning_models.dart';
import '../../models/formation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/elearning_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/formation_provider.dart';
import '../../providers/presence_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import 'elearning_screen.dart';

/// Accueil : salutation, héro (assiduité + formation en cours),
/// raccourcis, formation en ligne et actualités.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  static const _emptyFormation = ElearningFormation(id: 0, titre: '');

  FormationModel? _formationEnCours(List<FormationModel> formations) {
    for (final f in formations) {
      if (f.statut == 'EN_COURS') return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final formations = context.watch<FormationProvider>().formations;
    final finance = context.watch<FinanceProvider>();
    final presence = context.watch<PresenceProvider>();
    final elearning = context.watch<ElearningProvider>();

    final enCours = _formationEnCours(formations);
    final taux = presence.tauxAssiduite;
    final progression =
        elearning.progressions.entries.where((e) => e.value.estCommence).toList();
    final reprendreId =
        progression.isNotEmpty ? progression.first.value.formationId : null;
    final reprendreTitre = reprendreId == null
        ? null
        : elearning.formations
            .firstWhere((f) => f.id == reprendreId, orElse: () => _emptyFormation)
            .titre;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 28),
      children: [
        Text(
          'Bonjour${user != null && user.prenom.isNotEmpty ? ', ${user.prenom}' : ''} !',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          'Continuez sur votre lancée.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        _Hero(
          tauxPresence: taux,
          nbPresents: presence.nbPresents,
          nbTotal: presence.presences.length,
          formation: enCours,
          onVoirFormations: () => onNavigate(1),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Raccourcis',
          subtitle: 'Tout gérer en quelques taps',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.school_outlined,
                label: 'Formations',
                value: '${formations.length} au catalogue',
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.video_library_outlined,
                label: 'E-learning',
                value: '${elearning.formations.length} parcours',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ElearningScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.payments_outlined,
                label: 'Écolage',
                value: 'Solde ${AppFormat.ar(finance.soldeTotal)}',
                onTap: () => onNavigate(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.workspace_premium_outlined,
                label: 'Certificat',
                value: 'Suivez vos progrès',
                onTap: () => onNavigate(3),
              ),
            ),
          ],
        ),
        if (progression.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ReprendreCard(
            titre: reprendreTitre?.isNotEmpty == true
                ? reprendreTitre!
                : 'Formation en ligne',
            pourcentage: progression.first.value.pourcentage,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ElearningScreen(
                  initialFormationId: progression.first.value.formationId,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Actualités',
          subtitle: 'Vie de la communauté YMS',
        ),
        const SizedBox(height: 12),
        ..._actualites(formations).map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActualiteCard(article: a),
          ),
        ),
      ],
    );
  }

  List<({String titre, String texte, IconData icon})> _actualites(
      List<FormationModel> formations) {
    final items = <({String titre, String texte, IconData icon})>[];

    formations.sort((a, b) => a.statut.compareTo(b.statut));
    for (final f in formations.take(3)) {
      switch (f.statut) {
        case 'A_VENIR':
          items.add((
            titre: 'Inscriptions ouvertes',
            texte: '${f.titre} — réservez vite votre place (${f.placesRestantes} restantes).',
            icon: Icons.campaign_outlined,
          ));
        case 'EN_COURS':
          items.add((
            titre: 'Formation en cours',
            texte: '${f.titre} avance bien : retrouvez les séances en ligne et les ressources.',
            icon: Icons.play_circle_outline,
          ));
        case 'TERMINEE':
          items.add((
            titre: 'Résultats disponibles',
            texte: '${f.titre} est terminée : consultez vos certificats dans l\'onglet Certificat.',
            icon: Icons.emoji_events_outlined,
          ));
      }
    }
    return items;
  }
}

class _Hero extends StatelessWidget {
  final double? tauxPresence;
  final int nbPresents;
  final int nbTotal;
  final FormationModel? formation;
  final VoidCallback onVoirFormations;

  const _Hero({
    required this.tauxPresence,
    required this.nbPresents,
    required this.nbTotal,
    required this.formation,
    required this.onVoirFormations,
  });

  @override
  Widget build(BuildContext context) {
    final t = tauxPresence ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brown800, AppColors.brown950],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown950.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PresenceRing(rate: t),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assiduité',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$nbPresents présent(s) sur $nbTotal séance(s)',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.gold, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formation == null
                          ? 'Votre prochaine aventure'
                          : 'Formation en cours',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.goldSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formation?.titre ?? 'Découvrez le catalogue YMS',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (formation != null)
                TextButton(
                  onPressed: onVoirFormations,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Voir'),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceRing extends StatelessWidget {
  final double rate;
  const _PresenceRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CircularProgressIndicator(
              value: rate / 100,
              strokeWidth: 6,
              backgroundColor: AppColors.brown700.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${rate.round()} %',
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
                Text(
                  'présence',
                  style: GoogleFonts.manrope(
                    fontSize: 8.5,
                    color: AppColors.goldSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: icon, color: AppColors.brown700),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReprendreCard extends StatelessWidget {
  final String titre;
  final int pourcentage;
  final VoidCallback onTap;

  const _ReprendreCard({
    required this.titre,
    required this.pourcentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.play_circle_outline,
                color: AppColors.warn,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reprendre la formation en ligne',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(titre,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pourcentage / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.cardBorder,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$pourcentage %',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActualiteCard extends StatelessWidget {
  final ({String titre, String texte, IconData icon}) article;
  const _ActualiteCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconTile(icon: article.icon, color: AppColors.ok),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.titre, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(article.texte, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}