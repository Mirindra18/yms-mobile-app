import 'package:flutter/material.dart';
import '../models/formation_model.dart';
import '../services/api_client.dart';
import '../services/inscription_service.dart';

class FormationDetailScreen extends StatefulWidget {
  final FormationModel formation;
  final bool initiallyInscrit;

  const FormationDetailScreen({
    super.key,
    required this.formation,
    this.initiallyInscrit = false,
  });

  @override
  State<FormationDetailScreen> createState() => _FormationDetailScreenState();
}

class _FormationDetailScreenState extends State<FormationDetailScreen> {
  late final InscriptionService _inscriptionService;

  bool _isSubmitting = false;
  late bool _isInscrit; // état local, mis à jour après succès

  @override
  void initState() {
    super.initState();
    _inscriptionService = InscriptionService(ApiClient());
    _isInscrit = widget.initiallyInscrit;
  }

  bool get _dateLimiteDepassee => widget.formation.isDateLimiteDepassee;

  bool get _canSubscribe => !_isInscrit && !_dateLimiteDepassee && !_isSubmitting;

  Future<void> _handleInscription() async {
    setState(() => _isSubmitting = true);

    try {
      await _inscriptionService.inscrireAFormation(widget.formation.id);

      if (!mounted) return;
      setState(() => _isInscrit = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Inscription validée avec succès !')),
            ],
          ),
        ),
      );
    } on InscriptionException catch (e) {
      if (!mounted) return;

      // Si déjà inscrit côté serveur, on synchronise l'état local
      if (e.type == InscriptionErrorType.alreadySubscribed) {
        setState(() => _isInscrit = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(e.message)),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _buttonLabel {
    if (_isInscrit) return 'Déjà inscrit';
    if (_dateLimiteDepassee) return 'Inscriptions closes';
    return 'S\'inscrire';
  }

  @override
  Widget build(BuildContext context) {
    final formation = widget.formation;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(formation.titre),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.titre,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (formation.dateLimiteInscription != null)
                Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 18,
                      color: _dateLimiteDepassee ? Colors.red : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Inscriptions jusqu\'au ${_formatDate(formation.dateLimiteInscription!)}',
                      style: TextStyle(
                        color: _dateLimiteDepassee ? Colors.red : Colors.black54,
                        fontWeight: _dateLimiteDepassee ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                formation.description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubscribe ? _handleInscription : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isInscrit
                        ? Colors.grey.shade400
                        : const Color(0xFF2E5AAC),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(_buttonLabel, style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (_isInscrit)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('Vous êtes inscrit à cette formation.'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}