class TaskAnalysis {
  final String originalText;

  final String taskType;

  final String category;

  final String priority;

  final String? person;

  final String? relationship;

  final String? document;

  final DateTime? eventDate;

  final bool repeatYearly;

  final double confidence;

  final bool needsConfirmation;

  const TaskAnalysis({
    required this.originalText,
    required this.taskType,
    required this.category,
    required this.priority,
    this.person,
    this.relationship,
    this.document,
    this.eventDate,
    this.repeatYearly = false,
    this.confidence = 1.0,
    this.needsConfirmation = true,
  });
}
