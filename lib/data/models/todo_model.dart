import 'package:nestflow/nestflow.dart';

class TodoModel {
  final int id;
  final String title;
  final String? description;
  final TodoPriority priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? projectId;
  final int? parentId;
  final String? recurrenceRule;
  final List<LabelModel> labels;

  const TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.isCompleted,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.parentId,
    this.recurrenceRule,
    this.labels = const [],
  });

  bool get isSubtask => parentId != null;
  bool get isRecurring => recurrenceRule != null;

  TodoModel copyWith({
    int? id,
    String? title,
    String? description,
    TodoPriority? priority,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? projectId,
    bool clearProjectId = false,
    int? parentId,
    bool clearParentId = false,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
    List<LabelModel>? labels,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectId: clearProjectId ? null : projectId ?? this.projectId,
      parentId: clearParentId ? null : parentId ?? this.parentId,
      recurrenceRule:
          clearRecurrenceRule ? null : recurrenceRule ?? this.recurrenceRule,
      labels: labels ?? this.labels,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isUpcoming {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return dueDate!.isAfter(endOfToday);
  }
}
