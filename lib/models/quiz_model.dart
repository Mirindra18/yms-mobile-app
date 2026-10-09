class QuizModel {
  final int id;
  final String titre;
  final String formation;
  final int questionCount;
  final int dureeMinutes;
  final List<QuizQuestionModel> questions;

  const QuizModel({
    required this.id,
    required this.titre,
    required this.formation,
    required this.questionCount,
    required this.dureeMinutes,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
    id: (json['id'] as num).toInt(),
    titre: (json['titre'] as String?) ?? '',
    formation: (json['formation'] as String?) ?? '',
    questionCount: (json['questions'] as num?)?.toInt() ?? 0,
    dureeMinutes: (json['dureeMin'] as num?)?.toInt() ?? 0,
    questions: ((json['items'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );
}

class QuizQuestionModel {
  final int id;
  final String enonce;
  final String type;
  final List<String> reponses;
  final int ordre;

  const QuizQuestionModel({
    required this.id,
    required this.enonce,
    required this.type,
    required this.reponses,
    required this.ordre,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      QuizQuestionModel(
        id: (json['id'] as num).toInt(),
        enonce: (json['enonce'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'QCM',
        reponses: ((json['reponses'] as List<dynamic>?) ?? const [])
            .whereType<String>()
            .toList(),
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      );
}

class QuizResultModel {
  final int quizId;
  final int score;
  final int total;
  final bool valide;

  const QuizResultModel({
    required this.quizId,
    required this.score,
    required this.total,
    required this.valide,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) =>
      QuizResultModel(
        quizId: (json['quizId'] as num).toInt(),
        score: (json['score'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        valide: json['valide'] as bool? ?? false,
      );
}
