import 'package:flutter_test/flutter_test.dart';
import 'package:footix/data/models/quiz_model.dart';

void main() {
  group('QuizModel', () {
    final sampleJson = {
      'id': 'q1',
      'themeId': 't1',
      'title': 'Quiz Comptabilité',
      'description': 'Un quiz sur la comptabilité',
      'difficulty': 'FACILE',
      'timeLimit': 15,
      'passingScore': 70,
      'requiredStars': 5,
      'isFree': false,
      'isActive': true,
      'createdAt': '2024-01-01',
      'updatedAt': '2024-06-01',
      'theme': {'id': 't1', 'title': 'Comptabilité'},
      '_count': {'questions': 10},
    };

    test('fromJson parses all fields correctly', () {
      final quiz = QuizModel.fromJson(sampleJson);

      expect(quiz.id, 'q1');
      expect(quiz.themeId, 't1');
      expect(quiz.title, 'Quiz Comptabilité');
      expect(quiz.description, 'Un quiz sur la comptabilité');
      expect(quiz.difficulty, 'FACILE');
      expect(quiz.timeLimit, 15);
      expect(quiz.passingScore, 70);
      expect(quiz.requiredStars, 5);
      expect(quiz.isFree, false);
      expect(quiz.isActive, true);
    });

    test('fromJson parses nested theme', () {
      final quiz = QuizModel.fromJson(sampleJson);
      expect(quiz.theme, isNotNull);
      expect(quiz.theme!.title, 'Comptabilité');
      expect(quiz.theme!.id, 't1');
    });

    test('fromJson parses _count', () {
      final quiz = QuizModel.fromJson(sampleJson);
      expect(quiz.count, isNotNull);
      expect(quiz.count!.questions, 10);
    });

    test('fromJson handles missing optional fields', () {
      final quiz = QuizModel.fromJson({
        'id': 'q2',
        'title': 'Minimal Quiz',
        'createdAt': '2024-01-01',
        'updatedAt': '2024-01-01',
      });

      expect(quiz.themeId, '');
      expect(quiz.description, '');
      expect(quiz.difficulty, 'MOYEN');
      expect(quiz.timeLimit, 10);
      expect(quiz.passingScore, 70);
      expect(quiz.requiredStars, 0);
      expect(quiz.isFree, false);
      expect(quiz.isActive, true);
      expect(quiz.theme, isNull);
      expect(quiz.questions, isNull);
      expect(quiz.count, isNull);
      expect(quiz.userStatus, isNull);
    });

    test('fromJson parses questions list', () {
      final quiz = QuizModel.fromJson({
        ...sampleJson,
        'questions': [
          {
            'id': 'qn1',
            'quizId': 'q1',
            'content': 'Quelle est la formule ?',
            'type': 'QCU',
            'createdAt': '2024-01-01',
            'updatedAt': '2024-01-01',
            'options': [
              {'id': 'o1', 'questionId': 'qn1', 'content': 'A', 'isCorrect': true},
              {'id': 'o2', 'questionId': 'qn1', 'content': 'B', 'isCorrect': false},
            ],
          },
        ],
      });

      expect(quiz.questions, isNotNull);
      expect(quiz.questions!.length, 1);
      expect(quiz.questions![0].content, 'Quelle est la formule ?');
      expect(quiz.questions![0].options!.length, 2);
      expect(quiz.questions![0].options![0].isCorrect, true);
    });

    test('fromJson parses userStatus', () {
      final quiz = QuizModel.fromJson({
        ...sampleJson,
        'userStatus': {
          'isUnlocked': true,
          'requiredStars': 5,
          'hasPassed': false,
          'isCompleted': false,
          'remainingAttempts': 2,
          'totalAttempts': 1,
          'bestScore': 55,
          'canPurchaseAttempt': false,
          'extraAttemptCost': 10,
        },
      });

      expect(quiz.userStatus, isNotNull);
      expect(quiz.userStatus!.isUnlocked, true);
      expect(quiz.userStatus!.hasPassed, false);
      expect(quiz.userStatus!.remainingAttempts, 2);
      expect(quiz.userStatus!.bestScore, 55);
      expect(quiz.userStatus!.canPurchaseAttempt, false);
      expect(quiz.userStatus!.extraAttemptCost, 10);
    });
  });

  group('QuestionModel', () {
    test('isQCM and isQCU return correct values', () {
      final qcm = QuestionModel.fromJson({
        'id': 'q1',
        'quizId': 'quiz1',
        'content': 'Question QCM',
        'type': 'QCM',
        'createdAt': '',
        'updatedAt': '',
      });
      expect(qcm.isQCM, true);
      expect(qcm.isQCU, false);

      final qcu = QuestionModel.fromJson({
        'id': 'q2',
        'quizId': 'quiz1',
        'content': 'Question QCU',
        'type': 'QCU',
        'createdAt': '',
        'updatedAt': '',
      });
      expect(qcu.isQCM, false);
      expect(qcu.isQCU, true);
    });
  });

  group('OptionModel', () {
    test('fromJson parses correctly', () {
      final option = OptionModel.fromJson({
        'id': 'o1',
        'questionId': 'q1',
        'content': 'Option A',
        'isCorrect': true,
        'explanation': 'Because...',
      });

      expect(option.id, 'o1');
      expect(option.content, 'Option A');
      expect(option.isCorrect, true);
      expect(option.explanation, 'Because...');
    });

    test('fromJson defaults isCorrect to false', () {
      final option = OptionModel.fromJson({
        'id': 'o2',
        'questionId': 'q1',
        'content': 'Option B',
      });
      expect(option.isCorrect, false);
      expect(option.explanation, isNull);
    });
  });

  group('QuizUserStatus', () {
    test('fromJson handles defaults', () {
      final status = QuizUserStatus.fromJson({});
      expect(status.isUnlocked, true);
      expect(status.requiredStars, 0);
      expect(status.hasPassed, false);
      expect(status.isCompleted, false);
      expect(status.remainingAttempts, 3);
      expect(status.totalAttempts, 0);
      expect(status.bestScore, isNull);
      expect(status.canPurchaseAttempt, false);
      expect(status.extraAttemptCost, 10);
    });
  });
}
