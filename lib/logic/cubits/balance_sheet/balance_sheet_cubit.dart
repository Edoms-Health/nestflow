import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

part 'balance_sheet_state.dart';

class BalanceSheetCubit extends Cubit<BalanceSheetState> {
  final BalanceSheetService service = BalanceSheetService();

  BalanceSheetCubit() : super(BalanceSheetLoading());

  Future<void> load() async {
    try {
      final accounts = await service.fetchAll();
      emit(BalanceSheetLoaded(accounts));
    } catch (e) {
      emit(BalanceSheetError(ErrorType.failedToLoad));
    }
  }

  void deleteAccount(BalanceSheetAccountModel account) async {
    try {
      await service.delete(account.id);
      await load();
      emit(BalanceSheetSuccess(SuccessType.deleted));
    } catch (e) {
      emit(BalanceSheetError(ErrorType.failedToDelete));
    }
  }

  void formInit({BalanceSheetAccountModel? account}) {
    emit(
      BalanceSheetFormInitial(
        type: account?.type ?? BalanceSheetAccountType.asset,
        errors: {},
      ),
    );
  }

  void setType(BalanceSheetAccountType type) {
    if (state is BalanceSheetFormInitial) {
      emit((state as BalanceSheetFormInitial).copyWith(type: type));
    }
  }

  Future<bool> submit(
    Map<String, String> errorMessages,
    BalanceSheetAccountModel? account,
    String? name,
    double? amount,
    String? note,
  ) async {
    final form = state as BalanceSheetFormInitial;
    final errors = <String, String>{};

    if (name == null || name.trim().isEmpty) {
      errors['name'] = errorMessages['name_is_required']!;
    }
    if (amount == null || amount < 0) {
      errors['amount'] = errorMessages['amount_must_be_greater_than']!;
    }

    if (errors.isNotEmpty) {
      emit(form.copyWith(errors: errors));
      return false;
    }

    try {
      final now = DateTime.now();
      final model = BalanceSheetAccountModel(
        id: account?.id ?? 0,
        name: name!,
        type: form.type,
        amount: amount!,
        note: note,
        createdAt: account?.createdAt ?? now,
        updatedAt: now,
      );

      if (account == null) {
        await service.create(model);
        emit(BalanceSheetSuccess(SuccessType.created));
      } else {
        await service.update(model);
        emit(BalanceSheetSuccess(SuccessType.updated));
      }
      await load();
      return true;
    } catch (e) {
      emit(BalanceSheetError(ErrorType.failedToAdd));
      return false;
    }
  }
}
