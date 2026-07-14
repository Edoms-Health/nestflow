import 'package:drift/drift.dart';
import 'package:nestflow/data/database/tables/export.dart';
import 'package:nestflow/nestflow.dart';

class RecurrenceFrequencyConverter
    extends TypeConverter<RecurrenceFrequency, String> {
  const RecurrenceFrequencyConverter();

  @override
  RecurrenceFrequency fromSql(String fromDb) =>
      RecurrenceFrequency.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(RecurrenceFrequency value) => value.name;
}

class RecurringExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.cascade)();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  IntColumn get contactId => integer().nullable().references(
    Contacts,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get note => text().nullable().withLength(min: 0, max: 255)();

  TextColumn get currency =>
      text().withLength(min: 1, max: 10).withDefault(const Constant('USD'))();

  TextColumn get frequency =>
      text().map(const RecurrenceFrequencyConverter())();

  /// The next date this expense is due. Advanced forward each time it's
  /// handled (confirmed or explicitly skipped).
  DateTimeColumn get nextDueDate => dateTime()();

  /// Optional date after which this recurring expense stops firing.
  DateTimeColumn get endDate => dateTime().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
