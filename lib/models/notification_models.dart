/// Modèles du module Notifications.
/// Correspondent exactement aux DTO exposés par notification-service
/// (NotificationController) : NotificationResponse, TypeNotification.

enum TypeNotification {
  formation,
  inscription,
  rendezVous,
  modification,
  annulation,
  rappel,
  informationGenerale,
}

TypeNotification typeNotificationFromJson(String value) {
  switch (value) {
    case 'FORMATION':
      return TypeNotification.formation;
    case 'INSCRIPTION':
      return TypeNotification.inscription;
    case 'RENDEZ_VOUS':
      return TypeNotification.rendezVous;
    case 'MODIFICATION':
      return TypeNotification.modification;
    case 'ANNULATION':
      return TypeNotification.annulation;
    case 'RAPPEL':
      return TypeNotification.rappel;
    default:
      return TypeNotification.informationGenerale;
  }
}

class NotificationModel {
  final int destinataireEntryId;
  final int notificationId;
  final String titre;
  final String contenu;
  final TypeNotification type;
  final int? referenceId;
  final bool lue;
  final DateTime? dateLecture;
  final DateTime createdAt;

  NotificationModel({
    required this.destinataireEntryId,
    required this.notificationId,
    required this.titre,
    required this.contenu,
    required this.type,
    this.referenceId,
    required this.lue,
    this.dateLecture,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      destinataireEntryId: json['destinataireEntryId'] as int,
      notificationId: json['notificationId'] as int,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      type: typeNotificationFromJson(json['type'] as String),
      referenceId: json['referenceId'] as int?,
      lue: json['lue'] as bool? ?? false,
      dateLecture: json['dateLecture'] != null ? DateTime.parse(json['dateLecture'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  NotificationModel copyWith({bool? lue}) {
    return NotificationModel(
      destinataireEntryId: destinataireEntryId,
      notificationId: notificationId,
      titre: titre,
      contenu: contenu,
      type: type,
      referenceId: referenceId,
      lue: lue ?? this.lue,
      dateLecture: dateLecture,
      createdAt: createdAt,
    );
  }
}
