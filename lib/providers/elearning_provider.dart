import 'package:flutter/foundation.dart';

import '../models/elearning_models.dart';
import '../services/api_client.dart';
import '../services/elearning_service.dart';

class ElearningProvider extends ChangeNotifier {
  final ElearningService _service;

  ElearningProvider(ApiClient apiClient)
      : _service = ElearningService(apiClient);

  List<ElearningFormation> formations = [];
  final Map<int, ElearningContent> _parcours = {};
  final Map<int, ProgressionModel> _progressions = {};

  bool isLoading = false;
  bool isLoadingParcours = false;
  String? errorMessage;

  ProgressionModel? progressionDe(int formationId) => _progressions[formationId];

  Map<int, ProgressionModel> get progressions => _progressions;

  ElearningContent? parcoursDe(int formationId) => _parcours[formationId];

  Future<void> loadFormations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      formations = await _service.getFormations();
    } on ElearningException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger les formations en ligne.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadParcours(int formationId) async {
    isLoadingParcours = true;
    errorMessage = null;
    notifyListeners();

    try {
      _parcours[formationId] = await _service.getParcours(formationId);
    } on ElearningException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger le parcours.';
    } finally {
      isLoadingParcours = false;
      notifyListeners();
    }
  }

  Future<void> loadProgression(int formationId) async {
    try {
      _progressions[formationId] = await _service.getMaProgression(formationId);
      notifyListeners();
    } on ElearningException {
      // Ne bloque pas le parcours si la progression échoue.
    }
  }

  Future<void> demarrerLecon(int formationId, int leconId) async {
    final progression =
        await _service.demarrerLecon(formationId, leconId);
    _progressions[formationId] = progression;
    notifyListeners();
  }

  Future<void> terminerLecon(int formationId, int leconId) async {
    final progression = await _service.terminerLecon(formationId, leconId);
    _progressions[formationId] = progression;
    notifyListeners();
  }
}