import 'package:flutter_test/flutter_test.dart';
import 'package:yms_mobile_app/models/quiz_model.dart';

void main() {
  test('maps quiz and safe question fields from the public API', () {
    final quiz = QuizModel.fromJson({
      'id': 8,
      'titre': 'Évaluation comptable',
      'formation': 'Comptable Senior',
      'questions': 1,
      'dureeMin': 12,
      'items': [
        {
          'id': 43,
          'enonce': 'Quel est le rôle du bilan ?',
          'type': 'QCM',
          'reponses': ['Option A', 'Option B'],
          'ordre': 1,
        },
      ],
    });

    expect(quiz.id, 8);
    expect(quiz.formation, 'Comptable Senior');
    expect(quiz.questionCount, 1);
    expect(quiz.questions.single.id, 43);
    expect(quiz.questions.single.reponses, ['Option A', 'Option B']);
  });

  test('maps submitted quiz result', () {
    final result = QuizResultModel.fromJson({
      'quizId': 8,
      'score': 75,
      'total': 4,
      'valide': true,
    });

    expect(result.quizId, 8);
    expect(result.score, 75);
    expect(result.total, 4);
    expect(result.valide, isTrue);
  });
}
