part of 'recurring_expense_cubit.dart';

sealed class RecurringExpenseState extends Equatable {
  const RecurringExpenseState();
}

class RecurringExpenseLoading extends RecurringExpenseState {
  @override
  List<Object> get props => [];
}

class RecurringExpenseLoaded extends RecurringExpenseState {
  final List<RecurringExpenseModel> items;

  const RecurringExpenseLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class RecurringExpenseError extends RecurringExpenseState {
  final ErrorType type;

  const RecurringExpenseError(this.type);

  @override
  List<Object?> get props => [type];
}

class RecurringExpenseSuccess extends RecurringExpenseState {
  final SuccessType type;

  const RecurringExpenseSuccess(this.type);

  @override
  List<Object?> get props => [type];
}

final class RecurringExpenseFormInitial extends RecurringExpenseState {
  final List<WalletModel> wallets;
  final List<CategoryModel> categories;
  final int? walletId;
  final int? categoryId;
  final RecurrenceFrequency frequency;
  final DateTime? endDate;
  final bool processing;
  final Map<String, String> errors;

  const RecurringExpenseFormInitial({
    this.wallets = const [],
    this.categories = const [],
    this.walletId,
    this.categoryId,
    this.frequency = RecurrenceFrequency.monthly,
    this.endDate,
    this.processing = false,
    this.errors = const {},
  });

  RecurringExpenseFormInitial copyWith({
    List<WalletModel>? wallets,
    List<CategoryModel>? categories,
    int? walletId,
    int? categoryId,
    RecurrenceFrequency? frequency,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? processing,
    Map<String, String>? errors,
  }) {
    return RecurringExpenseFormInitial(
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      processing: processing ?? this.processing,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    categories,
    walletId,
    categoryId,
    frequency,
    endDate,
    processing,
    errors,
  ];
}
