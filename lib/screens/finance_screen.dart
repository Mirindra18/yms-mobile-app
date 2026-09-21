import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../providers/finance_provider.dart';
import '../providers/formation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const _modes = [
  ('MVOLA', 'MVola'),
  ('ORANGE_MONEY', 'Orange Money'),
  ('AIRTEL_MONEY', 'Airtel Money'),
  ('ESPECES', 'Espèces'),
  ('VIREMENT_BANCAIRE', 'Virement bancaire'),
];

String _modeLabel(String mode) {
  for (final (value, label) in _modes) {
    if (value == mode) return label;
  }
  return mode;
}

/// Onglet Écolage : synthèse de la dette, échéances et paiement.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final formations = context.watch<FormationProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 28),
      children: [
        Text('Écolage', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Suivez vos paiements en toute simplicité',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (finance.isLoading && finance.ecolages.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: AppLoading())
        else if (finance.errorMessage != null && finance.ecolages.isEmpty)
          AppErrorState(message: finance.errorMessage!, onRetry: finance.load)
        else if (finance.ecolages.isEmpty)
          const AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Aucun écolage',
            subtitle:
                'Votre écolage s\'affichera ici une fois inscrit à une formation.',
          )
        else
          ...finance.ecolages.map((ecolage) => _buildEcolage(context, ecolage, formations)),
      ],
    );
  }

  Widget _buildEcolage(BuildContext context, EcolageModel ecolage,
      FormationProvider formations) {
    final titre = formations
        .formationById(ecolage.formationId)
        ?.titre ?? 'Formation #${ecolage.formationId}';
    final echeances = ecolage.echeances.toList()
      ..sort((a, b) {
        final da = a.moisConcerne ?? DateTime(0);
        final db = b.moisConcerne ?? DateTime(0);
        return da.compareTo(db);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SynthCard(ecolage: ecolage, formationTitre: titre),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Échéances',
          subtitle: '${echeances.length} mensualités à suivre',
        ),
        const SizedBox(height: 12),
        ...echeances.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EcheanceCard(
              echeance: e,
              onPayer: () => _openPaiement(context, e),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openPaiement(BuildContext context, EcheanceModel echeance) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PaiementSheet(echeance: echeance),
    );
  }
}

class _SynthCard extends StatelessWidget {
  final EcolageModel ecolage;
  final String formationTitre;

  const _SynthCard({required this.ecolage, required this.formationTitre});

  @override
  Widget build(BuildContext context) {
    final paye = ecolage.montantTotal - ecolage.soldeDu;
    final ratio = ecolage.montantTotal <= 0
        ? 0.0
        : (paye / ecolage.montantTotal).clamp(0.0, 1.0);

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
          Text(
            'Écolage · $formationTitre',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde restant',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.goldSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormat.ar(ecolage.soldeDu),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: ecolage.estSolder ? 'Soldé' : 'En cours',
                color: ecolage.estSolder ? AppColors.ok : AppColors.gold,
                background: Colors.white.withValues(alpha: 0.12),
                icon: ecolage.estSolder
                    ? Icons.check_circle
                    : Icons.hourglass_top,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.brown700.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppFormat.ar(paye)} réglés sur ${AppFormat.ar(ecolage.montantTotal)}',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.goldSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EcheanceCard extends StatelessWidget {
  final EcheanceModel echeance;
  final VoidCallback onPayer;

  const _EcheanceCard({required this.echeance, required this.onPayer});

  (String, Color) get _statutMeta => switch (echeance.statut) {
        'PAYEE' => ('Payée', AppColors.ok),
        'EN_ATTENTE' => ('En attente', AppColors.warn),
        'EN_RETARD' => ('En retard', AppColors.danger),
        _ => (echeance.statut, AppColors.muted),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statutMeta;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon: Icons.calendar_month_outlined,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        echeance.moisLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Limite : ${AppFormat.date(echeance.dateLimite)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormat.ar(echeance.montant),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Cormorant Garamond',
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                StatusChip(label: label, color: color),
                const Spacer(),
                if (echeance.payableNow)
                  FilledButton(
                    onPressed: onPayer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brown900,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Payer',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaiementSheet extends StatefulWidget {
  final EcheanceModel echeance;
  const _PaiementSheet({required this.echeance});

  @override
  State<_PaiementSheet> createState() => _PaiementSheetState();
}

class _PaiementSheetState extends State<_PaiementSheet> {
  String _mode = 'MVOLA';
  bool _isPaying = false;

  Future<void> _confirmer() async {
    setState(() => _isPaying = true);
    try {
      final result = await context.read<FinanceProvider>().payer(
            echeanceId: widget.echeance.id,
            montant: widget.echeance.montant,
            modePaiement: _mode,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RecuDialog(paiement: result),
      );
      if (!mounted) return;
      AppToast.show(context, 'Paiement validé avec succès', isOk: true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          16,
          AppSpacing.page,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Payer l\'échéance', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${widget.echeance.moisLabel} · ${AppFormat.ar(widget.echeance.montant)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Text('Mode de paiement', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((m) {
                final (value, label) = m;
                final selected = _mode == value;
                return ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.cream : AppColors.ink,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: AppColors.white,
                  selectedColor: AppColors.brown900,
                  side: BorderSide(
                    color: selected ? AppColors.brown900 : AppColors.cardBorder,
                  ),
                  onSelected: (_) => setState(() => _mode = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPaying ? null : _confirmer,
                icon: _isPaying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cream,
                        ),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                    'Confirmer · ${AppFormat.ar(widget.echeance.montant)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reçu de paiement stylisé (simulation du « ticket » de la maquette).
class _RecuDialog extends StatelessWidget {
  final PaiementModel paiement;
  const _RecuDialog({required this.paiement});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.okBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.ok, size: 34),
            ),
            const SizedBox(height: 14),
            Text('Paiement validé', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'REÇU N° ${paiement.numeroRecu ?? '—'}',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brown900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.cardBorder),
                  ),
                  _ligne(context, 'Montant', paiement.montantAr),
                  _ligne(context, 'Mode', _modeLabel(paiement.modePaiement)),
                  _ligne(context, 'Date', AppFormat.date(paiement.createdAt, full: true)),
                  _ligne(context, 'Statut', paiement.statut == 'VALIDE' ? 'Validé' : 'En attente'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}