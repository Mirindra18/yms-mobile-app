import 'package:flutter/material.dart';

class FormateurTab {
  final String label;
  final IconData icon;
  const FormateurTab(this.label, this.icon);
}

/// Index des destinations du shell (ordre = ordre du menu latéral).
class FormateurTabs {
  static const accueil = 0;
  static const elearning = 1;
  static const formations = 2;
  static const sessions = 3;
  static const calendrier = 4;
  static const participants = 5;
  static const presence = 6;
  static const profil = 7;

  static const all = <FormateurTab>[
    FormateurTab('Accueil', Icons.home_rounded),
    FormateurTab('E-Learning', Icons.school_rounded),
    FormateurTab('Formations', Icons.menu_book_rounded),
    FormateurTab('Sessions', Icons.event_available_rounded),
    FormateurTab('Calendrier', Icons.calendar_month_rounded),
    FormateurTab('Participants', Icons.groups_rounded),
    FormateurTab('Présence', Icons.fact_check_rounded),
    FormateurTab('Profil', Icons.person_rounded),
  ];
}
