import 'package:drift/drift.dart';

class MonthlyFinancials extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get year => integer()();

  IntColumn get month => integer()();

  RealColumn get income => real().withDefault(const Constant(0.0))();

  RealColumn get expense => real().withDefault(const Constant(0.0))();

  TextColumn get note => text().nullable().withLength(min: 0, max: 255)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {year, month},
  ];
}

class BalanceSheetAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// One of: 'asset', 'liability', 'equity'
  TextColumn get type => text().withLength(min: 1, max: 20)();

  RealColumn get amount => real().withDefault(const Constant(0.0))();

  TextColumn get note => text().nullable().withLength(min: 0, max: 255)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
