import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

part 'label_dao.g.dart';

@DriftAccessor(tables: [Labels, TodoLabels])
class LabelDao extends DatabaseAccessor<AppDatabase> with _$LabelDaoMixin {
  LabelDao(super.db);

  Future<List<Label>> findAll() => select(labels).get();

  Future<int> insertLabel(LabelsCompanion label) =>
      into(labels).insert(label);

  Future<bool> updateLabel(LabelsCompanion label) =>
      update(labels).replace(label);

  Future<int> deleteLabel(int id) =>
      (delete(labels)..where((l) => l.id.equals(id))).go();

  Future<List<Label>> findForTodo(int todoId) {
    final query = select(labels).join([
      innerJoin(todoLabels, todoLabels.labelId.equalsExp(labels.id)),
    ])
      ..where(todoLabels.todoId.equals(todoId));
    return query.map((row) => row.readTable(labels)).get();
  }

  Future<void> attachLabel(int todoId, int labelId) async {
    await into(todoLabels).insert(
      TodoLabelsCompanion(
        todoId: Value(todoId),
        labelId: Value(labelId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> detachLabel(int todoId, int labelId) async {
    await (delete(todoLabels)
          ..where((t) => t.todoId.equals(todoId) & t.labelId.equals(labelId)))
        .go();
  }

  Future<void> setLabelsForTodo(int todoId, List<int> labelIds) async {
    await (delete(todoLabels)..where((t) => t.todoId.equals(todoId))).go();
    for (final labelId in labelIds) {
      await attachLabel(todoId, labelId);
    }
  }
}
