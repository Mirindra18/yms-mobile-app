import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/elearning_models.dart';

/// Affiche une ressource pédagogique selon son type (PDF, vidéo,
/// document, lien). L'ouverture des fichiers PDF/vidéo se fait via une
/// application externe pour l'instant.
class RessourceViewer extends StatelessWidget {
  final RessourceModel ressource;

  const RessourceViewer({super.key, required this.ressource});

  @override
  Widget build(BuildContext context) {
    // On analyse le type sous forme de String (en majuscules pour éviter les erreurs de casse)
    final typeStr = ressource.type.toUpperCase();
    
    final icone = switch (typeStr) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'VIDEO' => Icons.play_circle_outline,
      'DOCUMENT' => Icons.description_outlined,
      'LINK' => Icons.link,
      _ => Icons.insert_drive_file_outlined, // Valeur par défaut (OTHER ou autre)
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icone, color: const Color(0xFF2E5AAC)),
        title: Text(ressource.titre),
        subtitle: ressource.description != null ? Text(ressource.description!) : null,
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _ouvrir(context),
      ),
    );
  }

  Future<void> _ouvrir(BuildContext context) async {
    final url = ressource.url;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun lien disponible pour cette ressource.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette ressource.')),
      );
    }
  }
}