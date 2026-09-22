import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/elearning_provider.dart';
import '../../core/widgets/ressource_viewer.dart';

/// Écran de lecture d'une formation en E-learning, avec reprise
/// automatique à la dernière leçon consultée. Ticket MOB-B1.
class LecteurElearningScreen extends StatefulWidget {
  final int formationId;
  final String titreFormation;

  const LecteurElearningScreen({
    super.key,
    required this.formationId,
    required this.titreFormation,
  });

  @override
  State<LecteurElearningScreen> createState() => _LecteurElearningScreenState();
}

class _LecteurElearningScreenState extends State<LecteurElearningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ElearningProvider>().chargerFormation(widget.formationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: Text(widget.titreFormation)),
      body: Consumer<ElearningProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case LoadStatus.idle:
            case LoadStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case LoadStatus.error:
              return _EtatErreur(
                message: provider.errorMessage ?? 'Une erreur est survenue.',
                onReessayer: () => provider.chargerFormation(widget.formationId),
              );

            case LoadStatus.success:
              return _ContenuLecteur(formationId: widget.formationId);
          }
        },
      ),
    );
  }
}

class _ContenuLecteur extends StatelessWidget {
  final int formationId;

  const _ContenuLecteur({required this.formationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ElearningProvider>();
    final lecon = provider.leconCourante;

    if (lecon == null) {
      return const Center(child: Text('Aucune leçon n\'est encore disponible pour cette formation.'));
    }

    final progressionValue = provider.lecons.isEmpty ? 0.0 : (provider.indexLeconCourante + 1) / provider.lecons.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressionValue,
                  minHeight: 8,
                  color: const Color(0xFF2E5AAC),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Leçon ${provider.indexLeconCourante + 1} sur ${provider.lecons.length}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lecon.titre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (lecon.dureeMinutes != null) ...[
                  const SizedBox(height: 4),
                  Text('${lecon.dureeMinutes} min', style: const TextStyle(color: Colors.black54)),
                ],
                if (lecon.contenu.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    lecon.contenu,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
                if (lecon.ressources.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Ressources', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...lecon.ressources.map((ressource) => RessourceViewer(ressource: ressource)),
                ],
              ],
            ),
          ),
        ),
        _BarreNavigation(formationId: formationId),
      ],
    );
  }
}

class _BarreNavigation extends StatelessWidget {
  final int formationId;

  const _BarreNavigation({required this.formationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ElearningProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: provider.estPremiereLecon ? null : provider.allerALaLeconPrecedente,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Précédent'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => provider.terminerLeconCourante(formationId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5AAC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(provider.estDerniereLecon ? Icons.check : Icons.arrow_forward),
            label: Text(provider.estDerniereLecon ? 'Terminer' : 'Suivant'),
          ),
        ],
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _EtatErreur({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
