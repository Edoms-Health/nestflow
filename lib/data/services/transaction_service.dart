import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/core/core.dart';
import 'package:nestflow/data/data.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();

  factory TransactionService() => _instance;

  TransactionService._internal();

  final TransactionDao _dao = TransactionDao(AppDatabase.instance);
  final CategoryService _categoryService = CategoryService();
  final WalletService _walletService = WalletService();

  Future<int> create(TransactionModel model) async {
    final transactionId = await _dao.insertTransaction(model);
    if (!model.noImpactOnBalance) {
      await _walletService.recalculateWalletBalance(id: model.walletId);
      if (model.type == TransactionType.transfer && model.toWalletId != null) {
        await _walletService.recalculateWalletBalance(id: model.toWalletId!);
      }
      AppEvents.notifyBalanceChanged();
    }
    return transactionId;
  }

  Future<void> delete(TransactionModel transaction) async {
    await _dao.deleteTransaction(transaction.id);
    if (!transaction.noImpactOnBalance) {
      await _walletService.recalculateWalletBalance(id: transaction.walletId);
      if (transaction.type == TransactionType.transfer && transaction.toWalletId != null) {
        await _walletService.recalculateWalletBalance(id: transaction.toWalletId!);
      }
      AppEvents.notifyBalanceChanged();
    }
  }

  Future<List<TransactionModel>> getTransactionPagination({
    CategoryModel? category,
    ContactModel? contact,
    DateTimeRange<DateTime>? dateRange,
    TransactionType? type,
    int? walletId,
    List<int>? tagIds,
    int offset = 0,
    int? limit,
  }) async => (await _dao.pagination(
    offset: offset,
    category: category,
    contact: contact,
    dateRange: dateRange,
    type: type,
    walletId: walletId,
    tagIds: tagIds,
    limit: limit ?? AppStrings.paginationLimit,
  ));

  Future<List<TransactionModel>> getRecentTransactions() async =>
      (await _dao.getRecentTransactions());

  Future<TransactionModel?> find(int id) async => (await _dao.find(id));

  Future<
    ({
      Money income,
      Money expenses,
      Money debtsPaid,
      Money debtsReceived,
      Money transferred,
    })
  >
  getTotals({
    int? categoryId,
    int? contactId,
    int? walletId,
    TransactionType? type,
    DateTimeRange<DateTime>? dateRange,
    List<int>? tagIds,
    bool includeDebts = false,
  }) async {
    final result = await _dao.getTotals(
      categoryId: categoryId,
      contactId: contactId,
      walletId: walletId,
      type: type,
      dateRange: dateRange,
      tagIds: tagIds,
      includeDebts: includeDebts,
    );
    return (
      income: Money.inDefaultCurrency(result.income),
      expenses: Money.inDefaultCurrency(result.expenses),
      debtsPaid: Money.inDefaultCurrency(result.debtsPaid),
      debtsReceived: Money.inDefaultCurrency(result.debtsReceived),
      transferred: Money.inDefaultCurrency(result.transferred),
    );
  }

  List<TransactionGroupedByDateModel> groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> groupedMap = {};

    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      groupedMap.putIfAbsent(key, () => []).add(tx);
    }

    final List<TransactionGroupedByDateModel> result = groupedMap.entries.map((
      entry,
    ) {
      final date = DateTime.parse(entry.key);
      return TransactionGroupedByDateModel(
        date: date,
        transactions: entry.value,
      );
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Future<bool> hasTransaction() async {
    return (await _dao.hasTransactions());
  }

  Future<List<WeeklyChartDataModel>> getWeeklyChartData() async {
    final startOfWeek = DateTimeUtils.startOfWeek();
    final endOfWeek = DateTimeUtils.endOfWeek();

    final transactions = await _dao.getBetween(startOfWeek, endOfWeek);

    final Map<String, WeeklyChartDataModel> data = {
      for (int i = 0; i < 7; i++)
        DateFormat.E().format(
          startOfWeek.add(Duration(days: i)),
        ): WeeklyChartDataModel(
          day: DateFormat.E().format(startOfWeek.add(Duration(days: i))),
          income: 0,
          expenses: 0,
        ),
    };

    for (final tx in transactions) {
      final day = DateFormat.E().format(tx.date);
      final amount = (await tx.amountMoney.convertToDefaultCurrency()).amount;

      if (tx.type == TransactionType.income) {
        data[day]!.income += amount;
      } else if (tx.type == TransactionType.expenses) {
        data[day]!.expenses += amount;
      }
    }

    return data.values.toList();
  }

  Future<List<MonthlySummaryModel>> getMonthlyIncomeVsExpenses({
    int? categoryId,
    int? contactId,
    int? walletId,
    DateTimeRange? dateRange,
    TransactionType? type,
    List<int>? tagIds,
  }) async => _dao.getMonthlyIncomeVsExpenses(
    categoryId: categoryId,
    contactId: contactId,
    walletId: walletId,
    dateRange: dateRange,
    type: type,
    tagIds: tagIds,
  );

  Future<void> insertAll(List<TransactionModel> data) async =>
      _dao.insertAll(data);

  Future<void> createAddBalanceTransaction({
    required WalletModel wallet,
    required double amount,
  }) async {
    final DateTime now = DateTime.now();
    await create(
      TransactionModel(
        id: 0,
        amount: amount,
        type: TransactionType.income,
        walletId: wallet.id,
        categoryId: (await _categoryService.findByIdentifier(
          "add_balance",
        ))!.id,
        date: now,
        currency: wallet.currency,
        currencyRate: await CurrencyRateUtils.forCurrency(wallet.currency),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> createWithdrawBalanceTransaction({
    required WalletModel wallet,
    required double amount,
  }) async {
    final DateTime now = DateTime.now();
    await create(
      TransactionModel(
        id: 0,
        amount: amount,
        type: TransactionType.expenses,
        walletId: wallet.id,
        categoryId: (await _categoryService.findByIdentifier(
          "withdraw_balance",
        ))!.id,
        date: now,
        currency: wallet.currency,
        currencyRate: await CurrencyRateUtils.forCurrency(wallet.currency),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> update(TransactionModel model, TransactionModel oldModel) async {
    final bool isUpdated = await _dao.updateTransaction(model);

    if (oldModel.noImpactOnBalance && model.noImpactOnBalance) {
      return isUpdated;
    }

    final affectedWalletIds = <int>{
      oldModel.walletId,
      model.walletId,
      if (oldModel.toWalletId != null) oldModel.toWalletId!,
      if (model.toWalletId != null) model.toWalletId!,
    };

    for (final walletId in affectedWalletIds) {
      await _walletService.recalculateWalletBalance(id: walletId);
    }

    AppEvents.notifyBalanceChanged();

    return isUpdated;
  }
}
