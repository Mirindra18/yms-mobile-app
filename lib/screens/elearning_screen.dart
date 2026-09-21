import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/elearning_models.dart';
import '../providers/elearning_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'elearning_detail_screen.dart';

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
      appBar: AppBar(
        title: const Text('E-learning'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadFormations,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ElearningProvider provider) {
    if (provider.isLoading && provider.formations.isEmpty) {
      return const CustomScrollView(
        slivers: [SliverFillRemaining(child: AppLoading())],
      );
    }
    if (provider.errorMessage != null && provider.formations.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: provider.loadFormations,
      );
    }
    if (provider.formations.isEmpty) {
      return const AppEmptyState(
        icon: Icons.video_library_outlined,
        title: 'Aucun parcours en ligne',
        subtitle:
            'Les parcours e-learning apparaîtront ici dès leur publication.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: provider.formations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final formation = provider.formations[i];
        return _ElearningCard(formation: formation);
      },
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
                    Text(formation.titre,
                        style: Theme.of(context).textTheme.titleMedium),
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