import 'package:flutter/material.dart';

import '../formateur/screens/calendrier_screen.dart';
import '../formateur/screens/formations_screen.dart';
import '../formateur/screens/participants_screen.dart';
import '../formateur/screens/placeholder_screen.dart';
import '../formateur/screens/sessions_screen.dart';
import '../formateur/formateur_shell.dart';
import 'formateur_routes.dart';

/// À brancher dans ton MaterialApp :
///   onGenerateRoute: (s) => FormateurRouter.generate(s) ?? tonRouterActuel(s)
/// ou à appeler depuis ton routing existant pour les chemins de l'espace formateur.
class FormateurRouter {
  static bool handles(String? name) =>
      FormateurRoutes.all.any((r) => r.path == name);

  static Route<dynamic>? generate(RouteSettings settings) {
    if (!handles(settings.name)) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _screen(settings.name),
    );
  }

  static Widget _screen(String? name) {
    switch (name) {
      case '/formations':
        return const FormationsScreen();
      case '/sessions':
        return const SessionsScreen();
      case '/calendrier':
        return const CalendrierScreen();
      case '/participants':
        return const ParticipantsScreen();
      case '/contenus':
        return const PlaceholderScreen(
            route: FormateurRoutes.contenus,
            description: 'Contenus pédagogiques réservés aux formateurs.');
      case '/presences':
        return const PlaceholderScreen(
            route: FormateurRoutes.presences,
            description: 'Suivi des présences de vos apprenants.');
      case '/quiz':
        return const PlaceholderScreen(
            route: FormateurRoutes.quiz,
            description: 'Création et gestion de vos quiz.');
      case '/resultats':
        return const PlaceholderScreen(
            route: FormateurRoutes.resultats,
            description: 'Résultats des quiz de vos apprenants.');
      case '/':
      default:
        return const FormateurShell();
    }
  }
}
