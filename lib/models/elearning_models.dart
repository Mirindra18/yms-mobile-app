/// Modèles du module E-learning.
/// Aligné sur les DTO Java et sécurisé contre les erreurs de typage JSON.

class ElearningFormation {
  final int id;
  final String titre;
  final String description;

  const ElearningFormation({
    required this.id,
    this.titre = '',
    this.description = '',
  });

  factory ElearningFormation.fromJson(Map<String, dynamic> json) =>
      ElearningFormation(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titre: (json['titre'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
      );
}

class RessourceModel {
  final int id;
  final String titre;
  final String type;
  final String url;
  final String? description;
  final int ordre;
  final int? tailleOctets;

  const RessourceModel({
    required this.id,
    this.titre = '',
    this.type = 'OTHER',
    this.url = '',
    this.description,
    this.ordre = 0,
    this.tailleOctets,
  });

  factory RessourceModel.fromJson(Map<String, dynamic> json) => RessourceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titre: (json['titre'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'OTHER',
        url: (json['url'] as String?) ?? '',
        description: json['description'] as String?,
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
        tailleOctets: (json['tailleOctets'] as num?)?.toInt(),
      );

  String get tailleLabel {
    final b = tailleOctets;
    if (b == null || b <= 0) return '';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} Mo';
    if (b >= 1024) return '${(b / 1024).round()} Ko';
    return '$b o';
  }
}

class LeconModel {
  final int id;
  final String titre;
  final String description;
  final String contenu;
  final int ordre;
  final int? dureeMinutes;
  final int? chapitreId;
  final List<RessourceModel> ressources;

  const LeconModel({
    required this.id,
    this.titre = '',
    this.description = '',
    this.contenu = '',
    this.ordre = 0,
    this.dureeMinutes,
    this.chapitreId,
    this.ressources = const [],
  });

  factory LeconModel.fromJson(Map<String, dynamic> json) => LeconModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titre: (json['titre'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        contenu: (json['contenu'] as String?) ?? '',
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
        dureeMinutes: (json['dureeMinutes'] as num?)?.toInt(),
        chapitreId: (json['chapitreId'] as num?)?.toInt(),
        ressources: ((json['ressources'] as List<dynamic>?) ?? const [])
            .map((r) => RessourceModel.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  String get dureeLabel {
    final d = dureeMinutes;
    if (d == null || d <= 0) return '';
    if (d < 60) return '$d min';
    return '${(d / 60).toStringAsFixed(1)} h';
  }
}

class ChapitreModel {
  final int id;
  final String titre;
  final String description;
  final int ordre;
  final int? formationId;
  final List<LeconModel> lecons;

  const ChapitreModel({
    required this.id,
    this.titre = '',
    this.description = '',
    this.ordre = 0,
    this.formationId,
    this.lecons = const [],
  });

  factory ChapitreModel.fromJson(Map<String, dynamic> json) => ChapitreModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titre: (json['titre'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
        formationId: (json['formationId'] as num?)?.toInt(),
        lecons: ((json['lecons'] as List<dynamic>?) ?? const [])
            .map((l) => LeconModel.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  int get nbLecons => lecons.length;
}

class ElearningContent {
  final int id;
  final String titre;
  final String description;
  final List<ChapitreModel> chapitres;

  const ElearningContent({
    required this.id,
    this.titre = '',
    this.description = '',
    this.chapitres = const [],
  });

  factory ElearningContent.fromJson(Map<String, dynamic> json) {
    final chaps = ((json['chapitres'] as List<dynamic>?) ?? const [])
        .map((c) => ChapitreModel.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    return ElearningContent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      titre: (json['titre'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      chapitres: chaps,
    );
  }

  int get nbLecons => chapitres.fold(0, (sum, c) => sum + c.nbLecons);

  /// Liste à plat pratique pour la navigation séquentielle
  List<LeconModel> get toutesLesLecons =>
      chapitres.expand((chapitre) => chapitre.lecons).toList();
}

/// Alias pour compatibilité avec FormationContentModel
typedef FormationContentModel = ElearningContent;

class ProgressionModel {
  final int id;
  final int apprenantId;
  final int formationId;
  final int? derniereLeconId;
  final int pourcentage;
  final String statut;
  final DateTime? derniereConsultation;
  final DateTime? dateValidation;

  const ProgressionModel({
    this.id = 0,
    this.apprenantId = 0,
    this.formationId = 0,
    this.derniereLeconId,
    this.pourcentage = 0,
    this.statut = 'NOT_STARTED',
    this.derniereConsultation,
    this.dateValidation,
  });

  factory ProgressionModel.fromJson(Map<String, dynamic> json) =>
      ProgressionModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        apprenantId: (json['apprenantId'] as num?)?.toInt() ?? 0,
        formationId: (json['formationId'] as num?)?.toInt() ?? 0,
        derniereLeconId: (json['derniereLeconId'] as num?)?.toInt(),
        pourcentage: (json['pourcentage'] as num?)?.toInt() ?? 0,
        statut: (json['statut'] as String?) ?? 'NOT_STARTED',
        derniereConsultation: _tryDate(json['derniereConsultation']),
        dateValidation: _tryDate(json['dateValidation']),
      );

  bool get estTermine => statut == 'COMPLETED';
  bool get estCommence => statut == 'IN_PROGRESS' || estTermine;

  static DateTime? _tryDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}