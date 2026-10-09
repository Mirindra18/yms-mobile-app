import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

class QuizAttemptScreen extends StatefulWidget {
  final QuizModel quiz;
  final QuizService service;

  const QuizAttemptScreen({
    super.key,
    required this.quiz,
    required this.service,
  });

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  late final List<QuizQuestionModel> _questions;
  late final int _durationSeconds;
  late int _remainingSeconds;
  final Map<int, int> _answers = {};
  Timer? _timer;
  int _currentIndex = 0;
  bool _submitting = false;
  String? _error;
  QuizResultModel? _result;

  @override
  void initState() {
    super.initState();
    _questions = [...widget.quiz.questions]
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    _durationSeconds =
        (widget.quiz.dureeMinutes > 0 ? widget.quiz.dureeMinutes : 15) * 60;
    _remainingSeconds = _durationSeconds;
    if (_questions.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 1) {
          _timer?.cancel();
          setState(() => _remainingSeconds = 0);
          _submit(expired: true);
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit({bool expired = false}) async {
    if (_submitting || _result != null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.service.submit(widget.quiz.id, _answers);
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
      _timer?.cancel();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = QuizService.errorMessage(error);
        _submitting = false;
      });
      if (expired) _timer?.cancel();
    }
  }

  Future<void> _confirmExit() async {
    if (_submitting || _result != null) {
      Navigator.of(context).pop();
      return;
    }
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le quiz ?'),
        content: const Text(
          'Votre progression ne sera pas enregistrée si vous quittez maintenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(result == null ? 'Passer le quiz' : 'Résultat'),
        leading: IconButton(
          onPressed: result == null
              ? _confirmExit
              : () => Navigator.pop(context),
          icon: Icon(result == null ? Icons.close : Icons.arrow_back),
          tooltip: result == null ? 'Quitter le quiz' : 'Retour',
        ),
      ),
      body: result == null ? _buildAttempt() : _buildResult(result),
    );
  }

  Widget _buildAttempt() {
    if (_questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Ce quiz ne contient aucune question.'),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final timeCritical = _remainingSeconds <= 30;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quiz.titre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.quiz.formation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          minHeight: 8,
                          backgroundColor: AppColors.cardBorder,
                          color: AppColors.brown700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_currentIndex + 1}/${_questions.length}'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: timeCritical
                          ? AppColors.danger
                          : AppColors.brown700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: timeCritical
                            ? AppColors.danger
                            : AppColors.brown900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text('${_answers.length} réponse(s)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.enonce,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  question.reponses.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AnswerOption(
                      label: question.reponses[index],
                      selected: _answers[question.id] == index,
                      onTap: _submitting
                          ? null
                          : () => setState(() => _answers[question.id] = index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.danger.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _currentIndex == 0 || _submitting
                  ? null
                  : () => setState(() => _currentIndex--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédente'),
            ),
            const Spacer(),
            if (_currentIndex < _questions.length - 1)
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _currentIndex++),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Suivante'),
              )
            else
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Envoi...' : 'Terminer'),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _submit(expired: _remainingSeconds == 0),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer l’envoi'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResult(QuizResultModel result) {
    final passed = result.valide;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.emoji_events_outlined : Icons.refresh_rounded,
                  size: 58,
                  color: passed ? AppColors.gold : AppColors.brown700,
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? 'Félicitations !' : 'Continuez vos efforts',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.quiz.titre,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '${result.score} %',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.brown900,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${result.total} question(s) · seuil de réussite : 50 %',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour aux quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brown700 : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.brown700 : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
