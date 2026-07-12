import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

class TodoService {
  final TodoDao _dao = AppDatabase.instance.todoDao;

  Future<List<TodoModel>> fetchAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  Future<List<TodoModel>> fetchByCompleted(bool isCompleted, {int? projectId}) async {
    final rows = await _dao.findTopLevel(isCompleted, projectId: projectId);
    return rows.map(_toModel).toList();
  }

  Future<List<TodoModel>> fetchSubtasks(int parentId) async {
    final rows = await _dao.findSubtasks(parentId);
    return rows.map(_toModel).toList();
  }

  Future<int> create(TodoModel todo) async {
    return _dao.insertTodo(
      TodosCompanion(
        title: Value(todo.title),
        description: Value(todo.description),
        priority: Value(todo.priority),
        isCompleted: Value(false),
        dueDate: Value(todo.dueDate),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        projectId: Value(todo.projectId),
        parentId: Value(todo.parentId),
        recurrenceRule: Value(todo.recurrenceRule),
      ),
    );
  }

  Future<bool> update(TodoModel todo) async {
    return _dao.updateTodo(
      TodosCompanion(
        id: Value(todo.id),
        title: Value(todo.title),
        description: Value(todo.description),
        priority: Value(todo.priority),
        isCompleted: Value(todo.isCompleted),
        dueDate: Value(todo.dueDate),
        updatedAt: Value(DateTime.now()),
        projectId: Value(todo.projectId),
        parentId: Value(todo.parentId),
        recurrenceRule: Value(todo.recurrenceRule),
      ),
    );
  }

  Future<void> delete(int id) async {
    await _dao.deleteTodo(id);
  }

  Future<void> toggleComplete(int id, bool isCompleted) async {
    await _dao.toggleComplete(id, isCompleted);
  }

  TodoModel _toModel(Todo row) {
    return TodoModel(
      id: row.id,
      title: row.title,
      description: row.description,
      priority: row.priority,
      isCompleted: row.isCompleted,
      dueDate: row.dueDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      projectId: row.projectId,
      parentId: row.parentId,
      recurrenceRule: row.recurrenceRule,
    );
  }
}
