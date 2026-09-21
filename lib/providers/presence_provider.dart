import 'package:flutter/foundation.dart';

import '../models/presence_model.dart';
import '../services/api_client.dart';
import '../services/presence_service.dart';

class PresenceProvider extends ChangeNotifier {
  final PresenceService _service;

  PresenceProvider(ApiClient apiClient)
      : _service = PresenceService(apiClient);

  List<PresenceEntry> presences = [];
  bool isLoading = false;
  String? errorMessage;

  double? get tauxAssiduite => PresenceStats.taux(presences);
  int get nbPresents => PresenceStats.presents(presences);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      presences = await _service.getMesPresences();
    } on PresenceException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Impossible de charger vos présences.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}