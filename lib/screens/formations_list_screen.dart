import 'package:flutter/material.dart';
import '../models/elearning_models.dart';
import '../models/formation_model.dart'; // Ajouté pour s'assurer que FormationModel est bien reconnu
import '../services/elearning_service.dart';
import 'lecteur_elearning_screen.dart';

/// Liste des formations disponibles, point d'entrée vers le lecteur
/// E-learning. Ticket MOB-B1.
class FormationsListScreen extends StatefulWidget {
  final ElearningService elearningService;

  const FormationsListScreen({super.key, required this.elearningService});

  @override
  State<FormationsListScreen> createState() => _FormationsListScreenState();
}

class _FormationsListScreenState extends State<FormationsListScreen> {
  late Future<List<FormationModel>> _formationsFuture;

  @override
  void initState() {
    super.initState();
    _formationsFuture = widget.elearningService.listerFormations();
  }

  Future<void> _rafraichir() async {
    setState(() {
      _formationsFuture = widget.elearningService.listerFormations();
    });
    await _formationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Mes formations')),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: FutureBuilder<List<FormationModel>>(
          future: _formationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('${snapshot.error}')),
                ],
              );
            }

            final formations = snapshot.data ?? [];
            if (formations.isEmpty) {
              return const Center(child: Text('Aucune formation disponible pour le moment.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: formations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final formation = formations[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF2E5AAC)),
                    title: Text(formation.titre),
                    subtitle: formation.description.isNotEmpty ? Text(formation.description) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LecteurElearningScreen(
                          formationId: formation.id,
                          titreFormation: formation.titre,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}