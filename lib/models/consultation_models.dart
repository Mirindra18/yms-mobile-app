/// Modèles du module Consultations / RDV.
/// Correspondent exactement aux DTO exposés par consultation-service
/// (ConsultationController) : CreneauResponse, ConsultationResponse.

enum StatutConsultation { enAttente, confirmee, terminee, annulee, reprogrammee }

StatutConsultation statutConsultationFromJson(String value) {
  switch (value) {
    case 'CONFIRMEE':
      return StatutConsultation.confirmee;
    case 'TERMINEE':
      return StatutConsultation.terminee;
    case 'ANNULEE':
      return StatutConsultation.annulee;
    case 'REPROGRAMMEE':
      return StatutConsultation.reprogrammee;
    default:
      return StatutConsultation.enAttente;
  }
}

extension StatutConsultationLibelle on StatutConsultation {
  String get libelle => switch (this) {
        StatutConsultation.enAttente => 'En attente',
        StatutConsultation.confirmee => 'Confirmée',
        StatutConsultation.terminee => 'Terminée',
        StatutConsultation.annulee => 'Annulée',
        StatutConsultation.reprogrammee => 'Reprogrammée',
      };
}

class CreneauModel {
  final int id;
  final int consultantId;
  final String consultantNomComplet;
  final DateTime dateCreneau;
  final String heureDebut;
  final String heureFin;
  final bool disponible;

  CreneauModel({
    required this.id,
    required this.consultantId,
    required this.consultantNomComplet,
    required this.dateCreneau,
    required this.heureDebut,
    required this.heureFin,
    required this.disponible,
  });

  factory CreneauModel.fromJson(Map<String, dynamic> json) {
    return CreneauModel(
      id: json['id'] as int,
      consultantId: json['consultantId'] as int,
      consultantNomComplet: json['consultantNomComplet'] as String? ?? '',
      dateCreneau: DateTime.parse(json['dateCreneau'] as String),
      heureDebut: json['heureDebut'] as String,
      heureFin: json['heureFin'] as String,
      disponible: json['disponible'] as bool,
    );
  }
}

class ConsultationModel {
  final int id;
  final int clientId;
  final String clientNomComplet;
  final int consultantId;
  final String consultantNomComplet;
  final CreneauModel creneau;
  final StatutConsultation statut;
  final String? motif;
  final DateTime createdAt;

  ConsultationModel({
    required this.id,
    required this.clientId,
    required this.clientNomComplet,
    required this.consultantId,
    required this.consultantNomComplet,
    required this.creneau,
    required this.statut,
    this.motif,
    required this.createdAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientNomComplet: json['clientNomComplet'] as String? ?? '',
      consultantId: json['consultantId'] as int,
      consultantNomComplet: json['consultantNomComplet'] as String? ?? '',
      creneau: CreneauModel.fromJson(json['creneau'] as Map<String, dynamic>),
      statut: statutConsultationFromJson(json['statut'] as String),
      motif: json['motif'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get estAnnulable =>
      statut == StatutConsultation.enAttente ||
      statut == StatutConsultation.confirmee ||
      statut == StatutConsultation.reprogrammee;

  bool get estReprogrammable =>
      statut == StatutConsultation.enAttente || statut == StatutConsultation.confirmee;
}
