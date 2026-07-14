import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class RecurringExpenseScreen extends StatelessWidget {
  const RecurringExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringExpenseCubit, RecurringExpenseState>(
      listener: (context, state) {
        if (state is RecurringExpenseError) {
          context.read<SharedCubit>().showDialog(
            type: AlertDialogType.error,
            title: 'Recurring Expenses',
            message: 'Something went wrong. Please try again.',
          );
        } else if (state is RecurringExpenseSuccess) {
          context.read<SharedCubit>().showSnackBar(
            message: state.type.message(context, 'recurring expense'),
          );
        }
      },
      buildWhen: (previous, current) => [
        RecurringExpenseLoaded,
        RecurringExpenseLoading,
        RecurringExpenseError,
      ].any((type) => current.runtimeType == type),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Recurring Expenses'),
            actions: [
              if (state is RecurringExpenseLoaded && state.items.isNotEmpty)
                IconButton(
                  onPressed: () => _goToForm(context: context),
                  icon: const Icon(Icons.add_outlined),
                ),
            ],
          ),
          extendBodyBehindAppBar:
              !(state is RecurringExpenseLoaded && state.items.isNotEmpty),
          body: Builder(
            builder: (context) {
              if (state is RecurringExpenseLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is RecurringExpenseLoaded &&
                  state.items.isNotEmpty) {
                return SafeArea(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 3),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) => RecurringExpenseTile(
                      item: state.items[index],
                      onPressedEdit: (item) =>
                          _goToForm(context: context, item: item),
                      onPressedDelete: (item) =>
                          _deleteItem(context: context, item: item),
                    ),
                    separatorBuilder: (context, index) =>
                        ListViewSeparatorDivider(height: 0.6),
                  ),
                );
              }
              return PlaceholderView(
                icon: AppIcons.calendar,
                title: 'No recurring expenses yet',
                subtitle:
                    'Expenses you put on repeat will show up here so you can track, edit, or cancel them.',
                actions: [
                  PlaceholderViewAction(
                    title: 'Add recurring expense',
                    icon: AppIcons.plus,
                    onTap: () => _goToForm(context: context),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _goToForm({
    required BuildContext context,
    RecurringExpenseModel? item,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RecurringExpenseCubit>(),
          child: RecurringExpenseFormScreen(item: item),
        ),
      ),
    );
  }

  void _deleteItem({
    required BuildContext context,
    required RecurringExpenseModel item,
  }) {
    context.read<SharedCubit>().showDialog(
      type: AlertDialogType.confirm,
      title: 'Delete Recurring Expense',
      message:
          'Are you sure you want to delete this recurring expense (${item.amountMoney.format()})?',
      icon: AppIcons.calendar,
      callbackConfirm: () =>
          context.read<RecurringExpenseCubit>().deleteItem(item.id),
    );
  }
}
