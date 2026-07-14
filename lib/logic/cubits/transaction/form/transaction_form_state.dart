part of 'transaction_form_cubit.dart';

sealed class TransactionFormState extends Equatable {
  const TransactionFormState();
}

class TransactionFormLoading extends TransactionFormState {
  @override
  List<Object> get props => [];
}

class TransactionFormInitial extends TransactionFormState {
  final List<WalletModel> wallets;
  final List<CategoryModel> categories;
  final List<TagModel> tags;
  final TransactionType? type;
  final int? walletId;
  final int? categoryId;
  final int? contactId;
  final ContactModel? contact;
  final int? toWalletId;
  final List<int> tagIds;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? interestRate;
  final bool interestIsDaily;
  final String? currency;
  final bool noImpactOnBalance;
  final bool isRecurring;
  final RecurrenceFrequency recurrenceFrequency;
  final bool processing;
  final Map<String, String> errors;

  const TransactionFormInitial({
    this.wallets = const [],
    this.categories = const [],
    this.tags = const [],
    this.type,
    this.walletId,
    this.categoryId,
    this.tagIds = const [],
    this.date,
    this.startDate,
    this.endDate,
    this.interestRate,
    this.interestIsDaily = false,
    this.contactId,
    this.contact,
    this.toWalletId,
    this.currency,
    this.noImpactOnBalance = false,
    this.isRecurring = false,
    this.recurrenceFrequency = RecurrenceFrequency.monthly,
    this.processing = false,
    this.errors = const {},
  });

  TransactionFormInitial copyWith({
    List<WalletModel>? wallets,
    List<CategoryModel>? categories,
    List<TagModel>? tags,
    TransactionType? type,
    int? walletId,
    int? categoryId,
    int? contactId,
    ContactModel? contact,
    int? toWalletId,
    List<int>? tagIds,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    double? interestRate,
    bool? interestIsDaily,
    String? currency,
    double? currencyRate,
    bool? noImpactOnBalance,
    bool? isRecurring,
    RecurrenceFrequency? recurrenceFrequency,
    bool? processing,
    Map<String, String>? errors,
  }) {
    return TransactionFormInitial(
      contact: contact ?? this.contact,
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      contactId: contactId ?? this.contactId,
      toWalletId: toWalletId ?? this.toWalletId,
      tagIds: tagIds ?? this.tagIds,
      date: date ?? this.date,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      interestRate: interestRate ?? this.interestRate,
      interestIsDaily: interestIsDaily ?? this.interestIsDaily,
      tags: tags ?? this.tags,
      currency: currency ?? this.currency,
      noImpactOnBalance: noImpactOnBalance ?? this.noImpactOnBalance,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      categoryId: categories != null
          ? categories.first.id
          : (categoryId ?? this.categoryId),
      processing: processing ?? this.processing,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    categories,
    type,
    walletId,
    contactId,
    toWalletId,
    categoryId,
    tagIds,
    date,
    startDate,
    endDate,
    interestRate,
    interestIsDaily,
    currency,
    contact,
    noImpactOnBalance,
    isRecurring,
    recurrenceFrequency,
    processing,
    errors,
  ];
}

class TransactionFormError extends TransactionFormState {
  final ErrorType type;

  const TransactionFormError(this.type);

  @override
  List<Object?> get props => [type];
}

class TransactionFormSuccess extends TransactionFormState {
  final SuccessType type;

  const TransactionFormSuccess(this.type);

  @override
  List<Object?> get props => [type];
}
