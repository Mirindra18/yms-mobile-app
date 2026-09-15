# Intégration mobile — E-learning, Consultations, Présences, Notifications

Tickets MOB-B1 (lecteur E-learning + module RDV/Consultations) et
MOB-B2 (scanner QR Code de présence + centre de notifications temps réel).

## 1. Dépendances à ajouter dans `pubspec.yaml`

Voir `pubspec_additions.yaml` fourni avec ce lot. En résumé, s'ajoutent
aux dépendances déjà présentes (`dio`, `flutter_secure_storage`, `provider`) :

```yaml
dependencies:
  intl: ^0.19.0
  url_launcher: ^6.3.0
  mobile_scanner: ^5.2.3
  stomp_dart_client: ^2.0.0
```

Puis : `flutter pub get`

## 2. Fichiers fournis

```
lib/
  models/
    elearning_models.dart       (Formation, Chapitre, Lecon, Ressource, Progression)
    consultation_models.dart    (Creneau, Consultation, StatutConsultation)
    presence_models.dart        (Presence, StatutPresence)
    notification_models.dart    (Notification, TypeNotification)
  services/
    elearning_service.dart
    consultation_service.dart
    presence_service.dart
    notification_service.dart          (partie REST)
    notification_realtime_service.dart (partie WebSocket/STOMP)
  providers/
    elearning_provider.dart
    consultation_provider.dart
    presence_provider.dart
    notification_provider.dart
  screens/
    formations_list_screen.dart
    lecteur_elearning_screen.dart
    creneaux_list_screen.dart
    mes_consultations_screen.dart
    qr_scanner_screen.dart
    historique_presence_screen.dart
    notifications_center_screen.dart
  widgets/
    ressource_viewer.dart
    notification_badge_icon.dart
```

## 3. Permissions caméra (nécessaires pour `mobile_scanner`)

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>Cette application utilise la caméra pour scanner le QR Code de présence.</string>
```

## 4. Câblage dans `main.dart`

À fusionner manuellement avec le `main.dart` existant (ne pas écraser),
selon le même principe que `main_example_wiring.dart` :

```dart
final apiClient = ApiClient();

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
    ChangeNotifierProvider(create: (_) => ElearningProvider(ElearningService(apiClient))),
    ChangeNotifierProvider(create: (_) => ConsultationProvider(ConsultationService(apiClient))),
    ChangeNotifierProvider(create: (_) => PresenceProvider(PresenceService(apiClient))),
    ChangeNotifierProvider(create: (_) => NotificationProvider(
      NotificationService(apiClient),
      NotificationRealtimeService(apiClient),
    )),
  ],
  child: const YmsApp(),
);
```

Démarrer l'écoute temps réel juste après le chargement du profil
(dans `AuthProvider._loadProfile` ou juste après, une fois
`currentUser` disponible) :

```dart
await context.read<NotificationProvider>().demarrerEcouteTempsReel(currentUser!);
```

Et l'arrêter à la déconnexion (`AuthProvider.logout`) :
```dart
context.read<NotificationProvider>().arreterEcouteTempsReel();
```

## 5. Points à adapter/confirmer avant de commiter

- **`ApiClient.baseUrl`** : les microservices `consultation-service`
  (port 8084) et `notification-service` (port 8085) tournent
  aujourd'hui comme processus indépendants. Ce module suppose que
  l'API Gateway (Sarobidy) route `/api/consultations/**` et
  `/api/notifications/**` vers ces services, exactement comme pour les
  autres modules. Si le Gateway n'est pas encore prêt, adapter les
  base URL le temps de l'intégration finale.
- **Canal WebSocket temps réel** (`notification_realtime_service.dart`) :
  le backend expose l'endpoint avec SockJS
  (`/ws/notifications`). Ce module se connecte directement au
  transport WebSocket brut (`/ws/notifications/websocket`), solution
  pragmatique en l'absence de client SockJS complet pour Dart. À
  valider une fois le Gateway et la configuration CORS/WebSocket
  finalisés.
- **`presence_service.dart`** : le microservice `presence-service`
  (ticket BACK-B3, Sarobidy) n'existe pas encore dans le dépôt backend
  au moment de l'écriture de ce module. Les endpoints
  `POST /api/presences/scan` et `GET /api/presences/moi` sont une
  hypothèse de travail cohérente avec les règles RG-PRES-01 à
  RG-PRES-06. **À confirmer avec Sarobidy** dès que le service sera
  disponible, et ajuster `presence_models.dart` en conséquence.
- **Jeton JWT** : comme pour le module Auth existant, le contenu exact
  du jeton (email vs id numérique dans le `subject`) doit être
  confirmé avec Fiderana. `notification_realtime_service.dart` envoie
  le jeton en en-tête `Authorization` à la connexion WebSocket.

## 6. Correspondance avec les règles de gestion

| Règle | Fichier |
|---|---|
| Reprise de cours (dernière leçon consultée) | `elearning_provider.dart` (`_calculerIndexReprise`) |
| RG-CON-01 (demande de consultation sur créneau disponible) | `consultation_service.dart`, `creneaux_list_screen.dart` |
| RG-CON-06 (reprogrammation) | `consultation_provider.dart`, `mes_consultations_screen.dart` |
| RG-PRES-04 (présence par scan de QR Code) | `qr_scanner_screen.dart`, `presence_service.dart` |
| RG-NOT-04/05 (consultation et marquage lu/non lu) | `notification_provider.dart`, `notifications_center_screen.dart` |
| RG-NOT-07 (diffusion temps réel) | `notification_realtime_service.dart` |

## 7. Tests

Ce lot ne fournit pas de tests automatisés Flutter (widget/unit tests)
dans cette itération : seul le test par défaut généré par Flutter
(`test/widget_test.dart`, compteur de démonstration) est présent à ce
jour dans le dépôt, aucun test métier n'existe encore pour les autres
modules non plus. Recommandé pour une prochaine itération : tests unitaires sur les providers
(`ElearningProvider._calculerIndexReprise`, transitions de
`ConsultationProvider`) avec `mockito` ou `mocktail`.
