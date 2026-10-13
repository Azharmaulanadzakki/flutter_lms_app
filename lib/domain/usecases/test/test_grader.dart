import '../../../core/errors/failures.dart';
import '../../entities/question.dart';
import '../../entities/test_result.dart';

class GradeOutcome {
  const GradeOutcome({
    required this.score,
    required this.correct,
    required this.wrong,
    required this.items,
  });

  final double score;
  final int correct;
  final int wrong;
  final List<GradedQuestion> items;
}

/// Menghitung nilai (0 sampai 100) berdasarkan poin tiap soal.
/// Dart murni, mudah diuji.
class TestGrader {
  const TestGrader();

  GradeOutcome grade({
    required List<Question> questions,
    required Map<String, int> answers,
    required Map<String, QuestionKey> keys,
  }) {
    var totalPoints = 0;
    var earnedPoints = 0;
    var correct = 0;
    final items = <GradedQuestion>[];

    for (final q in questions) {
      final key = keys[q.id];
      if (key == null) {
        throw const Failure('Kunci jawaban belum lengkap. Hubungi admin.');
      }

      final selected = answers[q.id];
      final isCorrect = selected != null && selected == key.correctIndex;

      totalPoints += q.points;
      if (isCorrect) {
        earnedPoints += q.points;
        correct++;
      }

      items.add(GradedQuestion(
        question: q,
        selectedIndex: selected,
        correctIndex: key.correctIndex,
        explanation: key.explanation,
      ));
    }

    final raw = totalPoints == 0 ? 0.0 : earnedPoints / totalPoints * 100;

    return GradeOutcome(
      score: (raw * 10).round() / 10,
      correct: correct,
      wrong: questions.length - correct,
      items: items,
    );
  }
}