import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/presence_models.dart';
import '../providers/presence_provider.dart';
import 'qr_scanner_screen.dart';

/// Historique de présence de l'apprenant connecté. Ticket MOB-B2.
class HistoriquePresenceScreen extends StatefulWidget {
  const HistoriquePresenceScreen({super.key});

  @override
  State<HistoriquePresenceScreen> createState() => _HistoriquePresenceScreenState();
}

class _HistoriquePresenceScreenState extends State<HistoriquePresenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresenceProvider>().chargerHistorique();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Mes présences')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E5AAC),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
        ),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, _) {
          if (provider.statutHistorique == LoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.historique.isEmpty) {
            return const Center(child: Text('Aucune présence enregistrée pour le moment.'));
          }

          return RefreshIndicator(
            onRefresh: provider.chargerHistorique,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: provider.historique.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final presence = provider.historique[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_icone(presence.statut), color: _couleur(presence.statut)),
                    title: Text(presence.intituleSession ?? 'Séance #${presence.sessionId}'),
                    subtitle: Text(DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(presence.dateHeure)),
                    trailing: Text(presence.statut.libelle, style: TextStyle(color: _couleur(presence.statut))),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _icone(StatutPresence statut) => switch (statut) {
        StatutPresence.present => Icons.check_circle,
        StatutPresence.absent => Icons.cancel,
        StatutPresence.retard => Icons.access_time,
        StatutPresence.excuse => Icons.info,
      };

  Color _couleur(StatutPresence statut) => switch (statut) {
        StatutPresence.present => Colors.green,
        StatutPresence.absent => Colors.redAccent,
        StatutPresence.retard => Colors.orange,
        StatutPresence.excuse => Colors.blueGrey,
      };
}
