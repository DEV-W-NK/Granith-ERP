import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum GranithTaskStatus { pending, inProgress, paused, completed, cancelled }

extension GranithTaskStatusUi on GranithTaskStatus {
  String get label => switch (this) {
    GranithTaskStatus.pending => 'Pendente',
    GranithTaskStatus.inProgress => 'Em andamento',
    GranithTaskStatus.paused => 'Pausada',
    GranithTaskStatus.completed => 'Concluida',
    GranithTaskStatus.cancelled => 'Cancelada',
  };

  IconData get icon => switch (this) {
    GranithTaskStatus.pending => Icons.schedule_rounded,
    GranithTaskStatus.inProgress => Icons.timer_rounded,
    GranithTaskStatus.paused => Icons.pause_circle_outline_rounded,
    GranithTaskStatus.completed => Icons.task_alt_rounded,
    GranithTaskStatus.cancelled => Icons.cancel_outlined,
  };
}

enum GranithTaskPriority { low, medium, high, urgent }

extension GranithTaskPriorityUi on GranithTaskPriority {
  String get label => switch (this) {
    GranithTaskPriority.low => 'Baixa',
    GranithTaskPriority.medium => 'Media',
    GranithTaskPriority.high => 'Alta',
    GranithTaskPriority.urgent => 'Urgente',
  };

  Color get color => switch (this) {
    GranithTaskPriority.low => const Color(0xFF67D6FF),
    GranithTaskPriority.medium => const Color(0xFFE3B84A),
    GranithTaskPriority.high => const Color(0xFFFFA657),
    GranithTaskPriority.urgent => const Color(0xFFFF6B6B),
  };
}

enum GranithTaskSource { general, project, budget }

extension GranithTaskSourceUi on GranithTaskSource {
  String get label => switch (this) {
    GranithTaskSource.general => 'Geral',
    GranithTaskSource.project => 'Obra',
    GranithTaskSource.budget => 'Orcamento',
  };
}

class GranithTask {
  const GranithTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.supervisorId,
    required this.supervisorName,
    required this.assigneeId,
    required this.assigneeName,
    required this.source,
    required this.projectId,
    required this.projectName,
    required this.budgetId,
    required this.budgetName,
    required this.dueAt,
    required this.estimatedMinutes,
    required this.startedAt,
    required this.activeTimerStartedAt,
    required this.accumulatedSeconds,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String title;
  final String description;
  final GranithTaskStatus status;
  final GranithTaskPriority priority;
  final String supervisorId;
  final String supervisorName;
  final String assigneeId;
  final String assigneeName;
  final GranithTaskSource source;
  final String? projectId;
  final String projectName;
  final String? budgetId;
  final String budgetName;
  final DateTime? dueAt;
  final int estimatedMinutes;
  final DateTime? startedAt;
  final DateTime? activeTimerStartedAt;
  final int accumulatedSeconds;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isTimerRunning => activeTimerStartedAt != null;
  bool get isClosed =>
      status == GranithTaskStatus.completed ||
      status == GranithTaskStatus.cancelled;

  String get sourceName => switch (source) {
    GranithTaskSource.project =>
      projectName.trim().isEmpty ? 'Obra' : projectName,
    GranithTaskSource.budget =>
      budgetName.trim().isEmpty ? 'Orcamento' : budgetName,
    GranithTaskSource.general => 'Atividade geral',
  };

  int elapsedSecondsAt(DateTime now) {
    final activeStart = activeTimerStartedAt;
    if (activeStart == null) return accumulatedSeconds;
    return accumulatedSeconds +
        now.toUtc().difference(activeStart.toUtc()).inSeconds.clamp(0, 1 << 31);
  }

  factory GranithTask.fromMap(Map<String, dynamic> map) {
    T enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      final text = raw?.toString();
      for (final value in values) {
        if (value.name == text) return value;
      }
      return fallback;
    }

    return GranithTask(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      status: enumValue(
        GranithTaskStatus.values,
        map['status'],
        GranithTaskStatus.pending,
      ),
      priority: enumValue(
        GranithTaskPriority.values,
        map['priority'],
        GranithTaskPriority.medium,
      ),
      supervisorId: (map['supervisorId'] ?? '').toString(),
      supervisorName: (map['supervisorName'] ?? '').toString(),
      assigneeId: (map['assigneeId'] ?? '').toString(),
      assigneeName: (map['assigneeName'] ?? '').toString(),
      source: enumValue(
        GranithTaskSource.values,
        map['sourceType'],
        GranithTaskSource.general,
      ),
      projectId: map['projectId']?.toString(),
      projectName: (map['projectName'] ?? '').toString(),
      budgetId: map['budgetId']?.toString(),
      budgetName: (map['budgetName'] ?? '').toString(),
      dueAt: DbValue.toDateTime(map['dueAt']),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 0,
      startedAt: DbValue.toDateTime(map['startedAt']),
      activeTimerStartedAt: DbValue.toDateTime(map['activeTimerStartedAt']),
      accumulatedSeconds: (map['accumulatedSeconds'] as num?)?.toInt() ?? 0,
      completedAt: DbValue.toDateTime(map['completedAt']),
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }
}
