import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

// Import-ao eto koa ireo services sy providers vaovao nampiana:
import 'services/elearning_service.dart';
import 'providers/elearning_provider.dart';
import 'services/consultation_service.dart';
import 'providers/consultation_provider.dart';
import 'services/presence_service.dart';
import 'providers/presence_provider.dart';
import 'services/notification_service.dart';
import 'services/notification_realtime_service.dart';
import 'providers/notification_provider.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        
        // --- Nampiana eto ireo providers vaovao ---
        ChangeNotifierProvider(
          create: (_) => ElearningProvider(ElearningService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsultationProvider(ConsultationService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => PresenceProvider(PresenceService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            NotificationService(apiClient),
            NotificationRealtimeService(apiClient),
          ),
        ),
      ],
      child: const YmsApp(),
    ),
  );
}

class YmsApp extends StatelessWidget {
  const YmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E5AAC),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const ProfileScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}