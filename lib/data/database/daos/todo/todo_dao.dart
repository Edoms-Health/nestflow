import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

part 'todo_dao.g.dart';

@DriftAccessor(tables: [Todos])
class TodoDao extends DatabaseAccessor<AppDatabase> with _$TodoDaoMixin {
  TodoDao(super.db);

  Future<List<Todo>> findAll() => select(todos).get();

  Future<List<Todo>> findByCompleted(bool isCompleted) {
    return (select(todos)
          ..where((t) => t.isCompleted.equals(isCompleted))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Only top-level todos (no parent) — used for the main list so
  /// subtasks don't double-render alongside their parent.
  /// [projectId] filters to a single project; pass null for "all projects".
  Future<List<Todo>> findTopLevel(bool isCompleted, {int? projectId}) {
    final query = select(todos)
      ..where((t) => t.isCompleted.equals(isCompleted) & t.parentId.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    return query.get();
  }

  Future<List<Todo>> findSubtasks(int parentId) {
    return (select(todos)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> insertTodo(TodosCompanion todo) => into(todos).insert(todo);

  Future<bool> updateTodo(TodosCompanion todo) => update(todos).replace(todo);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<int> toggleComplete(int id, bool isCompleted) {
    return (update(todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
