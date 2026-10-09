import '../models/formateur_model.dart';

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class FormateurMockData {
  static List<Seance> seances(String email) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Seance s(int id, int offset, String d, String f, String titre) => Seance(
      id: id,
      date: _iso(today.add(Duration(days: offset))),
      heureDebut: '$d:00',
      heureFin: '$f:00',
      formationTitre: titre,
      formateurEmail: email,
    );
    return [
      s(1, -6, '08:00', '12:00', 'Gestion de projet agile'),
      s(2, -2, '14:00', '17:00', 'Excel avancé'),
      s(3, 0, '09:00', '12:00', 'Gestion de projet agile'),
      s(4, 0, '14:00', '16:30', 'Communication professionnelle'),
      s(5, 2, '08:30', '11:30', 'Excel avancé'),
      s(6, 5, '10:00', '13:00', 'Leadership et management'),
      s(7, 9, '14:00', '17:00', 'Communication professionnelle'),
    ];
  }

  static List<Formation> formations(String email) => [
    Formation(
      id: 1,
      titre: 'Gestion de projet agile',
      categorie: 'Management',
      dureeHeures: 40,
      dateDebut: '2026-09-15',
      dateFin: '2026-11-15',
      statut: 'EN_COURS',
      capaciteMax: 20,
      nbInscrits: 16,
      formateurEmail: email,
    ),
    Formation(
      id: 2,
      titre: 'Excel avancé',
      categorie: 'Bureautique',
      dureeHeures: 24,
      dateDebut: '2026-10-01',
      dateFin: '2026-11-30',
      statut: 'EN_COURS',
      capaciteMax: 15,
      nbInscrits: 9,
      formateurEmail: email,
    ),
    Formation(
      id: 3,
      titre: 'Leadership et management',
      categorie: 'Management',
      dureeHeures: 32,
      dateDebut: '2026-11-10',
      dateFin: '2026-12-20',
      statut: 'A_VENIR',
      capaciteMax: 25,
      nbInscrits: 6,
      formateurEmail: email,
    ),
    Formation(
      id: 4,
      titre: 'Communication professionnelle',
      categorie: 'Soft skills',
      dureeHeures: 20,
      dateDebut: '2026-08-01',
      dateFin: '2026-09-20',
      statut: 'TERMINEE',
      capaciteMax: 18,
      nbInscrits: 18,
      formateurEmail: email,
    ),
  ];

  static List<Inscription> participants() => [
    Inscription(
      id: 1,
      formationId: 1,
      userId: 11,
      userNom: 'Rakoto',
      userPrenom: 'Andry',
      userEmail: 'andry.rakoto@mail.mg',
      formationTitre: 'Gestion de projet agile',
      dateInscription: '2026-09-02',
      statut: 'VALIDEE',
    ),
    Inscription(
      id: 2,
      formationId: 1,
      userId: 12,
      userNom: 'Rasoa',
      userPrenom: 'Miora',
      userEmail: 'miora.rasoa@mail.mg',
      formationTitre: 'Gestion de projet agile',
      dateInscription: '2026-09-05',
      statut: 'VALIDEE',
    ),
    Inscription(
      id: 3,
      formationId: 2,
      userId: 13,
      userNom: 'Randria',
      userPrenom: 'Tiana',
      userEmail: 'tiana.randria@mail.mg',
      formationTitre: 'Excel avancé',
      dateInscription: '2026-09-20',
      statut: 'EN_ATTENTE',
    ),
    Inscription(
      id: 4,
      formationId: 2,
      userId: 14,
      userNom: 'Andrianina',
      userPrenom: 'Fanja',
      userEmail: 'fanja.andrianina@mail.mg',
      formationTitre: 'Excel avancé',
      dateInscription: '2026-09-22',
      statut: 'VALIDEE',
    ),
    Inscription(
      id: 5,
      formationId: 3,
      userId: 15,
      userNom: 'Razafy',
      userPrenom: 'Hery',
      userEmail: 'hery.razafy@mail.mg',
      formationTitre: 'Leadership et management',
      dateInscription: '2026-10-01',
      statut: 'ANNULEE',
    ),
  ];
}
