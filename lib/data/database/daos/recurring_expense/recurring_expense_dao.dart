import 'package:drift/drift.dart';
import 'package:nestflow/data/database/tables/recurring_expenses_table.dart';
import 'package:nestflow/nestflow.dart';

part 'recurring_expense_dao.g.dart';

@DriftAccessor(tables: [RecurringExpenses])
class RecurringExpenseDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringExpenseDaoMixin {
  RecurringExpenseDao(super.db);

  Future<List<RecurringExpenseModel>> getAll({
    List<String> relations = const [],
    bool? isActive,
  }) async {
    final query = select(recurringExpenses).join([
      if (relations.contains('category'))
        leftOuterJoin(
          categories,
          categories.id.equalsExp(recurringExpenses.categoryId),
        ),
      if (relations.contains('wallet'))
        leftOuterJoin(
          wallets,
          wallets.id.equalsExp(recurringExpenses.walletId),
        ),
      if (relations.contains('contact'))
        leftOuterJoin(
          contacts,
          contacts.id.equalsExp(recurringExpenses.contactId),
        ),
    ]);

    if (isActive != null) {
      query.where(recurringExpenses.isActive.equals(isActive));
    }
    query.orderBy([OrderingTerm.asc(recurringExpenses.nextDueDate)]);

    final rows = await query.get();

    return rows.map((row) {
      final entity = row.readTable(recurringExpenses);
      final category = row.readTableOrNull(categories);
      final wallet = row.readTableOrNull(wallets);
      final contact = row.readTableOrNull(contacts);

      final model = RecurringExpenseModel.fromEntity(entity);
      return model.copyWith(
        category: category == null ? null : CategoryModel.fromEntity(category),
        wallet: wallet == null ? null : WalletModel.fromEntity(wallet),
        contact: contact == null ? null : ContactModel.fromEntity(contact),
      );
    }).toList();
  }

  /// All active recurring expenses whose [nextDueDate] is on/before [asOf]
  /// and haven't passed their optional [endDate].
  Future<List<RecurringExpenseModel>> getDue({DateTime? asOf}) async {
    final now = asOf ?? DateTime.now();
    final rows =
        await (select(recurringExpenses)..where(
              (t) =>
                  t.isActive.equals(true) &
                  t.nextDueDate.isSmallerOrEqualValue(now) &
                  (t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(now)),
            ))
            .get();
    return rows.map(RecurringExpenseModel.fromEntity).toList();
  }

  Future<RecurringExpenseModel?> find(int id) async {
    final row = await (select(
      recurringExpenses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : RecurringExpenseModel.fromEntity(row);
  }

  Future<int> insertRecurringExpense(RecurringExpensesCompanion data) =>
      into(recurringExpenses).insert(data);

  Future<bool> updateRecurringExpense(RecurringExpense data) =>
      update(recurringExpenses).replace(data);

  Future<int> deleteRecurringExpense(int id) =>
      (delete(recurringExpenses)..where((t) => t.id.equals(id))).go();
}
