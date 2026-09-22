import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/consultation_models.dart';
import '../../providers/consultation_provider.dart';
import 'creneaux_list_screen.dart';

/// Historique des consultations de l'apprenant connecté, avec
/// annulation et reprogrammation. Ticket MOB-B1.
class MesConsultationsScreen extends StatefulWidget {
  const MesConsultationsScreen({super.key});

  @override
  State<MesConsultationsScreen> createState() => _MesConsultationsScreenState();
}

class _MesConsultationsScreenState extends State<MesConsultationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().chargerMesConsultations();
    });
  }

  Future<void> _annuler(ConsultationModel consultation) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la consultation'),
        content: const Text('Voulez-vous vraiment annuler cette consultation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Oui, annuler')),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    final provider = context.read<ConsultationProvider>();
    final succes = await provider.annuler(consultation.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(succes ? 'Consultation annulée.' : provider.errorMessage ?? 'Échec de l\'annulation.')),
    );
  }

  Future<void> _reprogrammer(ConsultationModel consultation) async {
    final nouveauCreneau = await Navigator.of(context).push<CreneauModel>(
      MaterialPageRoute(builder: (_) => const CreneauxListScreen(modeReprogrammation: true)),
    );
    if (nouveauCreneau == null || !mounted) return;

    final provider = context.read<ConsultationProvider>();
    final succes = await provider.reprogrammer(
      consultationId: consultation.id,
      nouveauCreneauId: nouveauCreneau.id,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(succes ? 'Consultation reprogrammée.' : provider.errorMessage ?? 'Échec de la reprogrammation.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Mes consultations')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E5AAC),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreneauxListScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
      ),
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, _) {
          if (provider.statutConsultations == LoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.mesConsultations.isEmpty) {
            return const Center(child: Text('Vous n\'avez encore aucune consultation.'));
          }

          return RefreshIndicator(
            onRefresh: provider.chargerMesConsultations,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: provider.mesConsultations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final consultation = provider.mesConsultations[index];
                return _ConsultationCard(
                  consultation: consultation,
                  onAnnuler: consultation.estAnnulable ? () => _annuler(consultation) : null,
                  onReprogrammer: consultation.estReprogrammable ? () => _reprogrammer(consultation) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback? onAnnuler;
  final VoidCallback? onReprogrammer;

  const _ConsultationCard({required this.consultation, this.onAnnuler, this.onReprogrammer});

  Color get _couleurStatut => switch (consultation.statut) {
        StatutConsultation.enAttente => Colors.orange,
        StatutConsultation.confirmee => Colors.green,
        StatutConsultation.terminee => Colors.blueGrey,
        StatutConsultation.annulee => Colors.redAccent,
        StatutConsultation.reprogrammee => Colors.blueAccent,
      };

  @override
  Widget build(BuildContext context) {
    final creneau = consultation.creneau;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'fr_FR').format(creneau.dateCreneau),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _couleurStatut.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    consultation.statut.libelle,
                    style: TextStyle(color: _couleurStatut, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${creneau.heureDebut.substring(0, 5)} à ${creneau.heureFin.substring(0, 5)} — ${creneau.consultantNomComplet}'),
            if (consultation.motif != null && consultation.motif!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(consultation.motif!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            if (onAnnuler != null || onReprogrammer != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReprogrammer != null)
                    TextButton(onPressed: onReprogrammer, child: const Text('Reprogrammer')),
                  if (onAnnuler != null)
                    TextButton(
                      onPressed: onAnnuler,
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Annuler'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
