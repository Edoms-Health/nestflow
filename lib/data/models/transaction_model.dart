import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

class TransactionModel {
  final int id;
  final double amount;
  final TransactionType type;
  final int walletId;
  final WalletModel? wallet;
  final ContactModel? contact;
  final int categoryId;
  final int? contactId;
  final CategoryModel? category;
  final int? toWalletId;
  final WalletModel? toWallet;
  final DateTime date;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? interestRate;
  final bool interestIsDaily;
  final String? note;
  final String currency;
  final double currencyRate;
  final bool noImpactOnBalance;
  final List<int> tagIds;
  final List<TagModel>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.walletId,
    required this.categoryId,
    required this.currency,
    required this.currencyRate,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.noImpactOnBalance = false,
    this.tagIds = const [],
    this.contactId,
    this.wallet,
    this.contact,
    this.category,
    this.toWalletId,
    this.toWallet,
    this.startDate,
    this.endDate,
    this.interestRate,
    this.interestIsDaily = false,
    this.note,
    this.tags,
  });

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(
    id: t.id,
    amount: t.amount,
    type: t.type,
    walletId: t.walletId,
    categoryId: t.categoryId,
    contactId: t.contactId,
    toWalletId: t.toWalletId,
    date: t.date,
    startDate: t.startDate,
    endDate: t.endDate,
    interestRate: t.interestRate,
    interestIsDaily: t.interestIsDaily ?? false,
    note: t.note,
    currency: t.currency,
    currencyRate: t.currencyRate,
    noImpactOnBalance: t.noImpactOnBalance,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );

  Transaction toEntity() => Transaction(
    id: id,
    amount: amount,
    type: type,
    walletId: walletId,
    categoryId: categoryId,
    contactId: contactId,
    toWalletId: toWalletId,
    date: date,
    startDate: startDate,
    endDate: endDate,
    interestRate: interestRate,
    interestIsDaily: interestIsDaily,
    note: note,
    currency: currency,
    currencyRate: currencyRate,
    noImpactOnBalance: noImpactOnBalance,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  TransactionsCompanion toInsertCompanion() => TransactionsCompanion(
    amount: Value(amount),
    type: Value(type),
    walletId: Value(walletId),
    categoryId: Value(categoryId),
    contactId: Value(contactId),
    toWalletId: Value(toWalletId),
    date: Value(date),
    startDate: Value(startDate),
    endDate: Value(endDate),
    interestRate: Value(interestRate),
    interestIsDaily: Value(interestIsDaily),
    note: Value(note),
    currency: Value(currency),
    currencyRate: Value(currencyRate),
    noImpactOnBalance: Value(noImpactOnBalance),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );

  TransactionModel copyWith({
    double? amount,
    TransactionType? type,
    int? walletId,
    WalletModel? wallet,
    int? categoryId,
    CategoryModel? category,
    ContactModel? contact,
    int? contactId,
    int? toWalletId,
    WalletModel? toWallet,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    double? interestRate,
    bool? interestIsDaily,
    String? note,
    String? currency,
    double? currencyRate,
    bool? noImpactOnBalance,
    List<int>? tagIds,
    List<TagModel>? tags,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      wallet: wallet ?? this.wallet,
      contactId: contactId ?? this.contactId,
      contact: contact ?? this.contact,
      toWalletId: toWalletId ?? this.toWalletId,
      toWallet: toWallet ?? this.toWallet,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      date: date ?? this.date,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      interestRate: interestRate ?? this.interestRate,
      interestIsDaily: interestIsDaily ?? this.interestIsDaily,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      currencyRate: currencyRate ?? this.currencyRate,
      noImpactOnBalance: noImpactOnBalance ?? this.noImpactOnBalance,
      tagIds: tagIds ?? this.tagIds,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Money get amountMoney => Money(amount, currency);

  /// Interest owed on this debt as of [asOf] (defaults to now).
  /// - Flat mode: a one-time % of the principal, constant over time.
  /// - Daily mode: [interestRate]% of the principal, charged for each day
  ///   elapsed since [startDate] (or [date] if no start date is set).
  /// Zero if no interest rate is set.
  double interestAmountAsOf([DateTime? asOf]) {
    if (interestRate == null) return 0;
    if (!interestIsDaily) return amount * (interestRate! / 100);

    final from = startDate ?? date;
    final to = asOf ?? DateTime.now();
    final daysElapsed = to.isAfter(from) ? to.difference(from).inDays : 0;
    return amount * (interestRate! / 100) * daysElapsed;
  }

  /// Total amount to be repaid as of [asOf] (defaults to now):
  /// principal + interest accrued so far.
  double totalWithInterestAsOf([DateTime? asOf]) =>
      amount + interestAmountAsOf(asOf);

  Money interestAmountMoneyAsOf([DateTime? asOf]) =>
      Money(interestAmountAsOf(asOf), currency);

  Money totalWithInterestMoneyAsOf([DateTime? asOf]) =>
      Money(totalWithInterestAsOf(asOf), currency);

  /// Convenience getters using the current moment — handy in widgets that
  /// don't need to pin a specific "as of" date.
  double get interestAmount => interestAmountAsOf();
  double get totalWithInterest => totalWithInterestAsOf();
  Money get interestAmountMoney => interestAmountMoneyAsOf();
  Money get totalWithInterestMoney => totalWithInterestMoneyAsOf();
}
