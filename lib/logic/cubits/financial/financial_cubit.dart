import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

part 'financial_state.dart';

class FinancialCubit extends Cubit<FinancialState> {
  final FinancialService service = FinancialService();

  FinancialCubit() : super(FinancialLoading());

  Future<void> loadYear([int? year]) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final entries = await service.fetchForYear(targetYear);
      final years = await service.fetchAvailableYears();
      if (!years.contains(DateTime.now().year)) {
        years.insert(0, DateTime.now().year);
        years.sort((a, b) => b.compareTo(a));
      }

      final byMonth = {for (final e in entries) e.month: e};

      double annualIncome = 0;
      double annualExpense = 0;
      for (final e in entries) {
        annualIncome += e.income;
        annualExpense += e.expense;
      }

      emit(
        FinancialLoaded(
          year: targetYear,
          availableYears: years,
          entriesByMonth: byMonth,
          annualIncome: annualIncome,
          annualExpense: annualExpense,
        ),
      );
    } catch (e) {
      emit(FinancialError(ErrorType.failedToLoad));
    }
  }

  void formInit({required int year, required int month, MonthlyFinancialModel? entry}) {
    emit(
      FinancialFormInitial(
        year: year,
        month: month,
        entry: entry,
        errors: {},
      ),
    );
  }

  Future<bool> submit(
    Map<String, String> errorMessages,
    double? income,
    double? expense,
    String? note,
  ) async {
    final form = state as FinancialFormInitial;
    final errors = <String, String>{};

    if (income == null || income < 0) {
      errors['income'] = errorMessages['amount_must_be_greater_than']!;
    }
    if (expense == null || expense < 0) {
      errors['expense'] = errorMessages['amount_must_be_greater_than']!;
    }

    if (errors.isNotEmpty) {
      emit(form.copyWith(errors: errors));
      return false;
    }

    try {
      final now = DateTime.now();
      final model = MonthlyFinancialModel(
        id: form.entry?.id ?? 0,
        year: form.year,
        month: form.month,
        income: income!,
        expense: expense!,
        note: note,
        createdAt: form.entry?.createdAt ?? now,
        updatedAt: now,
      );
      await service.upsert(model);
      await loadYear(form.year);
      emit(FinancialSuccess(SuccessType.updated));
      return true;
    } catch (e) {
      emit(FinancialError(ErrorType.failedToUpdate));
      return false;
    }
  }
}
