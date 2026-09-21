import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../models/formation_model.dart';
import '../services/api_client.dart';

class FormationProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  FormationProvider(this._apiClient);

  List<FormationModel> formations = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadFormations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/api/formations');
      final data = response.data;
      if (data is List) {
        formations = data
            .map((e) => FormationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on DioException catch (e) {
      errorMessage = _extractError(e, 'Impossible de charger les formations.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  FormationModel? formationById(int id) {
    for (final formation in formations) {
      if (formation.id == id) return formation;
    }
    return null;
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}