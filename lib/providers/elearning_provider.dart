import 'package:flutter/foundation.dart';
import '../models/elearning_models.dart';
import '../services/elearning_service.dart';

enum LoadStatus { idle, loading, success, error }

/// Fournit à l'interface l'état du parcours d'une formation et de la
/// progression de l'apprenant, ainsi que les actions de navigation
/// entre leçons avec reprise automatique de la lecture.
class ElearningProvider extends ChangeNotifier {
  final ElearningService _service;

  ElearningProvider(this._service);

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;

  FormationContentModel? parcours;
  ProgressionModel? progression;
  int indexLeconCourante = 0;

  List<LeconModel> get lecons => parcours?.toutesLesLecons ?? [];

  LeconModel? get leconCourante =>
      lecons.isEmpty ? null : lecons[indexLeconCourante];

  bool get estPremiereLecon => indexLeconCourante == 0;

  bool get estDerniereLecon => lecons.isEmpty || indexLeconCourante == lecons.length - 1;

  /// Charge le parcours complet d'une formation ainsi que la
  /// progression existante, puis positionne la lecture sur la dernière
  /// leçon consultée (reprise de cours, ticket MOB-B1).
  Future<void> chargerFormation(int formationId) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      parcours = await _service.obtenirParcours(formationId);
      progression = await _service.obtenirMaProgression(formationId);
      indexLeconCourante = _calculerIndexReprise();

      if (leconCourante != null) {
        await _service.demarrerLecon(formationId, leconCourante!.id);
      }

      status = LoadStatus.success;
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }

    notifyListeners();
  }

  int _calculerIndexReprise() {
    final derniereLeconId = progression?.derniereLeconId;
    if (derniereLeconId == null) return 0;

    final index = lecons.indexWhere((lecon) => lecon.id == derniereLeconId);
    return index == -1 ? 0 : index;
  }

  Future<void> allerALaLeconSuivante(int formationId) async {
    if (estDerniereLecon) return;
    indexLeconCourante += 1;
    notifyListeners();
    final lecon = leconCourante;
    if (lecon != null) {
      await _service.demarrerLecon(formationId, lecon.id);
    }
  }

  void allerALaLeconPrecedente() {
    if (!estPremiereLecon) {
      indexLeconCourante -= 1;
      notifyListeners();
    }
  }

  /// Marque la leçon courante comme terminée et avance vers la
  /// suivante, ou clôture le parcours si c'était la dernière leçon.
  Future<void> terminerLeconCourante(int formationId) async {
    final lecon = leconCourante;
    if (lecon == null) return;

    try {
      progression = await _service.terminerLecon(formationId, lecon.id);
      if (!estDerniereLecon) {
        await allerALaLeconSuivante(formationId);
      }
      notifyListeners();
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}
