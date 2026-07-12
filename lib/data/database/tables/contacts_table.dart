import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get color =>
      text().withDefault(Constant('#1ca0d9')).withLength(min: 1, max: 10)();

  TextColumn get phone => text().nullable().withLength(min: 0, max: 20)();

  TextColumn get provider => text().nullable().withLength(min: 0, max: 20)();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
