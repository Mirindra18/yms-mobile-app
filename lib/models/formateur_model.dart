class Seance {
  final int id;
  final String date; // yyyy-MM-dd
  final String heureDebut;
  final String heureFin;
  final String formationTitre;
  final String formateurEmail;

  Seance({
    required this.id,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.formationTitre,
    required this.formateurEmail,
  });

  factory Seance.fromJson(Map<String, dynamic> j) => Seance(
        id: (j['id'] as num).toInt(),
        date: j['date']?.toString() ?? '',
        heureDebut: j['heureDebut']?.toString() ?? '00:00',
        heureFin: j['heureFin']?.toString() ?? '00:00',
        formationTitre: j['formationTitre']?.toString() ?? '',
        formateurEmail: j['formateurEmail']?.toString() ?? '',
      );

  DateTime get day => DateTime.parse('${date}T00:00:00');
  String get debut => heureDebut.length >= 5 ? heureDebut.substring(0, 5) : heureDebut;
  String get fin => heureFin.length >= 5 ? heureFin.substring(0, 5) : heureFin;
}

class Formation {
  final int id;
  final String titre;
  final String categorie;
  final int dureeHeures;
  final String dateDebut;
  final String dateFin;
  final String statut;
  final int capaciteMax;
  final int? placesRestantes;
  final int? nbInscrits;
  final String formateurEmail;

  Formation({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.dureeHeures,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    required this.capaciteMax,
    this.placesRestantes,
    this.nbInscrits,
    required this.formateurEmail,
  });

  factory Formation.fromJson(Map<String, dynamic> j) => Formation(
        id: (j['id'] as num).toInt(),
        titre: j['titre']?.toString() ?? '',
        categorie: j['categorie']?.toString() ?? '',
        dureeHeures: (j['dureeHeures'] as num?)?.toInt() ?? 0,
        dateDebut: j['dateDebut']?.toString() ?? '',
        dateFin: j['dateFin']?.toString() ?? '',
        statut: j['statut']?.toString() ?? '',
        capaciteMax: (j['capaciteMax'] as num?)?.toInt() ?? 0,
        placesRestantes: (j['placesRestantes'] as num?)?.toInt(),
        nbInscrits: (j['nbInscrits'] as num?)?.toInt(),
        formateurEmail: j['formateurEmail']?.toString() ?? '',
      );

  int get occupees =>
      nbInscrits ??
      (capaciteMax - (placesRestantes ?? capaciteMax)).clamp(0, capaciteMax).toInt();
  int get progression => capaciteMax > 0
      ? ((occupees / capaciteMax) * 100).round().clamp(0, 100).toInt()
      : 0;
}

class Inscription {
  final int id;
  final int formationId;
  final int userId;
  final String userNom;
  final String userPrenom;
  final String userEmail;
  final String formationTitre;
  final String dateInscription;
  final String statut;

  Inscription({
    required this.id,
    required this.formationId,
    required this.userId,
    required this.userNom,
    required this.userPrenom,
    required this.userEmail,
    required this.formationTitre,
    required this.dateInscription,
    required this.statut,
  });

  factory Inscription.fromJson(Map<String, dynamic> j) => Inscription(
        id: (j['id'] as num).toInt(),
        formationId: (j['formationId'] as num?)?.toInt() ?? 0,
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        userNom: j['userNom']?.toString() ?? '',
        userPrenom: j['userPrenom']?.toString() ?? '',
        userEmail: j['userEmail']?.toString() ?? '',
        formationTitre: j['formationTitre']?.toString() ?? '',
        dateInscription: j['dateInscription']?.toString() ?? '',
        statut: j['statut']?.toString() ?? '',
      );

  String get initiales {
    final a = userPrenom.isNotEmpty ? userPrenom[0] : '';
    final b = userNom.isNotEmpty ? userNom[0] : '';
    return '$a$b'.toUpperCase();
  }

  bool get validee {
    final s = statut.toUpperCase();
    return s == 'VALIDEE' || s == 'VALIDÉE';
  }

  bool get annulee {
    final s = statut.toUpperCase();
    return s == 'ANNULEE' || s == 'ANNULÉE';
  }

  String get statutLabel {
    if (validee) return 'Validée';
    if (annulee) return 'Annulée';
    if (statut.toUpperCase() == 'EN_ATTENTE') return 'En attente';
    return statut.isEmpty ? 'Inconnu' : statut;
  }
}

class PresenceSession {
  final int id;
  final int formationId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String status;
  final String? qrToken;
  final DateTime? qrExpireAt;

  const PresenceSession({
    required this.id,
    required this.formationId,
    required this.title,
    required this.start,
    required this.end,
    required this.status,
    this.qrToken,
    this.qrExpireAt,
  });

  factory PresenceSession.fromJson(Map<String, dynamic> json) =>
      PresenceSession(
        id: (json['id'] as num).toInt(),
        formationId: (json['formationId'] as num?)?.toInt() ?? 0,
        title: json['titre']?.toString() ?? '',
        start: DateTime.parse(json['debut'].toString()),
        end: DateTime.parse(json['fin'].toString()),
        status: json['statut']?.toString() ?? 'OPEN',
        qrToken: json['qrToken']?.toString(),
        qrExpireAt: json['qrExpireAt'] == null
            ? null
            : DateTime.parse(json['qrExpireAt'].toString()),
      );

  bool get isOpen => status.toUpperCase() == 'OPEN';
}

class PresenceRecord {
  final int id;
  final int participantId;
  final int sessionId;
  final String status;
  final String mode;
  final DateTime date;

  const PresenceRecord({
    required this.id,
    required this.participantId,
    required this.sessionId,
    required this.status,
    required this.mode,
    required this.date,
  });

  factory PresenceRecord.fromJson(Map<String, dynamic> json) =>
      PresenceRecord(
        id: (json['id'] as num).toInt(),
        participantId: (json['participantId'] as num).toInt(),
        sessionId: (json['seanceId'] as num).toInt(),
        status: json['statut']?.toString() ?? 'ABSENT',
        mode: json['mode']?.toString() ?? 'MANUAL',
        date: DateTime.parse(json['datePresence'].toString()),
      );
}

class PresenceStats {
  final int total;
  final int presents;
  final int absents;
  final double rate;

  const PresenceStats({
    required this.total,
    required this.presents,
    required this.absents,
    required this.rate,
  });

  factory PresenceStats.fromJson(Map<String, dynamic> json) => PresenceStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        presents: (json['presents'] as num?)?.toInt() ?? 0,
        absents: (json['absents'] as num?)?.toInt() ?? 0,
        rate: (json['tauxPresence'] as num?)?.toDouble() ?? 0,
      );
}
