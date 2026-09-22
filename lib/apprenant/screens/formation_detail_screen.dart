import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/formation_model.dart';
import '../../providers/formation_provider.dart';
import '../../services/api_client.dart';
import '../../services/inscription_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Détail d'une formation + inscription (même logique qu'avant, style premium).
class FormationDetailScreen extends StatefulWidget {
  final FormationModel formation;

  const FormationDetailScreen({super.key, required this.formation});

  @override
  State<FormationDetailScreen> createState() => _FormationDetailScreenState();
}

class _FormationDetailScreenState extends State<FormationDetailScreen> {
  late final InscriptionService _inscriptionService;

  bool _isSubmitting = false;
  bool _checkingInscription = true;
  bool _isInscrit = false;

  @override
  void initState() {
    super.initState();
    _inscriptionService = InscriptionService(context.read<ApiClient>());
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final inscrit = await _inscriptionService.estInscritAFormation(widget.formation.id);
    if (!mounted) return;
    setState(() {
      _isInscrit = inscrit;
      _checkingInscription = false;
    });
  }

  bool get _canSubscribe => !_isInscrit && widget.formation.estOuverte && !_isSubmitting;

  Future<void> _handleInscription() async {
    setState(() => _isSubmitting = true);
    final provider = context.read<FormationProvider>();

    try {
      await _inscriptionService.inscrireAFormation(widget.formation.id);
      await provider.loadFormations();

      if (!mounted) return;
      setState(() => _isInscrit = true);
      AppToast.show(context, 'Inscription validée avec succès', isOk: true);
    } on InscriptionException catch (e) {
      if (!mounted) return;
      if (e.type == InscriptionErrorType.alreadySubscribed) {
        setState(() => _isInscrit = true);
        AppToast.show(context, 'Vous êtes déjà inscrit à cette formation.', isOk: true);
      } else {
        AppToast.show(context, e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _buttonLabel {
    if (_isInscrit) return 'Déjà inscrit';
    if (widget.formation.estAnnulee) return 'Formation annulée';
    if (widget.formation.estTerminee) return 'Formation terminée';
    if (widget.formation.isDateLimiteDepassee) return 'Inscriptions closes';
    return 'S\'inscrire à la formation';
  }

  @override
  Widget build(BuildContext context) {
    final formation = widget.formation;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Formation')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _HeaderCard(formation: formation),
          const SizedBox(height: 18),
          _infoGrid(formation),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('À propos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    formation.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubscribe ? _handleInscription : null,
              icon: _isSubmitting || _checkingInscription
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.cream,
                      ),
                    )
                  : Icon(
                      _isInscrit ? Icons.check_circle_outline : Icons.assignment_turned_in_outlined,
                    ),
              label: Text(_buttonLabel),
            ),
          ),
          if (_isInscrit)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.ok, size: 16),
                  SizedBox(width: 6),
                  Text('Vous êtes inscrit à cette formation.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoGrid(FormationModel f) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.schedule,
            label: 'Durée',
            value: '${f.dureeHeures} h',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            icon: Icons.payments_outlined,
            label: 'Tarif',
            value: f.tarif > 0 ? AppFormat.ar(f.tarif) : 'Gratuit',
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final FormationModel formation;
  const _HeaderCard({required this.formation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brown800, AppColors.brown950],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formation.titre,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                    height: 1.15,
                  ),
                ),
              ),
              FormationStatusChip(statut: formation.statut),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formation.categorie,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.goldSoft,
            ),
          ),
          if (formation.tarif > 0) ...[
            const SizedBox(height: 12),
            Text(
              AppFormat.ar(formation.tarif),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.gold, height: 1),
          ),
          Row(
            children: [
              Icon(Icons.event, size: 15, color: AppColors.goldSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${AppFormat.date(formation.dateDebut)} → ${AppFormat.date(formation.dateFin)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.goldSoft,
                  ),
                ),
              ),
              if (formation.placesRestantes <= 5)
                StatusChip(
                  label: 'Plus que ${formation.placesRestantes} places !',
                  color: AppColors.warn,
                  background: Colors.white.withValues(alpha: 0.12),
                  icon: Icons.flash_on,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.brown700),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}