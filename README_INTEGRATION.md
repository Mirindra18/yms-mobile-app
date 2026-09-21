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

## 3. Câblage actuel
Le `main.dart` instancie `ApiClient`, `AuthProvider` et un `AuthGate`.
`GET /api/users/me` est exposé côté backend. L'URL se règle au lancement :

`flutter run --dart-define=API_BASE_URL=http://localhost:8081`

## 4. Correspondance avec les règles de gestion
- RG5 (modif profil) → `profile_screen.dart` + `user_service.dart` (`updateProfile`)
- RG6 (stockage sécurisé du token) → `flutter_secure_storage` dans `api_client.dart` / `auth_service.dart`
