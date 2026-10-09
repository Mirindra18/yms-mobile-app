import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/elearning_models.dart';
import '../../providers/elearning_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import 'elearning_detail_screen.dart';
import 'quiz_list_screen.dart';

/// Liste des formations en ligne (e-learning).
class ElearningScreen extends StatefulWidget {
  /// Si fourni, ouvre directement la formation correspondante une
  /// fois le catalogue chargé.
  final int? initialFormationId;

  const ElearningScreen({super.key, this.initialFormationId});

  @override
  State<ElearningScreen> createState() => _ElearningScreenState();
}

class _ElearningScreenState extends State<ElearningScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ElearningProvider>();
    if (provider.formations.isEmpty) {
      provider.loadFormations();
      return;
    }
    _maybeOpenInitial();
  }

  void _maybeOpenInitial() {
    if (widget.initialFormationId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ElearningProvider>();
      final target = provider.formations
          .where((f) => f.id == widget.initialFormationId)
          .toList();
      if (target.isEmpty || !mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ElearningDetailScreen(formation: target.first),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ElearningProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('E-learning')),
      body: RefreshIndicator(
        onRefresh: provider.loadFormations,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ElearningProvider provider) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        _QuizAccessCard(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const QuizListScreen())),
        ),
        const SizedBox(height: 20),
        if (provider.isLoading && provider.formations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: AppLoading(),
          )
        else if (provider.errorMessage != null && provider.formations.isEmpty)
          AppErrorState(
            message: provider.errorMessage!,
            onRetry: provider.loadFormations,
          )
        else if (provider.formations.isEmpty)
          const AppEmptyState(
            icon: Icons.video_library_outlined,
            title: 'Aucun parcours en ligne',
            subtitle:
                'Les parcours e-learning apparaîtront ici dès leur publication.',
          )
        else ...[
          Text('Vos parcours', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...provider.formations.map(
            (formation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ElearningCard(formation: formation),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuizAccessCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuizAccessCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brown800, AppColors.brown950],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppColors.gold, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes quiz',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Évaluez vos connaissances',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.goldSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.gold,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElearningCard extends StatelessWidget {
  final ElearningFormation formation;
  const _ElearningCard({required this.formation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ElearningDetailScreen(formation: formation),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.play_circle_outline,
                color: AppColors.warn,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formation.titre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formation.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
