import 'package:drift/drift.dart';
import 'package:nestflow/data/database/tables/financials_tables.dart';
import 'package:nestflow/nestflow.dart';

part 'monthly_financial_dao.g.dart';

@DriftAccessor(tables: [MonthlyFinancials])
class MonthlyFinancialDao extends DatabaseAccessor<AppDatabase>
    with _$MonthlyFinancialDaoMixin {
  MonthlyFinancialDao(super.db);

  Future<List<MonthlyFinancial>> getForYear(int year) {
    return (select(monthlyFinancials)
          ..where((t) => t.year.equals(year))
          ..orderBy([(t) => OrderingTerm.asc(t.month)]))
        .get();
  }

  Future<List<int>> getAllYears() async {
    final query = selectOnly(monthlyFinancials, distinct: true)
      ..addColumns([monthlyFinancials.year])
      ..orderBy([OrderingTerm.desc(monthlyFinancials.year)]);
    final rows = await query.get();
    return rows.map((r) => r.read(monthlyFinancials.year)!).toList();
  }

  /// Inserts a new month's entry, or updates it if one already exists
  /// for that year+month (enforced by the table's unique key).
  Future<void> upsert(MonthlyFinancialsCompanion data) {
    return into(monthlyFinancials).insertOnConflictUpdate(data);
  }

  Future<int> deleteEntry(int id) =>
      (delete(monthlyFinancials)..where((t) => t.id.equals(id))).go();
}
