import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/elearning_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/formation_provider.dart';
import 'providers/presence_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/root_shell.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FormationProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FinanceProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => PresenceProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ElearningProvider(apiClient)),
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
      title: 'YMS — Formation & Excellence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const RootShell();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}