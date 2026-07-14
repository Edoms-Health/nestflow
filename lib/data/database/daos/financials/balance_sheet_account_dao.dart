import 'package:drift/drift.dart';
import 'package:nestflow/data/database/tables/financials_tables.dart';
import 'package:nestflow/nestflow.dart';

part 'balance_sheet_account_dao.g.dart';

@DriftAccessor(tables: [BalanceSheetAccounts])
class BalanceSheetAccountDao extends DatabaseAccessor<AppDatabase>
    with _$BalanceSheetAccountDaoMixin {
  BalanceSheetAccountDao(super.db);

  Future<List<BalanceSheetAccount>> getAll() {
    return (select(
      balanceSheetAccounts,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<int> insertAccount(BalanceSheetAccountsCompanion data) =>
      into(balanceSheetAccounts).insert(data);

  Future<bool> updateAccount(BalanceSheetAccount data) =>
      update(balanceSheetAccounts).replace(data);

  Future<int> deleteAccount(int id) =>
      (delete(balanceSheetAccounts)..where((t) => t.id.equals(id))).go();
}
