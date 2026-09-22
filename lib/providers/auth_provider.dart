import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  AuthProvider(ApiClient apiClient)
    : _authService = AuthService(apiClient),
      _userService = UserService(apiClient);

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;
  bool isLoading = false;

  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      try {
        await _loadProfile();
      } catch (_) {
        status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Inscription. Ne connecte PAS automatiquement (le backend ne renvoie
  /// pas de token au register) : retourne le message de succès à afficher,
  /// ou null en cas d'échec (voir errorMessage).
  Future<String?> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String role,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final message = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        role: role,
      );
      return message;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.login(email, password);
      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      status = AuthStatus.unauthenticated;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _userService.updateProfile(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
      );
      currentUser = updated;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      currentUser = await _authService.getCurrentUser();
      status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      await _authService.logout();
      currentUser = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }
}