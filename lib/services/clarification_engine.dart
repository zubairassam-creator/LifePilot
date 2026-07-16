import '../models/task_analysis.dart';

class ClarificationResult {
  final bool needsClarification;
  final List<String> questions;

  const ClarificationResult({
    required this.needsClarification,
    required this.questions,
  });
}

class ClarificationEngine {
  static ClarificationResult analyze(TaskAnalysis task) {
    final questions = <String>[];

    switch (task.taskType) {
      case 'Birthday':
        if (task.person == null) {
          questions.add('Whose birthday is it?');
        }

        if (task.eventDate == null) {
          questions.add('Which date is the birthday?');
        }

        if (!RegExp(
          r'january|february|march|april|may|june|july|august|september|october|november|december',
          caseSensitive: false,
        ).hasMatch(task.originalText)) {
          questions.add('Which month is the birthday?');
        }

        break;

      case 'Appointment':
        questions.add('What time is the appointment?');
        break;

      case 'Meeting':
        questions.add('What time is the meeting?');
        break;

      case 'Expiry':
        questions.add(
          'I will remind you at 9:00 AM by default. Do you want another time?',
        );
        break;
    }

    return ClarificationResult(
      needsClarification: questions.isNotEmpty,
      questions: questions,
    );
  }
}
