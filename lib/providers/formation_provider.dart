import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/formation_model.dart';
import '../services/api_client.dart';

class FormationProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  FormationProvider(this._apiClient);

  List<FormationModel> formations = [];

  /// IDs des formations auxquelles l'utilisateur connecté est inscrit.
  Set<int> _mesFormationIds = {};

  bool isLoading = false;
  bool isLoadingInscriptions = false;

  String? errorMessage;
  String? inscriptionErrorMessage;

  /// Toutes les formations disponibles.
  Future<void> loadFormations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await _apiClient.dio.get('/api/formations');

      final data = response.data;

      if (data is List) {
        formations = data
            .whereType<Map>()
            .map(
              (e) => FormationModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } on DioException catch (e) {
      errorMessage = _extractError(
        e,
        'Impossible de charger les formations.',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Charge uniquement les inscriptions de l'utilisateur connecté.
  ///
  /// Backend :
  /// GET /api/inscriptions/me
  Future<void> loadMesInscriptions() async {
    isLoadingInscriptions = true;
    inscriptionErrorMessage = null;
    notifyListeners();

    try {
      final response =
          await _apiClient.dio.get('/api/inscriptions/me');

      final data = response.data;

      if (data is List) {
        final ids = <int>{};

        for (final item in data) {
          if (item is! Map) continue;

          final formationId = item['formationId'];

          if (formationId is num) {
            ids.add(formationId.toInt());
          } else if (formationId != null) {
            final parsed = int.tryParse(
              formationId.toString(),
            );

            if (parsed != null) {
              ids.add(parsed);
            }
          }
        }

        _mesFormationIds = ids;
      } else {
        _mesFormationIds = {};
      }
    } on DioException catch (e) {
      inscriptionErrorMessage = _extractError(
        e,
        'Impossible de charger vos inscriptions.',
      );

      _mesFormationIds = {};
    } finally {
      isLoadingInscriptions = false;
      notifyListeners();
    }
  }

  /// Nombre de formations auxquelles l'utilisateur est inscrit.
  int get nombreFormationsInscrites =>
      _mesFormationIds.length;

  /// IDs des formations de l'utilisateur.
  Set<int> get mesFormationIds =>
      Set.unmodifiable(_mesFormationIds);

  /// Retourne les formations disponibles auxquelles
  /// l'utilisateur est inscrit.
  List<FormationModel> get mesFormations {
    return formations
        .where(
          (formation) =>
              _mesFormationIds.contains(formation.id),
        )
        .toList();
  }

  FormationModel? formationById(int id) {
    for (final formation in formations) {
      if (formation.id == id) {
        return formation;
      }
    }

    return null;
  }

  String _extractError(
    DioException e,
    String fallback,
  ) {
    final data = e.response?.data;

    if (data is Map &&
        data['message'] is String) {
      return data['message'] as String;
    }

    return fallback;
  }
}