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

  // Listes et caches globaux
  List<ElearningFormation> formations = [];
  final Map<int, ElearningContent> _parcours = {};
  final Map<int, ProgressionModel> _progressions = {};

  bool isLoading = false;
  bool isLoadingParcours = false;

  // État de lecture courante (pour l'écran de cours / lecteur)
  ElearningContent? parcours;
  ProgressionModel? progression;
  int indexLeconCourante = 0;

  List<LeconModel> get lecons => parcours?.toutesLesLecons ?? [];

  LeconModel? get leconCourante =>
      lecons.isEmpty ? null : lecons[indexLeconCourante];

  bool get estPremiereLecon => indexLeconCourante == 0;

  bool get estDerniereLecon =>
      lecons.isEmpty || indexLeconCourante == lecons.length - 1;

  ProgressionModel? progressionDe(int formationId) => _progressions[formationId];
  Map<int, ProgressionModel> get progressions => _progressions;
  ElearningContent? parcoursDe(int formationId) => _parcours[formationId];

  /// Charge la liste globale des formations
  Future<void> loadFormations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      formations = await _service.getFormations();
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger les formations en ligne.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Charge le parcours complet d'une formation ainsi que la
  /// progression existante, puis positionne la lecture sur la dernière
  /// leçon consultée (reprise de cours).
  Future<void> chargerFormation(int formationId) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final content = await _service.obtenirParcours(formationId);
      parcours = content;
      _parcours[formationId] = content;

      try {
        progression = await _service.obtenirMaProgression(formationId);
        if (progression != null) {
          _progressions[formationId] = progression!;
        }
      } catch (_) {
        // La progression peut échouer sans bloquer l'affichage du parcours
      }

      indexLeconCourante = _calculerIndexReprise();

      if (leconCourante != null) {
        await _service.demarrerLecon(formationId, leconCourante!.id);
      }

      status = LoadStatus.success;
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    } catch (_) {
      errorMessage = 'Erreur lors du chargement de la formation.';
      status = LoadStatus.error;
    }

    notifyListeners();
  }

  /// Charge uniquement le parcours d'une formation (compatibilité UI)
  Future<void> loadParcours(int formationId) async {
    isLoadingParcours = true;
    errorMessage = null;
    notifyListeners();

    try {
      final content = await _service.obtenirParcours(formationId);
      _parcours[formationId] = content;
      if (parcours?.id == formationId) {
        parcours = content;
      }
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger le contenu de la formation.';
    } finally {
      isLoadingParcours = false;
      notifyListeners();
    }
  }

  /// Charge uniquement la progression d'une formation (compatibilité UI)
  Future<void> loadProgression(int formationId) async {
    try {
      final prog = await _service.obtenirMaProgression(formationId);
      if (prog != null) {
        _progressions[formationId] = prog;
        if (progression?.formationId == formationId) {
          progression = prog;
        }
        notifyListeners();
      }
    } catch (_) {
      // Ignorer silencieusement si la progression échoue
    }
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
      try {
        final prog = await _service.demarrerLecon(formationId, lecon.id);
        progression = prog;
        _progressions[formationId] = prog;
      } catch (_) {}
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
      final prog = await _service.terminerLecon(formationId, lecon.id);
      progression = prog;
      _progressions[formationId] = prog;

      if (!estDerniereLecon) {
        await allerALaLeconSuivante(formationId);
      }
      notifyListeners();
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> demarrerLecon(int formationId, int leconId) async {
    try {
      final prog = await _service.demarrerLecon(formationId, leconId);
      progression = prog;
      _progressions[formationId] = prog;
      notifyListeners();
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> terminerLecon(int formationId, int leconId) async {
    try {
      final prog = await _service.terminerLecon(formationId, leconId);
      progression = prog;
      _progressions[formationId] = prog;
      notifyListeners();
    } on ElearningServiceException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}