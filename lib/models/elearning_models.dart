/// Modèles du module E-learning.
/// Correspondent exactement aux DTO exposés par ElearningController
/// (mg.yms.elearning côté backend) : FormationContentResponse,
/// ChapitreResponse, LeconResponse, RessourceResponse.

enum ResourceType { pdf, video, document, link, other }

ResourceType resourceTypeFromJson(String value) {
  switch (value) {
    case 'PDF':
      return ResourceType.pdf;
    case 'VIDEO':
      return ResourceType.video;
    case 'DOCUMENT':
      return ResourceType.document;
    case 'LINK':
      return ResourceType.link;
    default:
      return ResourceType.other;
  }
}

class RessourceModel {
  final int id;
  final String titre;
  final ResourceType type;
  final String? url;
  final String? description;
  final int? ordre;
  final int? tailleOctets;

  RessourceModel({
    required this.id,
    required this.titre,
    required this.type,
    this.url,
    this.description,
    this.ordre,
    this.tailleOctets,
  });

  factory RessourceModel.fromJson(Map<String, dynamic> json) {
    return RessourceModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      type: resourceTypeFromJson(json['type'] as String),
      url: json['url'] as String?,
      description: json['description'] as String?,
      ordre: json['ordre'] as int?,
      tailleOctets: json['tailleOctets'] as int?,
    );
  }
}

class LeconModel {
  final int id;
  final String titre;
  final String? description;
  final String? contenu;
  final int? ordre;
  final int? dureeMinutes;
  final int chapitreId;
  final List<RessourceModel> ressources;

  LeconModel({
    required this.id,
    required this.titre,
    this.description,
    this.contenu,
    this.ordre,
    this.dureeMinutes,
    required this.chapitreId,
    required this.ressources,
  });

  factory LeconModel.fromJson(Map<String, dynamic> json) {
    return LeconModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      contenu: json['contenu'] as String?,
      ordre: json['ordre'] as int?,
      dureeMinutes: json['dureeMinutes'] as int?,
      chapitreId: json['chapitreId'] as int,
      ressources: (json['ressources'] as List<dynamic>? ?? [])
          .map((e) => RessourceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChapitreModel {
  final int id;
  final String titre;
  final String? description;
  final int? ordre;
  final int formationId;
  final List<LeconModel> lecons;

  ChapitreModel({
    required this.id,
    required this.titre,
    this.description,
    this.ordre,
    required this.formationId,
    required this.lecons,
  });

  factory ChapitreModel.fromJson(Map<String, dynamic> json) {
    return ChapitreModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      ordre: json['ordre'] as int?,
      formationId: json['formationId'] as int,
      lecons: (json['lecons'] as List<dynamic>? ?? [])
          .map((e) => LeconModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Correspond à FormationResponse (liste des formations).
class FormationModel {
  final int id;
  final String titre;
  final String? description;

  FormationModel({required this.id, required this.titre, this.description});

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    return FormationModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
    );
  }
}

/// Correspond à FormationContentResponse (GET /formations/{id}/parcours) :
/// la formation avec l'intégralité de son arborescence chapitres/leçons/ressources.
class FormationContentModel {
  final int id;
  final String titre;
  final String? description;
  final List<ChapitreModel> chapitres;

  FormationContentModel({
    required this.id,
    required this.titre,
    this.description,
    required this.chapitres,
  });

  factory FormationContentModel.fromJson(Map<String, dynamic> json) {
    return FormationContentModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      chapitres: (json['chapitres'] as List<dynamic>? ?? [])
          .map((e) => ChapitreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Liste des leçons à plat, dans l'ordre des chapitres puis de leur
  /// propre ordre, pratique pour la navigation séquentielle du lecteur.
  List<LeconModel> get toutesLesLecons =>
      chapitres.expand((chapitre) => chapitre.lecons).toList();
}

enum ProgressStatus { notStarted, inProgress, completed }

ProgressStatus progressStatusFromJson(String value) {
  switch (value) {
    case 'IN_PROGRESS':
      return ProgressStatus.inProgress;
    case 'COMPLETED':
      return ProgressStatus.completed;
    default:
      return ProgressStatus.notStarted;
  }
}

/// Correspond à ProgressionResponse.
class ProgressionModel {
  final int id;
  final int apprenantId;
  final int formationId;
  final int? derniereLeconId;
  final int pourcentage;
  final ProgressStatus statut;

  ProgressionModel({
    required this.id,
    required this.apprenantId,
    required this.formationId,
    this.derniereLeconId,
    required this.pourcentage,
    required this.statut,
  });

  factory ProgressionModel.fromJson(Map<String, dynamic> json) {
    return ProgressionModel(
      id: json['id'] as int,
      apprenantId: json['apprenantId'] as int,
      formationId: json['formationId'] as int,
      derniereLeconId: json['derniereLeconId'] as int?,
      pourcentage: json['pourcentage'] as int? ?? 0,
      statut: progressStatusFromJson(json['statut'] as String? ?? 'NOT_STARTED'),
    );
  }
}
