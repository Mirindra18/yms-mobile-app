import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/elearning_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/formation_provider.dart';
import 'providers/formateur_provider.dart';
import 'providers/presence_provider.dart';
import 'auth/screens/login_screen.dart';
import 'routing/role_router.dart';
import 'services/api_client.dart';
import 'services/elearning_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final apiClient = ApiClient();
  // No bundled font files are available in the app assets, so runtime fetching
  // is required for the branded Google Fonts used across the UI.
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FormationProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FormateurProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => PresenceProvider(apiClient)),
        ChangeNotifierProvider(
          create: (_) => ElearningProvider(ElearningService(apiClient)),
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
      context.read<AuthProvider>().requireLoginAtStartup();
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
        final user = auth.currentUser!;
        return RoleRouter.getHome(user);

      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
