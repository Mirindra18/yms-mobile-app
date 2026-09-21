import 'package:flutter/foundation.dart';
import '../models/presence_models.dart';
import '../models/presence_model.dart'; // <-- Indispensable pour PresenceEntry et PresenceStats
import '../services/api_client.dart';
import '../services/presence_service.dart';

enum LoadStatus { idle, loading, success, error }
enum ScanStatus { idle, enCours, succes, erreur }

class PresenceProvider extends ChangeNotifier {
  final PresenceService _service;

  PresenceProvider(dynamic serviceOrApiClient)
      : _service = serviceOrApiClient is PresenceService
            ? serviceOrApiClient
            : PresenceService(serviceOrApiClient as ApiClient);

  LoadStatus statutHistorique = LoadStatus.idle;
  ScanStatus statutScan = ScanStatus.idle;
  
  List<PresenceModel> historique = [];
  List<PresenceEntry> presences = [];

  bool isLoading = false;
  String? errorMessage;
  String? messageScan;

  bool _traitementEnCours = false;

  double? get tauxAssiduite => 
      presences.isNotEmpty ? PresenceStats.taux(presences) : null;
      
  int get nbPresents => 
      presences.isNotEmpty ? PresenceStats.presents(presences) : historique.length;

  Future<void> chargerHistorique() async {
    statutHistorique = LoadStatus.loading;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      historique = await _service.listerMonHistorique();
      statutHistorique = LoadStatus.success;
    } on PresenceServiceException catch (e) {
      errorMessage = e.message;
      statutHistorique = LoadStatus.error;
    } catch (_) {
      errorMessage = 'Impossible de charger vos présences.';
      statutHistorique = LoadStatus.error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> load() => chargerHistorique();

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
    } catch (_) {
      statutScan = ScanStatus.erreur;
      messageScan = 'Erreur lors du traitement du QR Code.';
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