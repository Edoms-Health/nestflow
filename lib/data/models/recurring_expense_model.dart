import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

class RecurringExpenseModel {
  final int id;
  final double amount;
  final int walletId;
  final WalletModel? wallet;
  final int categoryId;
  final CategoryModel? category;
  final int? contactId;
  final ContactModel? contact;
  final String? note;
  final String currency;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringExpenseModel({
    required this.id,
    required this.amount,
    required this.walletId,
    required this.categoryId,
    required this.currency,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
    this.category,
    this.contactId,
    this.contact,
    this.note,
    this.endDate,
    this.isActive = true,
  });

  factory RecurringExpenseModel.fromEntity(RecurringExpense e) =>
      RecurringExpenseModel(
        id: e.id,
        amount: e.amount,
        walletId: e.walletId,
        categoryId: e.categoryId,
        contactId: e.contactId,
        note: e.note,
        currency: e.currency,
        frequency: e.frequency,
        nextDueDate: e.nextDueDate,
        endDate: e.endDate,
        isActive: e.isActive,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  RecurringExpensesCompanion toInsertCompanion() => RecurringExpensesCompanion(
    amount: Value(amount),
    walletId: Value(walletId),
    categoryId: Value(categoryId),
    contactId: Value(contactId),
    note: Value(note),
    currency: Value(currency),
    frequency: Value(frequency),
    nextDueDate: Value(nextDueDate),
    endDate: Value(endDate),
    isActive: Value(isActive),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );

  RecurringExpense toEntity() => RecurringExpense(
    id: id,
    amount: amount,
    walletId: walletId,
    categoryId: categoryId,
    contactId: contactId,
    note: note,
    currency: currency,
    frequency: frequency,
    nextDueDate: nextDueDate,
    endDate: endDate,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  RecurringExpenseModel copyWith({
    double? amount,
    int? walletId,
    WalletModel? wallet,
    int? categoryId,
    CategoryModel? category,
    int? contactId,
    ContactModel? contact,
    String? note,
    String? currency,
    RecurrenceFrequency? frequency,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RecurringExpenseModel(
      id: id,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      wallet: wallet ?? this.wallet,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      contactId: contactId ?? this.contactId,
      contact: contact ?? this.contact,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Money get amountMoney => Money(amount, currency);
}
