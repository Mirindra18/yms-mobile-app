import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/formation_model.dart';
import '../../models/quiz_model.dart';
import '../../providers/formation_provider.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import 'quiz_attempt_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  late final QuizService _quizService;
  List<QuizModel> _quizzes = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService(context.read<ApiClient>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final formationProvider = context.read<FormationProvider>();
    try {
      if (formationProvider.formations.isEmpty &&
          !formationProvider.isLoading) {
        await formationProvider.loadFormations();
      }
      final responses = await Future.wait<dynamic>([
        _quizService.getQuizzes(),
        formationProvider.loadMesInscriptions(),
      ]);
      final quizzes = responses.first as List<QuizModel>;
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _error =
            formationProvider.inscriptionErrorMessage ??
            formationProvider.errorMessage;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = QuizService.errorMessage(error);
        _isLoading = false;
      });
    }
  }

  List<QuizModel> _quizzesFor(
    List<QuizModel> quizzes,
    List<FormationModel> formations,
  ) {
    final titles = formations
        .map((formation) => formation.titre.trim().toLowerCase())
        .where((title) => title.isNotEmpty)
        .toSet();
    final ids = formations.map((formation) => formation.id).toSet();

    return quizzes.where((quiz) {
      final title = quiz.formation.trim().toLowerCase();
      if (titles.contains(title)) return true;
      return ids.any((id) => RegExp('#\\s*$id\\b').hasMatch(title));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formationProvider = context.watch<FormationProvider>();
    final enrolledQuizzes = _quizzesFor(
      _quizzes,
      formationProvider.mesFormations,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Mes quiz')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _IntroCard(
              quizCount: enrolledQuizzes.length,
              formationCount: formationProvider.nombreFormationsInscrites,
            ),
            const SizedBox(height: 20),
            if (_isLoading && _quizzes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: AppLoading(),
              )
            else if (_error != null && _quizzes.isEmpty)
              AppErrorState(message: _error!, onRetry: _load)
            else if (_error != null)
              _InlineError(message: _error!, onRetry: _load)
            else if (formationProvider.mesFormationIds.isEmpty)
              const AppEmptyState(
                icon: Icons.school_outlined,
                title: 'Aucune formation inscrite',
                subtitle:
                    'Les quiz apparaîtront ici lorsque vous serez inscrit à une formation.',
              )
            else if (enrolledQuizzes.isEmpty)
              const AppEmptyState(
                icon: Icons.quiz_outlined,
                title: 'Aucun quiz disponible',
                subtitle:
                    'Les évaluations de vos formations apparaîtront ici dès leur publication.',
              )
            else ...[
              Text(
                'Évaluations disponibles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...enrolledQuizzes.map(
                (quiz) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuizCard(
                    quiz: quiz,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizAttemptScreen(
                          quiz: quiz,
                          service: _quizService,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final int quizCount;
  final int formationCount;

  const _IntroCard({required this.quizCount, required this.formationCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brown800, AppColors.brown950],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz_outlined, color: AppColors.gold, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prêt à vous évaluer ?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.cream,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quizCount quiz · $formationCount formation(s) suivie(s)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.goldSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;

  const _QuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.fact_check_outlined,
                color: AppColors.brown700,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.titre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz.formation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${quiz.questions.length} question(s) · '
                      '${quiz.dureeMinutes > 0 ? quiz.dureeMinutes : 15} min',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.brown700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: AppColors.danger),
        title: Text(message),
        trailing: IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          tooltip: 'Réessayer',
        ),
      ),
    );
  }
}
