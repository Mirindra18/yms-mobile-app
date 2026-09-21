class FormationModel {
  final int id;
  final String titre;
  final String categorie;
  final String description;
  final int dureeHeures;
  final double tarif;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final int capaciteMax;
  final int placesRestantes;
  final String statut;
  final String? formateurEmail;

  FormationModel({
    required this.id,
    required this.titre,
    this.categorie = '',
    this.description = '',
    this.dureeHeures = 0,
    this.tarif = 0,
    this.dateDebut,
    this.dateFin,
    this.capaciteMax = 0,
    this.placesRestantes = 0,
    this.statut = '',
    this.formateurEmail,
  });

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    return FormationModel(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String,
      categorie: json['categorie'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dureeHeures: (json['dureeHeures'] as num?)?.toInt() ?? 0,
      tarif: (json['tarif'] as num?)?.toDouble() ?? 0,
      dateDebut: _tryParseDate(json['dateDebut']),
      dateFin: _tryParseDate(json['dateFin']),
      capaciteMax: (json['capaciteMax'] as num?)?.toInt() ?? 0,
      placesRestantes: (json['placesRestantes'] as num?)?.toInt() ?? 0,
      statut: json['statut'] as String? ?? '',
      formateurEmail: json['formateurEmail'] as String?,
    );
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // Compatibilité avec l'ancien écran de détail.
  DateTime? get dateLimiteInscription => dateFin;
  int? get placesDisponibles => placesRestantes;

  bool get isDateLimiteDepassee =>
      dateFin != null && dateFin!.isBefore(DateTime.now());

  bool get estAnnulee => statut == 'ANNULEE';
  bool get estTerminee => statut == 'TERMINEE';
  bool get estOuverte => !estAnnulee && !estTerminee;
}