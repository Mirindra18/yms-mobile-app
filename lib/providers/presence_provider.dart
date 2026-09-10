import 'package:flutter/foundation.dart';
import '../models/presence_models.dart';
import '../services/presence_service.dart';

enum LoadStatus { idle, loading, success, error }
enum ScanStatus { idle, enCours, succes, erreur }

class PresenceProvider extends ChangeNotifier {
  final PresenceService _service;

  PresenceProvider(this._service);

  LoadStatus statutHistorique = LoadStatus.idle;
  String? errorMessage;
  List<PresenceModel> historique = [];

  ScanStatus statutScan = ScanStatus.idle;
  String? messageScan;

  /// Empêche de traiter deux fois le même QR Code scanné en rafale par
  /// la caméra avant que la requête réseau ne soit terminée.
  bool _traitementEnCours = false;

  Future<void> chargerHistorique() async {
    statutHistorique = LoadStatus.loading;
    notifyListeners();

    try {
      historique = await _service.listerMonHistorique();
      statutHistorique = LoadStatus.success;
    } on PresenceServiceException catch (e) {
      errorMessage = e.message;
      statutHistorique = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> validerQrCode(String contenu) async {
    if (_traitementEnCours) return;
    _traitementEnCours = true;

    statutScan = ScanStatus.enCours;
    messageScan = null;
    notifyListeners();

    try {
      final presence = await _service.validerPresenceParQrCode(contenu);
      historique = [presence, ...historique];
      statutScan = ScanStatus.succes;
      messageScan = 'Présence enregistrée avec succès.';
    } on PresenceServiceException catch (e) {
      statutScan = ScanStatus.erreur;
      messageScan = e.message;
    }

    notifyListeners();
    _traitementEnCours = false;
  }

  void reinitialiserScan() {
    statutScan = ScanStatus.idle;
    messageScan = null;
    notifyListeners();
  }
}
