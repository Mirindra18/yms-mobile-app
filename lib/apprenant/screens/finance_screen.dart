import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_models.dart';
import '../../providers/finance_provider.dart';
import '../../providers/formation_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().load();
      context.read<FormationProvider>().loadFormations();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<FinanceProvider>().load(),
      context.read<FormationProvider>().loadFormations(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final formationProvider = context.watch<FormationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F4EF),
        foregroundColor: const Color(0xFF2F2924),
        title: const Text(
          'Mon écolage',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, finance, formationProvider),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FinanceProvider finance,
    FormationProvider formationProvider,
  ) {
    if (finance.isLoading && finance.ecolages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (finance.errorMessage != null && finance.ecolages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger vos informations financières.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            finance.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: finance.load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (finance.ecolages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 70),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE5D8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 46,
              color: Color(0xFF8B6F47),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun écolage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F2924),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Votre écolage apparaîtra ici lorsque votre dossier financier aura été créé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5DED4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF8B6F47)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'L’inscription à une formation et la création de votre écolage sont deux opérations différentes. Si vous êtes déjà inscrit mais que cet écran reste vide, votre écolage doit encore être créé par l’administration.',
                    style: TextStyle(height: 1.45, color: Color(0xFF5F574F)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final total = finance.ecolages.fold<double>(
      0,
      (sum, ecolage) => sum + ecolage.montantTotal,
    );

    final solde = finance.soldeTotal;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildSummaryCard(total: total, solde: solde),
        const SizedBox(height: 20),

        if (finance.ecolages.length > 1)
          _buildSectionTitle('Mes formations', Icons.school_outlined),

        if (finance.ecolages.length > 1) const SizedBox(height: 10),

        ...finance.ecolages.map(
          (ecolage) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEcolageCard(context, ecolage, formationProvider),
          ),
        ),

        if (finance.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              finance.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard({required double total, required double solde}) {
    final paye = total - solde;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3A2A), Color(0xFF765E42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Situation financière',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Solde restant',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            _formatAr(solde),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _summaryValue('Total', _formatAr(total))),
              Expanded(child: _summaryValue('Déjà payé', _formatAr(paye))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEcolageCard(
    BuildContext context,
    EcolageModel ecolage,
    FormationProvider formationProvider,
  ) {
    final formation = formationProvider.formationById(ecolage.formationId);

    final titre =
        formation?.titre ??
        (ecolage.formationId > 0
            ? 'Formation #${ecolage.formationId}'
            : 'Formation');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DED3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E8DC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Color(0xFF806543),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F2924),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Montant total : ${_formatAr(ecolage.montantTotal)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDE7DF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Solde restant',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5F574F),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatAr(ecolage.soldeDu),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ecolage.estSolder
                            ? const Color(0xFF3E7C5A)
                            : const Color(0xFF9B5E25),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (ecolage.estSolder)
                  _buildPaidBadge()
                else ...[
                  const Text(
                    'Échéances',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF2F2924),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...ecolage.echeances.map(
                    (echeance) => _buildEcheanceCard(context, echeance),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF3E7C5A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cette formation est entièrement réglée.',
              style: TextStyle(
                color: Color(0xFF3E7C5A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcheanceCard(BuildContext context, EcheanceModel echeance) {
    final payee = echeance.isPayee;
    final paiementEnAttente = echeance.paiementEnAttente;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9E1D8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: payee
                      ? const Color(0xFFE8F2EB)
                      : const Color(0xFFF2EADF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  payee ? Icons.check_rounded : Icons.calendar_month_outlined,
                  size: 21,
                  color: payee
                      ? const Color(0xFF3E7C5A)
                      : const Color(0xFF806543),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      echeance.moisLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF332D27),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paiementEnAttente
                          ? 'Paiement en attente de validation'
                          : echeance.statutLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: paiementEnAttente
                            ? const Color(0xFF9B6B14)
                            : echeance.isEnRetard
                            ? const Color(0xFFB0483C)
                            : payee
                            ? const Color(0xFF3E7C5A)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatAr(echeance.montant),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF332D27),
                ),
              ),
            ],
          ),
          if (echeance.dateLimite != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Date limite : ${shortDate(echeance.dateLimite!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
          if (paiementEnAttente) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6DF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D69D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentMethodLabel(echeance.modePaiement),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF765712),
                    ),
                  ),
                  if (echeance.referenceTransaction?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Référence : ${echeance.referenceTransaction}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF765712),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Votre échéance sera réglée après vérification par l’administration.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF765712),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (echeance.payableNow && !paiementEnAttente) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentSheet(context, echeance),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text('Payer cette échéance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF806543),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPaymentSheet(
    BuildContext context,
    EcheanceModel echeance,
  ) async {
    final referenceController = TextEditingController();
    String modePaiement = 'MVOLA';
    var isSubmitting = false;
    String? errorMessage;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitPayment() async {
              final reference = referenceController.text.trim();
              final paiementEspeces = modePaiement == 'ESPECES';
              if (!paiementEspeces && reference.isEmpty) {
                setSheetState(() {
                  errorMessage = 'La référence de transaction est obligatoire.';
                });
                return;
              }

              setSheetState(() {
                isSubmitting = true;
                errorMessage = null;
              });
              try {
                await context.read<FinanceProvider>().payer(
                  echeanceId: echeance.id,
                  montant: echeance.montant,
                  modePaiement: modePaiement,
                  referenceTransaction: paiementEspeces ? '' : reference,
                );
                if (!sheetContext.mounted || !mounted) return;
                Navigator.of(sheetContext).pop();
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    icon: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFF9B6B14),
                      size: 48,
                    ),
                    title: const Text('Demande envoyée'),
                    content: Text(
                      'Votre paiement ${_paymentMethodLabel(modePaiement)} '
                      'est enregistré en attente de validation.\n\n'
                      '${paiementEspeces ? '' : 'Référence : $reference\n'}'
                      'L’échéance sera marquée payée après vérification '
                      'par l’administration.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Compris'),
                      ),
                    ],
                  ),
                );
              } catch (error) {
                if (!sheetContext.mounted) return;
                setSheetState(() {
                  isSubmitting = false;
                  errorMessage = error.toString();
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Payer l’échéance',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F2924),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          echeance.moisLabel,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3ED),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: Color(0xFF806543),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Montant à payer',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                _formatAr(echeance.montant),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Choisissez un moyen de paiement',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 56) / 2,
                              child: _PaymentMethodCard(
                                title: 'MVola',
                                asset: 'assets/images/Mvola.png',
                                selected: modePaiement == 'MVOLA',
                                onTap: isSubmitting
                                    ? null
                                    : () => setSheetState(
                                        () => modePaiement = 'MVOLA',
                                      ),
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 56) / 2,
                              child: _PaymentMethodCard(
                                title: 'Orange Money',
                                asset: 'assets/images/Orange.webp',
                                selected: modePaiement == 'ORANGE_MONEY',
                                onTap: isSubmitting
                                    ? null
                                    : () => setSheetState(
                                        () => modePaiement = 'ORANGE_MONEY',
                                      ),
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 56) / 2,
                              child: _PaymentMethodCard(
                                title: 'Airtel Money',
                                asset: 'assets/images/Airtel.webp',
                                selected: modePaiement == 'AIRTEL_MONEY',
                                onTap: isSubmitting
                                    ? null
                                    : () => setSheetState(
                                        () => modePaiement = 'AIRTEL_MONEY',
                                      ),
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 56) / 2,
                              child: _PaymentMethodCard(
                                title: 'Espèces',
                                icon: Icons.payments_outlined,
                                selected: modePaiement == 'ESPECES',
                                onTap: isSubmitting
                                    ? null
                                    : () => setSheetState(
                                        () => modePaiement = 'ESPECES',
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (modePaiement != 'ESPECES') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: referenceController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Référence de transaction *',
                              hintText: 'Ex. numéro de transaction reçu',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            modePaiement == 'ESPECES'
                                ? 'Remettez le montant en espèces à '
                                      'l’administration. La demande restera en '
                                      'attente jusqu’à la confirmation de '
                                      'l’encaissement.'
                                : 'Effectuez le transfert avec l’application '
                                      'ou le menu de votre opérateur, puis '
                                      'saisissez la référence figurant sur la '
                                      'confirmation. L’administration vérifiera '
                                      'le paiement avant de valider l’échéance.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Color(0xFF765712),
                            ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB0483C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSubmitting ? null : submitPayment,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              isSubmitting
                                  ? 'Envoi en cours...'
                                  : 'Envoyer pour validation',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF806543),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } finally {
      referenceController.dispose();
    }
  }

  String _paymentMethodLabel(String? method) => switch (method) {
    'MVOLA' => 'MVola',
    'ORANGE_MONEY' => 'Orange Money',
    'AIRTEL_MONEY' => 'Airtel Money',
    'ESPECES' => 'Espèces',
    null || '' => 'Mobile Money',
    _ => method,
  };

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF806543)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2F2924),
          ),
        ),
      ],
    );
  }

  String _formatAr(double value) {
    final number = value.round().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );

    return '$formatted Ar';
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String? asset;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const _PaymentMethodCard({
    required this.title,
    this.asset,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF806543)
        : const Color(0xFFE5DED4);

    return Material(
      color: selected ? const Color(0xFFFFF8E7) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: asset == null
                    ? Icon(
                        icon ?? Icons.account_balance_wallet_outlined,
                        size: 36,
                        color: const Color(0xFF806543),
                      )
                    : Image.asset(
                        asset!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          icon ?? Icons.account_balance_wallet_outlined,
                          color: const Color(0xFF806543),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF4A3928)
                      : const Color(0xFF5F574F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
