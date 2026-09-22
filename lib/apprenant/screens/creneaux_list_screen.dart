import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/consultation_models.dart';
import '../../providers/consultation_provider.dart';

/// Écran de consultation des créneaux disponibles et de demande de
/// rendez-vous. Ticket MOB-B1. Utilisé également en mode sélection
/// lors d'une reprogrammation (le créneau choisi est alors retourné à
/// l'appelant plutôt que d'entraîner une nouvelle demande directe).
class CreneauxListScreen extends StatefulWidget {
  final bool modeReprogrammation;

  const CreneauxListScreen({super.key, this.modeReprogrammation = false});

  @override
  State<CreneauxListScreen> createState() => _CreneauxListScreenState();
}

class _CreneauxListScreenState extends State<CreneauxListScreen> {
  CreneauModel? _selection;
  final _motifController = TextEditingController();
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().chargerCreneauxDisponibles();
    });
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    final creneau = _selection;
    if (creneau == null) return;

    if (widget.modeReprogrammation) {
      Navigator.of(context).pop(creneau);
      return;
    }

    setState(() => _envoiEnCours = true);
    final provider = context.read<ConsultationProvider>();
    final succes = await provider.demanderConsultation(
      creneauId: creneau.id,
      motif: _motifController.text.trim().isEmpty ? null : _motifController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _envoiEnCours = false);

    if (succes) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre demande de consultation a bien été envoyée.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'La demande a échoué.')),
      );
      provider.chargerCreneauxDisponibles();
      setState(() => _selection = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.modeReprogrammation ? 'Choisir un nouveau créneau' : 'Demander une consultation'),
      ),
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, _) {
          if (provider.statutCreneaux == LoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.statutCreneaux == LoadStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage ?? 'Une erreur est survenue.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provider.chargerCreneauxDisponibles,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.creneauxDisponibles.isEmpty) {
            return const Center(child: Text('Aucun créneau n\'est disponible pour le moment.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.creneauxDisponibles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final creneau = provider.creneauxDisponibles[index];
                    final selectionne = _selection?.id == creneau.id;
                    return Card(
                      elevation: selectionne ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selectionne ? const Color(0xFF2E5AAC) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selection = creneau),
                        leading: Icon(
                          selectionne ? Icons.check_circle : Icons.event_available_outlined,
                          color: selectionne ? const Color(0xFF2E5AAC) : null,
                        ),
                        title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(creneau.dateCreneau)),
                        subtitle: Text(
                          '${creneau.heureDebut.substring(0, 5)} à ${creneau.heureFin.substring(0, 5)} — ${creneau.consultantNomComplet}',
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!widget.modeReprogrammation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _motifController,
                    decoration: const InputDecoration(
                      labelText: 'Motif (facultatif)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selection == null || _envoiEnCours ? null : _confirmer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E5AAC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _envoiEnCours
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.modeReprogrammation ? 'Choisir ce créneau' : 'Confirmer la demande'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
