import 'package:flutter/foundation.dart';

import '../models/finance_models.dart';
import '../services/api_client.dart';
import '../services/finance_service.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceService _service;

  FinanceProvider(ApiClient apiClient) : _service = FinanceService(apiClient);

  List<EcolageModel> ecolages = [];
  bool isLoading = false;
  String? errorMessage;

  double get soldeTotal =>
      ecolages.fold(0, (sum, e) => sum + e.soldeDu);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      ecolages = await _service.getMesEcolages();
    } on FinanceException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger vos écolages.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PaiementModel> payer({
    required int echeanceId,
    required double montant,
    required String modePaiement,
  }) async {
    final paiement = await _service.payer(
      echeanceId: echeanceId,
      montant: montant,
      modePaiement: modePaiement,
    );
    await load();
    return paiement;
  }
}