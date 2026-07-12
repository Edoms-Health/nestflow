import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

// ── States ────────────────────────────────────────────────────
abstract class TodoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<TodoModel> todos;
  final List<TodoModel> completedTodos;

  TodoLoaded({required this.todos, required this.completedTodos});

  @override
  List<Object?> get props => [todos, completedTodos];
}

class TodoFormInitial extends TodoState {
  final TodoPriority priority;
  final DateTime? dueDate;
  final bool processing;
  final Map<String, String> errors;
  final ProjectModel? project;
  final List<LabelModel> labels;
  final String? recurrenceRule;

  TodoFormInitial({
    this.priority = TodoPriority.medium,
    this.dueDate,
    this.processing = false,
    this.errors = const {},
    this.project,
    this.labels = const [],
    this.recurrenceRule,
  });

  TodoFormInitial copyWith({
    TodoPriority? priority,
    DateTime? dueDate,
    bool? processing,
    Map<String, String>? errors,
    bool clearDueDate = false,
    ProjectModel? project,
    bool clearProject = false,
    List<LabelModel>? labels,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
  }) {
    return TodoFormInitial(
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      processing: processing ?? this.processing,
      errors: errors ?? this.errors,
      project: clearProject ? null : project ?? this.project,
      labels: labels ?? this.labels,
      recurrenceRule: clearRecurrenceRule
          ? null
          : recurrenceRule ?? this.recurrenceRule,
    );
  }

  @override
  List<Object?> get props =>
      [priority, dueDate, processing, errors, project, labels, recurrenceRule];
}

class TodoError extends TodoState {
  final String message;
  TodoError(this.message);

  @override
  List<Object?> get props => [message];
}

class TodoSuccess extends TodoState {
  final String message;
  TodoSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class TodoCubit extends Cubit<TodoState> {
  final TodoService _service = TodoService();
  final ProjectDao _projectDao = AppDatabase.instance.projectDao;
  final LabelDao _labelDao = AppDatabase.instance.labelDao;

  TodoCubit() : super(TodoLoading());

  Future<void> loadTodos({int? projectId}) async {
    try {
      final pending =
          await _service.fetchByCompleted(false, projectId: projectId);
      final completed =
          await _service.fetchByCompleted(true, projectId: projectId);
      emit(TodoLoaded(todos: pending, completedTodos: completed));
    } catch (e) {
      emit(TodoError('Failed to load tasks'));
    }
  }

  Future<void> formInit({TodoModel? todo, ProjectModel? defaultProject}) async {
    ProjectModel? project = defaultProject;
    if (todo?.projectId != null) {
      final row = await _projectDao.findById(todo!.projectId!);
      if (row != null) {
        project = ProjectModel(
          id: row.id,
          name: row.name,
          color: row.color,
          sortOrder: row.sortOrder,
          createdAt: row.createdAt,
        );
      }
    }
    List<LabelModel> labels = const [];
    if (todo != null) {
      final rows = await _labelDao.findForTodo(todo.id);
      labels = rows
          .map((r) => LabelModel(id: r.id, name: r.name, color: r.color))
          .toList();
    }
    emit(TodoFormInitial(
      priority: todo?.priority ?? TodoPriority.medium,
      dueDate: todo?.dueDate,
      project: project,
      labels: labels,
      recurrenceRule: todo?.recurrenceRule,
    ));
  }

  void setData({
    TodoPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    ProjectModel? project,
    bool clearProject = false,
    List<LabelModel>? labels,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
  }) {
    if (state is TodoFormInitial) {
      emit((state as TodoFormInitial).copyWith(
        priority: priority,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        project: project,
        clearProject: clearProject,
        labels: labels,
        recurrenceRule: recurrenceRule,
        clearRecurrenceRule: clearRecurrenceRule,
      ));
    }
  }

  Future<bool> submit({
    required TodoModel? existing,
    required String title,
    required String? description,
  }) async {
    final form = state as TodoFormInitial;

    Map<String, String> errors = {};
    if (title.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (title.length > 100) {
      errors['title'] = 'Title must be under 100 characters';
    }

    if (errors.isNotEmpty) {
      emit(form.copyWith(errors: errors));
      return false;
    }

    emit(form.copyWith(processing: true));

    try {
      final now = DateTime.now();
      final todo = TodoModel(
        id: existing?.id ?? 0,
        title: title.trim(),
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        priority: form.priority,
        isCompleted: existing?.isCompleted ?? false,
        dueDate: form.dueDate,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        projectId: form.project?.id,
        // parentId/recurrenceRule aren't editable in this form yet — always
        // preserve whatever the existing todo had rather than dropping it.
        parentId: existing?.parentId,
        recurrenceRule: form.recurrenceRule,
      );

      if (existing == null) {
        final id = await _service.create(todo);
        await NotificationService().scheduleTodoReminders(
          TodoModel(
            id: id, title: todo.title, description: todo.description,
            priority: todo.priority, isCompleted: todo.isCompleted,
            dueDate: todo.dueDate, createdAt: todo.createdAt, updatedAt: todo.updatedAt,
          ),
        );
      } else {
        await _service.update(todo);
        await NotificationService().scheduleTodoReminders(todo);
      }

      await loadTodos();
      emit(TodoSuccess(existing == null ? 'Task created!' : 'Task updated!'));
      return true;
    } catch (e) {
      emit(TodoError('Failed to save task'));
      return false;
    }
  }

  Future<void> toggleComplete(TodoModel todo) async {
    try {
      final nowCompleted = !todo.isCompleted;

      if (nowCompleted && todo.isRecurring && todo.dueDate != null) {
        final nextDueDate =
            _nextOccurrence(todo.dueDate!, todo.recurrenceRule!);
        final rescheduled = todo.copyWith(
          isCompleted: false,
          dueDate: nextDueDate,
        );
        await _service.update(rescheduled);
        await NotificationService().scheduleTodoReminders(rescheduled);
        await loadTodos();
        emit(TodoSuccess(
          'Task completed! Rescheduled to '
          '${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}',
        ));
        return;
      }

      await _service.toggleComplete(todo.id, nowCompleted);
      if (nowCompleted) {
        await NotificationService().cancelTodoReminders(todo.id);
      } else {
        await NotificationService().scheduleTodoReminders(
          todo.copyWith(),
        );
      }
      await loadTodos();
      emit(TodoSuccess(
        todo.isCompleted ? 'Task marked as pending' : 'Task completed!',
      ));
    } catch (e) {
      emit(TodoError('Failed to update task'));
    }
  }

  /// Fetches sub-tasks for a given parent. Deliberately does not touch
  /// TodoLoaded state — subtasks are loaded and cached locally inside
  /// TodoTile, since the main list only ever shows top-level todos.
  Future<List<TodoModel>> fetchSubtasks(int parentId) {
    return _service.fetchSubtasks(parentId);
  }

  /// Quick-add a sub-task with just a title (Todoist-style inline add).
  /// Doesn't emit TodoSuccess/TodoError since it's a lightweight action
  /// driven from inside TodoTile rather than the full form flow.
  Future<bool> createSubtask({
    required int parentId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    try {
      final now = DateTime.now();
      final subtask = TodoModel(
        id: 0,
        title: trimmed,
        priority: TodoPriority.medium,
        isCompleted: false,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );
      await _service.create(subtask);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> delete(TodoModel todo) async {
    try {
      await _service.delete(todo.id);
      await NotificationService().cancelTodoReminders(todo.id);
      await loadTodos();
      emit(TodoSuccess('Task deleted'));
    } catch (e) {
      emit(TodoError('Failed to delete task'));
    }
  }
}

DateTime _nextOccurrence(DateTime from, String rule) {
  switch (rule) {
    case 'DAILY':
      return from.add(const Duration(days: 1));
    case 'WEEKLY':
      return from.add(const Duration(days: 7));
    case 'MONTHLY':
      return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
    case 'YEARLY':
      return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    default:
      return from.add(const Duration(days: 1));
  }
}
