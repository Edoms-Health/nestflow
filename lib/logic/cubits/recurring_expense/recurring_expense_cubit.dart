import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

part 'recurring_expense_state.dart';

class RecurringExpenseCubit extends Cubit<RecurringExpenseState> {
  final RecurringExpenseService service = RecurringExpenseService();
  final WalletService walletService = WalletService();
  final CategoryService categoryService = CategoryService();

  RecurringExpenseCubit() : super(RecurringExpenseLoading());

  Future<void> loadAll() async {
    try {
      emit(RecurringExpenseLoaded(await service.fetchAll(isActive: true)));
    } catch (e) {
      emit(RecurringExpenseError(ErrorType.failedToLoad));
    }
  }

  void deleteItem(int id) async {
    try {
      await service.delete(id);
      await loadAll();
      emit(RecurringExpenseSuccess(SuccessType.deleted));
    } catch (e) {
      emit(RecurringExpenseError(ErrorType.failedToDelete));
    }
  }

  Future<void> formInit({RecurringExpenseModel? item}) async {
    final List<WalletModel> wallets = await walletService.fetchAll(
      isLocked: false,
    );
    final List<CategoryModel> categories =
        (await categoryService.getGrouped(type: TransactionType.expenses))
            .where((c) => c.identifier != 'balance_transfer')
            .toList();

    emit(
      RecurringExpenseFormInitial(
        wallets: wallets,
        categories: categories,
        walletId: item?.walletId ?? wallets.first.id,
        categoryId: item?.categoryId ?? categories.first.id,
        frequency: item?.frequency ?? RecurrenceFrequency.monthly,
        endDate: item?.endDate,
      ),
    );
  }

  void setData({
    int? walletId,
    int? categoryId,
    RecurrenceFrequency? frequency,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    if (state is RecurringExpenseFormInitial) {
      emit(
        (state as RecurringExpenseFormInitial).copyWith(
          walletId: walletId,
          categoryId: categoryId,
          frequency: frequency,
          endDate: endDate,
          clearEndDate: clearEndDate,
        ),
      );
    }
  }

  Future<bool> submit(
    Map<String, String> errorMessages,
    RecurringExpenseModel? item,
    double? amount,
    String? note,
  ) async {
    final RecurringExpenseFormInitial form =
        state as RecurringExpenseFormInitial;
    bool isSubmitted = false;

    if (_validate(form, errorMessages, amount)) {
      emit(form.copyWith(processing: true, errors: {}));

      isSubmitted = item == null
          ? await _create(form, amount!, note)
          : await _update(form, item, amount!, note);

      if (!isSubmitted) {
        emit(form.copyWith(processing: false));
      }
    }
    return isSubmitted;
  }

  Future<bool> _create(
    RecurringExpenseFormInitial form,
    double amount,
    String? note,
  ) async {
    try {
      final now = DateTime.now();
      final currency = form.wallets
          .firstWhere((w) => w.id == form.walletId)
          .currency;

      await service.create(
        RecurringExpenseModel(
          id: 0,
          amount: amount,
          walletId: form.walletId!,
          categoryId: form.categoryId!,
          note: (note == null || note.trim().isEmpty) ? null : note.trim(),
          currency: currency,
          frequency: form.frequency,
          nextDueDate: form.frequency.next(now),
          endDate: form.endDate,
          createdAt: now,
          updatedAt: now,
        ),
      );
      emit(RecurringExpenseSuccess(SuccessType.created));
      return true;
    } catch (e) {
      emit(RecurringExpenseError(ErrorType.failedToAdd));
      return false;
    }
  }

  Future<bool> _update(
    RecurringExpenseFormInitial form,
    RecurringExpenseModel item,
    double amount,
    String? note,
  ) async {
    try {
      final currency = form.wallets
          .firstWhere((w) => w.id == form.walletId)
          .currency;

      await service.update(
        item.copyWith(
          amount: amount,
          walletId: form.walletId,
          categoryId: form.categoryId,
          note: (note == null || note.trim().isEmpty) ? null : note.trim(),
          currency: currency,
          frequency: form.frequency,
          endDate: form.endDate,
          updatedAt: DateTime.now(),
        ),
      );
      emit(RecurringExpenseSuccess(SuccessType.updated));
      return true;
    } catch (e) {
      emit(RecurringExpenseError(ErrorType.failedToUpdate));
      return false;
    }
  }

  bool _validate(
    RecurringExpenseFormInitial form,
    Map<String, String> errorMessages,
    double? amount,
  ) {
    final Map<String, String> errors = {};

    if (amount == null) {
      errors['amount'] = errorMessages['amount_is_required']!;
    } else if (amount < 1) {
      errors['amount'] = errorMessages['amount_must_be_greater_than']!;
    }
    if (form.categoryId == null) {
      errors['category_id'] = errorMessages['category_is_required']!;
    }
    if (form.walletId == null) {
      errors['wallet_id'] = errorMessages['wallet_is_required']!;
    }

    if (errors.isNotEmpty) {
      emit(form.copyWith(errors: errors));
      return false;
    }
    return true;
  }
}
