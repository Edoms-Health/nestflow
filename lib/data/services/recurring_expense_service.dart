import 'package:nestflow/nestflow.dart';

class RecurringExpenseService {
  static final RecurringExpenseService _instance =
      RecurringExpenseService._internal();

  factory RecurringExpenseService() => _instance;

  RecurringExpenseService._internal();

  final RecurringExpenseDao _dao = RecurringExpenseDao(AppDatabase.instance);
  final TransactionService _transactionService = TransactionService();

  Future<List<RecurringExpenseModel>> fetchAll({
    List<String> relations = const ['category', 'wallet', 'contact'],
    bool? isActive,
  }) => _dao.getAll(relations: relations, isActive: isActive);

  Future<List<RecurringExpenseModel>> getDue({DateTime? asOf}) =>
      _dao.getDue(asOf: asOf);

  Future<RecurringExpenseModel?> find(int id) => _dao.find(id);

  Future<int> create(RecurringExpenseModel model) async {
    final id = await _dao.insertRecurringExpense(model.toInsertCompanion());
    await NotificationService().scheduleRecurringExpenseReminder(
      model.copyWith(),
    );
    return id;
  }

  Future<bool> update(RecurringExpenseModel model) async {
    final result = await _dao.updateRecurringExpense(model.toEntity());
    await NotificationService().scheduleRecurringExpenseReminder(model);
    return result;
  }

  Future<void> delete(int id) async {
    await NotificationService().cancelRecurringExpenseReminder(id);
    await _dao.deleteRecurringExpense(id);
  }

  /// Advances a recurring expense past its current [nextDueDate], used both
  /// when the user confirms it (creating a real transaction) and when they
  /// dismiss/skip it. Deactivates it if the new due date is past [endDate].
  Future<void> advance(RecurringExpenseModel model) async {
    final newDueDate = model.frequency.next(model.nextDueDate);
    final pastEnd = model.endDate != null && newDueDate.isAfter(model.endDate!);

    final updated = model.copyWith(
      nextDueDate: newDueDate,
      isActive: !pastEnd,
    );

    await _dao.updateRecurringExpense(updated.toEntity());

    if (pastEnd) {
      await NotificationService().cancelRecurringExpenseReminder(model.id);
    } else {
      await NotificationService().scheduleRecurringExpenseReminder(updated);
    }
  }

  /// Confirms a due recurring expense: creates the real transaction from the
  /// template, then advances the schedule.
  Future<TransactionModel> confirm(RecurringExpenseModel model) async {
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: 0,
      amount: model.amount,
      type: TransactionType.expenses,
      walletId: model.walletId,
      categoryId: model.categoryId,
      contactId: model.contactId,
      date: model.nextDueDate,
      note: model.note,
      currency: model.currency,
      currencyRate: await CurrencyRateUtils.forCurrency(model.currency),
      createdAt: now,
      updatedAt: now,
    );

    await _transactionService.create(transaction);
    await advance(model);

    return transaction;
  }

  /// Skips the current occurrence without creating a transaction.
  Future<void> skip(RecurringExpenseModel model) => advance(model);
}
