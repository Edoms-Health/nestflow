import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

class TodoPriorityConverter extends TypeConverter<TodoPriority, String> {
  const TodoPriorityConverter();

  @override
  TodoPriority fromSql(String fromDb) {
    return TodoPriority.values.firstWhere((e) => e.name == fromDb);
  }

  @override
  String toSql(TodoPriority value) => value.name;
}

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().map(const TodoPriorityConverter())();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// FK to Projects.id, nullable (todo may be in no project / "Inbox")
  IntColumn get projectId =>
      integer().nullable().references(Projects, #id)();

  /// Self-referencing FK for one level of sub-tasks (Todoist renders
  /// only one level deep in practice, so we don't support grandchildren)
  IntColumn get parentId => integer().nullable().references(Todos, #id)();

  /// Simple recurrence token, e.g. 'daily', 'weekly', 'monthly',
  /// 'weekdays'. Null = does not repeat. Kept as a plain string rather
  /// than a full RRULE parser to match Todoist's common-case presets.
  TextColumn get recurrenceRule => text().nullable()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get color => text().withDefault(const Constant('#4A90D9'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get color => text().withDefault(const Constant('#95A5A6'))();
}

/// Many-to-many join between Todos and Labels
class TodoLabels extends Table {
  IntColumn get todoId =>
      integer().references(Todos, #id, onDelete: KeyAction.cascade)();
  IntColumn get labelId =>
      integer().references(Labels, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {todoId, labelId};
}
