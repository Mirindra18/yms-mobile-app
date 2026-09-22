import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/elearning_models.dart';
import '../../providers/elearning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import 'lecon_screen.dart';

/// Contenu détaillé d'un parcours : chapitres, leçons et progression.
class ElearningDetailScreen extends StatefulWidget {
  final ElearningFormation formation;
  const ElearningDetailScreen({super.key, required this.formation});

  @override
  State<ElearningDetailScreen> createState() => _ElearningDetailScreenState();
}

class _ElearningDetailScreenState extends State<ElearningDetailScreen> {
  final Set<int> _doneEnSession = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<ElearningProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadParcours(widget.formation.id);
      provider.loadProgression(widget.formation.id);
    });
  }

  Set<int> _doneLecons(ElearningContent content, int pourcentage) {
    final result = Set<int>.of(_doneEnSession);
    if (content.nbLecons > 0 && pourcentage > 0) {
      final n = (pourcentage / 100 * content.nbLecons).round();
      final ids = <int>[];
      for (final chapitre in content.chapitres) {
        for (final lecon in chapitre.lecons) {
          ids.add(lecon.id);
        }
      }
      result.addAll(ids.take(n));
    }
    return result;
  }

  Future<void> _open(LeconModel lecon, int formationId) async {
    final provider = context.read<ElearningProvider>();
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeconScreen(formationId: formationId, lecon: lecon),
      ),
    );
    
    if (!mounted) return;

    if (done == true) {
      setState(() => _doneEnSession.add(lecon.id));
      provider.loadProgression(formationId);
    }
  }

  String _statutLabel(int pourcentage) {
    if (pourcentage >= 100) return 'Terminé';
    if (pourcentage > 0) return 'En cours';
    return 'Non commencé';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ElearningProvider>();
    final content = provider.parcoursDe(widget.formation.id);
    final progression = provider.progressionDe(widget.formation.id);
    final pourcentage = progression?.pourcentage ?? 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Parcours')),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadParcours(widget.formation.id);
          await provider.loadProgression(widget.formation.id);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _Header(
              titre: widget.formation.titre,
              description: widget.formation.description,
              pourcentage: pourcentage,
              statut: _statutLabel(pourcentage),
            ),
            const SizedBox(height: 24),
            if (provider.isLoadingParcours && content == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: AppLoading(),
              )
            else if (provider.errorMessage != null && content == null)
              AppErrorState(
                message: provider.errorMessage!,
                onRetry: () => provider.loadParcours(widget.formation.id),
              )
            else if (content != null)
              ..._buildChapitres(context, content, pourcentage),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChapitres(
    BuildContext context,
    ElearningContent content,
    int pourcentage,
  ) {
    if (content.chapitres.isEmpty) {
      return const [
        AppEmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Aucun chapitre',
          subtitle: 'Ce parcours est en préparation…',
        ),
      ];
    }

    final done = _doneLecons(content, pourcentage);
    return [
      SectionHeader(
        title: 'Programme',
        subtitle: '${content.nbLecons} leçons · ${content.chapitres.length} chapitres',
      ),
      const SizedBox(height: 12),
      ...content.chapitres.map(
        (chap) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _ChapitreCard(
            chapitre: chap,
            doneLecons: done,
            onLeconTap: (lecon) => _open(lecon, content.id),
          ),
        ),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  final String titre;
  final String description;
  final int pourcentage;
  final String statut;

  const _Header({
    required this.titre,
    required this.description,
    required this.pourcentage,
    required this.statut,
  });

  @override
  Widget build(BuildContext context) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(icon: Icons.menu_book_outlined, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.goldSoft,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.gold, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pourcentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.brown700.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pourcentage %',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatusChip(
            label: statut,
            color: pourcentage >= 100 ? AppColors.ok : AppColors.gold,
            background: Colors.white.withValues(alpha: 0.12),
            icon: pourcentage >= 100
                ? Icons.check_circle
                : pourcentage > 0
                    ? Icons.bolt
                    : Icons.play_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _ChapitreCard extends StatelessWidget {
  final ChapitreModel chapitre;
  final Set<int> doneLecons;
  final ValueChanged<LeconModel> onLeconTap;

  const _ChapitreCard({
    required this.chapitre,
    required this.doneLecons,
    required this.onLeconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.iconBgBrown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Chapitre ${chapitre.ordre}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brown700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${chapitre.nbLecons} leçons',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              chapitre.titre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (chapitre.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                chapitre.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            ...chapitre.lecons.map((lecon) => _LeconTile(
                  lecon: lecon,
                  done: doneLecons.contains(lecon.id),
                  onTap: () => onLeconTap(lecon),
                )),
          ],
        ),
      ),
    );
  }
}

class _LeconTile extends StatelessWidget {
  final LeconModel lecon;
  final bool done;
  final VoidCallback onTap;

  const _LeconTile({required this.lecon, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.play_circle_outline,
              size: 22,
              color: done ? AppColors.ok : AppColors.warn,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${lecon.ordre}. ${lecon.titre}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.ink,
                    ),
              ),
            ),
            if (lecon.dureeLabel.isNotEmpty) ...[
              Text(lecon.dureeLabel, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}