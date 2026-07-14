part of 'balance_sheet_cubit.dart';

sealed class BalanceSheetState extends Equatable {
  const BalanceSheetState();
}

class BalanceSheetLoading extends BalanceSheetState {
  @override
  List<Object> get props => [];
}

class BalanceSheetLoaded extends BalanceSheetState {
  final List<BalanceSheetAccountModel> accounts;

  const BalanceSheetLoaded(this.accounts);

  List<BalanceSheetAccountModel> get assets =>
      accounts.where((a) => a.type == BalanceSheetAccountType.asset).toList();

  List<BalanceSheetAccountModel> get liabilities => accounts
      .where((a) => a.type == BalanceSheetAccountType.liability)
      .toList();

  List<BalanceSheetAccountModel> get equity => accounts
      .where((a) => a.type == BalanceSheetAccountType.equity)
      .toList();

  double get totalAssets => assets.fold(0.0, (sum, a) => sum + a.amount);

  double get totalLiabilities =>
      liabilities.fold(0.0, (sum, a) => sum + a.amount);

  double get totalEquity => equity.fold(0.0, (sum, a) => sum + a.amount);

  /// The standard accounting identity check: Assets = Liabilities + Equity.
  bool get isBalanced =>
      (totalAssets - (totalLiabilities + totalEquity)).abs() < 0.01;

  @override
  List<Object> get props => [accounts];
}

class BalanceSheetError extends BalanceSheetState {
  final ErrorType type;

  const BalanceSheetError(this.type);

  @override
  List<Object> get props => [type];
}

class BalanceSheetSuccess extends BalanceSheetState {
  final SuccessType type;

  const BalanceSheetSuccess(this.type);

  @override
  List<Object> get props => [type];
}

class BalanceSheetFormInitial extends BalanceSheetState {
  final BalanceSheetAccountType type;
  final Map<String, String> errors;

  const BalanceSheetFormInitial({
    required this.type,
    this.errors = const {},
  });

  BalanceSheetFormInitial copyWith({
    BalanceSheetAccountType? type,
    Map<String, String>? errors,
  }) {
    return BalanceSheetFormInitial(
      type: type ?? this.type,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [type, errors];
}
