import 'package:flutter/material.dart';

import '../models/task_analysis.dart';
import '../services/planning_engine.dart';
import '../services/responsibility_engine.dart';

class LifePilotUnderstandingDialog {
  static Future<bool> show(BuildContext context, TaskAnalysis analysis) async {
    final reminderPlan = PlanningEngine.generateReminderPlan(analysis);

    final score = ResponsibilityEngine.calculateScore(analysis);
    final followUp = ResponsibilityEngine.requiresFollowUp(analysis);
    final morningBrief = ResponsibilityEngine.showInMorningBrief(analysis);
    final speakAloud = ResponsibilityEngine.shouldSpeakAloud(analysis);

    final (label, color) = _responsibilityLevel(score);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.psychology_alt,
            size: 42,
            color: Colors.indigo,
          ),

          title: const Text(
            'LifePilot Understood',
            textAlign: TextAlign.center,
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('Task Type', analysis.taskType),
                _row('Category', analysis.category),
                _row('Priority', analysis.priority),

                if (analysis.person != null) _row('Person', analysis.person!),

                if (analysis.relationship != null)
                  _row('Relationship', analysis.relationship!),

                if (analysis.document != null)
                  _row('Document', analysis.document!),

                if (analysis.repeatYearly) _row('Repeat', 'Every Year'),

                const SizedBox(height: 18),

                const Text(
                  'Secretary Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '$score / 10',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _statusTile(Icons.assignment_turned_in, 'Follow-up', followUp),

                _statusTile(Icons.wb_sunny, 'Morning Briefing', morningBrief),

                _statusTile(Icons.record_voice_over, 'Speak Aloud', speakAloud),

                const SizedBox(height: 20),

                LinearProgressIndicator(
                  value: analysis.confidence,
                  borderRadius: BorderRadius.circular(20),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Understanding ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                  ),
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 12),

                const Text(
                  'Suggested Reminder Plan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 12),

                ...reminderPlan.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Edit'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  static Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static Widget _statusTile(IconData icon, String title, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: enabled ? Colors.green : Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(
            enabled ? 'YES' : 'NO',
            style: TextStyle(
              color: enabled ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static (String, Color) _responsibilityLevel(int score) {
    if (score >= 10) {
      return ('🔴 Critical Responsibility', Colors.red);
    }

    if (score >= 8) {
      return ('🟠 High Responsibility', Colors.orange);
    }

    if (score >= 6) {
      return ('🟡 Medium Responsibility', Colors.amber);
    }

    return ('🟢 Normal Responsibility', Colors.green);
  }
}
