class FormationModel {
  final int id;
  final String titre;
  final String description;
  final DateTime? dateLimiteInscription;
  final int? placesDisponibles;

  FormationModel({
    required this.id,
    required this.titre,
    required this.description,
    this.dateLimiteInscription,
    this.placesDisponibles,
  });

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    return FormationModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      dateLimiteInscription: json['dateLimiteInscription'] != null
          ? DateTime.tryParse(json['dateLimiteInscription'] as String)
          : null,
      placesDisponibles: json['placesDisponibles'] as int?,
    );
  }

  bool get isDateLimiteDepassee =>
      dateLimiteInscription != null &&
      dateLimiteInscription!.isBefore(DateTime.now());
}
