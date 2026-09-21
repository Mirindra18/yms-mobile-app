# Mobile ↔ microservices (development)

The Flutter app talks to the identity service at the URL passed with
`API_BASE_URL`. Never hard-code an IP address in Dart source.

| Target | Command / value |
| --- | --- |
| Flutter Windows or web on this PC | `http://localhost:8081` |
| Android Emulator | `http://10.0.2.2:8081` |
| Physical phone on the same Wi-Fi | `http://<PC-LAN-IP>:8081` |

Example for an Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
```

The current completed vertical slice is identity: registration, login, secure
JWT storage, restore-session, and profile read/update. Training, attendance,
finance and learning APIs must be migrated one service at a time before their
mobile clients switch away from the legacy backend.
