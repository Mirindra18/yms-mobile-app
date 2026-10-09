import 'package:flutter/material.dart';


class FormateurRoute {
  final String path;
  final String label;
  final IconData icon;
  const FormateurRoute(this.path, this.label, this.icon);
}

class FormateurRoutes {
  static const accueil = FormateurRoute('/', 'Accueil', Icons.home_rounded);
  static const formations =
      FormateurRoute('/formations', 'Mes formations', Icons.menu_book_rounded);
  static const sessions =
      FormateurRoute('/sessions', 'Mes sessions', Icons.event_available_rounded);
  static const calendrier =
      FormateurRoute('/calendrier', 'Calendrier', Icons.calendar_month_rounded);
  static const participants =
      FormateurRoute('/participants', 'Participants', Icons.groups_rounded);
  static const contenus =
      FormateurRoute('/contenus', 'Contenus', Icons.folder_copy_rounded);
  static const presences =
      FormateurRoute('/presences', 'Présences', Icons.fact_check_rounded);
  static const quiz = FormateurRoute('/quiz', 'Quiz', Icons.quiz_rounded);
  static const resultats =
      FormateurRoute('/resultats', 'Résultats', Icons.leaderboard_rounded);

  static const all = [
    accueil,
    formations,
    sessions,
    calendrier,
    participants,
    contenus,
    presences,
    quiz,
    resultats,
  ];
}
