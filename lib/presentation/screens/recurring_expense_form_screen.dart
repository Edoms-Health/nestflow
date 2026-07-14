import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class RecurringExpenseFormScreen extends StatefulWidget {
  final RecurringExpenseModel? item;

  const RecurringExpenseFormScreen({super.key, this.item});

  @override
  State<RecurringExpenseFormScreen> createState() =>
      _RecurringExpenseFormScreenState();
}

class _RecurringExpenseFormScreenState
    extends State<RecurringExpenseFormScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _amountController.text = widget.item!.amount.toString();
      _noteController.text = widget.item!.note ?? '';
    }
    context.read<RecurringExpenseCubit>().formInit(item: widget.item);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecurringExpenseCubit, RecurringExpenseState>(
      buildWhen: (previous, current) =>
          current.runtimeType == RecurringExpenseFormInitial,
      builder: (context, state) {
        if (state is! RecurringExpenseFormInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final wallet = state.wallets
            .where((w) => w.id == state.walletId)
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.item == null
                  ? 'New Recurring Expense'
                  : 'Edit Recurring Expense',
            ),
          ),
          bottomNavigationBar: FormBottomNavigationBar(
            okButtonOnPressed: () async {
              if (await context.read<RecurringExpenseCubit>().submit(
                {
                  "amount_is_required": context.tr!.attribute_is_required(
                    context.tr!.amount,
                  ),
                  "amount_must_be_greater_than": context.tr!
                      .attribute_must_be_greater_than_number(
                        context.tr!.amount,
                        0,
                      ),
                  "category_is_required": context.tr!.attribute_is_required(
                    context.tr!.category,
                  ),
                  "wallet_is_required": context.tr!.attribute_is_required(
                    context.tr!.wallet,
                  ),
                },
                widget.item,
                double.tryParse(_amountController.text),
                _noteController.text,
              )) {
                if (!context.mounted) return;
                Navigator.pop(context, true);
              }
            },
            okButtonLoading: state.processing,
            okButtonText: widget.item == null
                ? context.tr!.create
                : context.tr!.update,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                ContainerForm(
                  margin: EdgeInsets.only(
                    bottom: AppDimensions.inputBottomMargin,
                  ),
                  child: CustomTextFormField(
                    label:
                        "${context.tr!.amount}${wallet != null ? ' (${wallet.currency})' : ''}",
                    controller: _amountController,
                    hintText: context.tr!.hint_text_transaction_amount(
                      wallet?.currency ?? '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    errorText: state.errors['amount'],
                  ),
                ),
                CategoryPicker(
                  label: context.tr!.category,
                  categories: state.categories,
                  hasDivider: true,
                  margin: EdgeInsets.zero,
                  selectedId: state.categoryId,
                  errorText: state.errors['category_id'],
                  onPicked: (CategoryModel category) => context
                      .read<RecurringExpenseCubit>()
                      .setData(categoryId: category.id),
                ),
                CustomDropdownMenu(
                  label: context.tr!.wallet,
                  options: state.wallets
                      .map(
                        (WalletModel w) => CustomDropdownMenuOption(
                          id: w.id,
                          name: w.name,
                          subtitle: w.type.toTrans(context),
                          trailingText: w.balanceMoney.format(),
                          icon: w.type.icon,
                          color: w.type.color,
                        ),
                      )
                      .toList(),
                  selectedId: state.walletId,
                  errorText: state.errors['wallet_id'],
                  onSelect: (dynamic id) =>
                      context.read<RecurringExpenseCubit>().setData(
                        walletId: id,
                      ),
                ),
                ContainerForm(
                  margin: EdgeInsets.only(
                    bottom: AppDimensions.inputBottomMargin,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<RecurrenceFrequency>(
                        segments: RecurrenceFrequency.values
                            .map(
                              (f) =>
                                  ButtonSegment(value: f, label: Text(f.label)),
                            )
                            .toList(),
                        selected: {state.frequency},
                        onSelectionChanged: (selection) => context
                            .read<RecurringExpenseCubit>()
                            .setData(frequency: selection.first),
                      ),
                    ],
                  ),
                ),
                ContainerForm(
                  margin: EdgeInsets.only(
                    bottom: AppDimensions.inputBottomMargin,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.endDate != null
                                  ? '${state.endDate!.year}-${state.endDate!.month.toString().padLeft(2, '0')}-${state.endDate!.day.toString().padLeft(2, '0')}'
                                  : 'No end date',
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                state.endDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (picked != null && context.mounted) {
                            context.read<RecurringExpenseCubit>().setData(
                              endDate: picked,
                            );
                          }
                        },
                        child: const Text('Pick'),
                      ),
                      if (state.endDate != null)
                        IconButton(
                          onPressed: () => context
                              .read<RecurringExpenseCubit>()
                              .setData(clearEndDate: true),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                    ],
                  ),
                ),
                ContainerForm(
                  paddingVertical: AppDimensions.padding,
                  child: CustomTextFormField(
                    label: context.tr!.note,
                    controller: _noteController,
                    hintText: context.tr!.transaction_note_placeholder,
                    required: false,
                    keyboardType: TextInputType.multiline,
                    maxLength: 200,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
