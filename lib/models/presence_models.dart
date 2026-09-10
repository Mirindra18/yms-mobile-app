/// Modèles du module Présences.
///
/// À CONFIRMER AVEC SAROBIDY : le microservice presence-service
/// (ticket BACK-B3) n'est pas encore disponible dans ce dépôt au
/// moment de l'écriture de ce module. Le contrat ci-dessous est une
/// hypothèse de travail cohérente avec les règles de gestion
/// RG-PRES-01 à RG-PRES-06 définies dans les spécifications du projet.
/// Ajuster les champs dès que l'API réelle sera publiée.

enum StatutPresence { present, absent, retard, excuse }

StatutPresence statutPresenceFromJson(String value) {
  switch (value) {
    case 'ABSENT':
      return StatutPresence.absent;
    case 'RETARD':
      return StatutPresence.retard;
    case 'EXCUSE':
      return StatutPresence.excuse;
    default:
      return StatutPresence.present;
  }
}

extension StatutPresenceLibelle on StatutPresence {
  String get libelle => switch (this) {
        StatutPresence.present => 'Présent',
        StatutPresence.absent => 'Absent',
        StatutPresence.retard => 'En retard',
        StatutPresence.excuse => 'Excusé',
      };
}

enum MethodeValidation { qrCode, manuel, biometrie }

class PresenceModel {
  final int id;
  final int sessionId;
  final String? intituleSession;
  final StatutPresence statut;
  final MethodeValidation methode;
  final DateTime dateHeure;

  PresenceModel({
    required this.id,
    required this.sessionId,
    this.intituleSession,
    required this.statut,
    required this.methode,
    required this.dateHeure,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      intituleSession: json['intituleSession'] as String?,
      statut: statutPresenceFromJson(json['statut'] as String? ?? 'PRESENT'),
      methode: MethodeValidation.qrCode,
      dateHeure: DateTime.parse(json['dateHeure'] as String),
    );
  }
}
