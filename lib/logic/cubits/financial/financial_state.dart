part of 'financial_cubit.dart';

sealed class FinancialState extends Equatable {
  const FinancialState();
}

class FinancialLoading extends FinancialState {
  @override
  List<Object> get props => [];
}

class FinancialLoaded extends FinancialState {
  final int year;
  final List<int> availableYears;
  final Map<int, MonthlyFinancialModel> entriesByMonth;
  final double annualIncome;
  final double annualExpense;

  const FinancialLoaded({
    required this.year,
    required this.availableYears,
    required this.entriesByMonth,
    required this.annualIncome,
    required this.annualExpense,
  });

  double get annualProfit => annualIncome - annualExpense;

  @override
  List<Object> get props => [year, availableYears, entriesByMonth, annualIncome, annualExpense];
}

class FinancialError extends FinancialState {
  final ErrorType type;

  const FinancialError(this.type);

  @override
  List<Object> get props => [type];
}

class FinancialSuccess extends FinancialState {
  final SuccessType type;

  const FinancialSuccess(this.type);

  @override
  List<Object> get props => [type];
}

class FinancialFormInitial extends FinancialState {
  final int year;
  final int month;
  final MonthlyFinancialModel? entry;
  final Map<String, String> errors;

  const FinancialFormInitial({
    required this.year,
    required this.month,
    this.entry,
    this.errors = const {},
  });

  FinancialFormInitial copyWith({Map<String, String>? errors}) {
    return FinancialFormInitial(
      year: year,
      month: month,
      entry: entry,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [year, month, entry, errors];
}
