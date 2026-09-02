# Intégration mobile — Auth & Profil

## 1. Dépendances à ajouter dans `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1

dev_dependencies:
  flutter_lints: ^4.0.0
```

Puis : `flutter pub get`

## 2. Fichiers fournis
```
lib/
  models/user_model.dart
  services/api_client.dart
  services/auth_service.dart
  services/user_service.dart
  providers/auth_provider.dart
  screens/login_screen.dart
  screens/profile_screen.dart
  main_example_wiring.dart   <- exemple à fusionner dans main.dart existant
```

## 3. Points à adapter avant de commiter
- `ApiClient.baseUrl` : remplacer par l'URL réelle de l'API Gateway
  (Sarobidy) ou du backend, selon la topologie retenue par l'équipe.
- `AuthService.login` : le endpoint `/api/auth/login` et le format de
  réponse (`{ "token": "..." }`) doivent être confirmés avec Fiderana
  qui gère le JWT côté backend.
- `UserService.getProfile` : suppose un `GET /api/users/me`. Si ce
  endpoint n'existe pas côté backend (le sprint ne liste que POST/PUT),
  soit l'ajouter côté backend, soit décoder le JWT côté mobile pour
  récupérer les infos de base.
- Ne pas fusionner `main_example_wiring.dart` tel quel s'il existe déjà
  un `main.dart` avec d'autres providers/routes — fusionner manuellement.

## 4. Correspondance avec les règles de gestion
- RG5 (modif profil) → `profile_screen.dart` + `user_service.dart` (`updateProfile`)
- RG6 (stockage sécurisé du token) → `flutter_secure_storage` dans `api_client.dart` / `auth_service.dart`
