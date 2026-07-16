import '../models/task_analysis.dart';
import 'brain_engine.dart';
import 'planning_engine.dart';
import 'responsibility_engine.dart';

class SecretaryResult {
  final TaskAnalysis analysis;
  final List<String> reminderPlan;
  final int responsibilityScore;
  final bool requiresFollowUp;
  final bool showInMorningBrief;
  final bool shouldSpeakAloud;

  const SecretaryResult({
    required this.analysis,
    required this.reminderPlan,
    required this.responsibilityScore,
    required this.requiresFollowUp,
    required this.showInMorningBrief,
    required this.shouldSpeakAloud,
  });
}

class SecretaryEngine {
  static SecretaryResult process(String input) {
    final analysis = BrainEngine.analyze(input);

    final plan = PlanningEngine.generateReminderPlan(analysis);

    final score = ResponsibilityEngine.calculateScore(analysis);

    return SecretaryResult(
      analysis: analysis,
      reminderPlan: plan,
      responsibilityScore: score,
      requiresFollowUp: ResponsibilityEngine.requiresFollowUp(analysis),
      showInMorningBrief: ResponsibilityEngine.showInMorningBrief(analysis),
      shouldSpeakAloud: ResponsibilityEngine.shouldSpeakAloud(analysis),
    );
  }
}
