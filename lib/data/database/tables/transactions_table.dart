import 'package:drift/drift.dart';
import 'package:nestflow/data/database/tables/export.dart';
import 'package:nestflow/nestflow.dart';

class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) =>
      TransactionType.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(TransactionType value) => value.name;
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  TextColumn get type => text().map(const TransactionTypeConverter())();

  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.cascade)();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable().withLength(min: 0, max: 255)();

  TextColumn get currency =>
      text().withLength(min: 1, max: 10).withDefault(const Constant('USD'))();

  RealColumn get currencyRate => real().withDefault(const Constant(1.0))();

  BoolColumn get noImpactOnBalance =>
      boolean().withDefault(const Constant(false))();

  IntColumn get contactId => integer().nullable().references(
    Contacts,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Destination wallet for a `transfer`-type transaction. Null for all
  /// other transaction types.
  IntColumn get toWalletId => integer().nullable().references(
    Wallets,
    #id,
    onDelete: KeyAction.cascade,
  )();

  DateTimeColumn get startDate => dateTime().nullable()();

  DateTimeColumn get endDate => dateTime().nullable()();

  /// Interest rate charged by the lender, for `debts`-type transactions
  /// where money is being borrowed (category `receiving_debts_and_installments`).
  /// Meaning depends on [interestIsDaily]: a flat one-time % of the
  /// principal if false, or a % charged per day (accruing from [startDate])
  /// if true. Null for all other transactions.
  RealColumn get interestRate => real().nullable()();

  /// Whether [interestRate] is a daily accruing rate rather than a flat
  /// one-time rate. Null/false = flat.
  BoolColumn get interestIsDaily =>
      boolean().nullable().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
