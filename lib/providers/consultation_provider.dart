import 'package:flutter/foundation.dart';
import '../models/consultation_models.dart';
import '../services/consultation_service.dart';

enum LoadStatus { idle, loading, success, error }

class ConsultationProvider extends ChangeNotifier {
  final ConsultationService _service;

  ConsultationProvider(this._service);

  LoadStatus statutCreneaux = LoadStatus.idle;
  LoadStatus statutConsultations = LoadStatus.idle;
  String? errorMessage;

  List<CreneauModel> creneauxDisponibles = [];
  List<ConsultationModel> mesConsultations = [];

  Future<void> chargerCreneauxDisponibles() async {
    statutCreneaux = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      creneauxDisponibles = await _service.listerCreneauxDisponibles();
      statutCreneaux = LoadStatus.success;
    } on ConsultationServiceException catch (e) {
      errorMessage = e.message;
      statutCreneaux = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> chargerMesConsultations() async {
    statutConsultations = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      mesConsultations = await _service.listerMesConsultations();
      statutConsultations = LoadStatus.success;
    } on ConsultationServiceException catch (e) {
      errorMessage = e.message;
      statutConsultations = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Demande une consultation. Retourne vrai en cas de succès. [RG-CON-01]
  Future<bool> demanderConsultation({required int creneauId, String? motif}) async {
    try {
      final consultation = await _service.demanderConsultation(creneauId: creneauId, motif: motif);
      mesConsultations = [consultation, ...mesConsultations];
      notifyListeners();
      return true;
    } on ConsultationServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> annuler(int consultationId) async {
    try {
      final miseAJour = await _service.annuler(consultationId);
      _remplacer(miseAJour);
      return true;
    } on ConsultationServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reprogrammer({required int consultationId, required int nouveauCreneauId}) async {
    try {
      final miseAJour = await _service.reprogrammer(
        consultationId: consultationId,
        nouveauCreneauId: nouveauCreneauId,
      );
      _remplacer(miseAJour);
      return true;
    } on ConsultationServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void _remplacer(ConsultationModel miseAJour) {
    mesConsultations = mesConsultations
        .map((c) => c.id == miseAJour.id ? miseAJour : c)
        .toList();
    notifyListeners();
  }
}
