import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/presentation/widgets/shared/calculator_modal_bottom_sheet.dart';
import 'package:nestflow/nestflow.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _interestIsDaily = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction != null
        ? widget.transaction!.amount.toString()
        : '';
    _noteController.text = widget.transaction?.note ?? '';
    _interestController.text = widget.transaction?.interestRate != null
        ? widget.transaction!.interestRate.toString()
        : '';
    _interestIsDaily = widget.transaction?.interestIsDaily ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listener: (context, state) {
        if (state is TransactionFormError) {
          context.read<SharedCubit>().showDialog(
            type: AlertDialogType.error,
            title: state.type.title(
              context,
              context.tr!.transactions,
              context.tr!.transaction,
            ),
            message: state.type.message(
              context,
              context.tr!.transactions,
              context.tr!.transaction,
            ),
          );
        } else if (state is TransactionFormSuccess) {
          context.read<SharedCubit>().showSnackBar(
            message: state.type.message(context, context.tr!.transaction),
          );
        }
      },
      buildWhen: (previous, current) => [
        TransactionFormLoading,
        TransactionFormInitial,
      ].any((type) => current.runtimeType == type),
      builder: (context, state) {
        if (state is TransactionFormInitial) {}
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.transaction != null
                  ? context.tr!.edit_resource(context.tr!.transaction)
                  : context.tr!.create_resource(context.tr!.transaction),
            ),
          ),
          bottomNavigationBar: state is TransactionFormInitial
              ? FormBottomNavigationBar(
                  okButtonOnPressed: () async {
                    context.read<TransactionFormCubit>().setData(
                      interestRate: double.tryParse(_interestController.text),
                      interestIsDaily: _interestIsDaily,
                    );
                    if (await context.read<TransactionFormCubit>().submit(
                      {
                        "amount_is_required": context.tr!.attribute_is_required(
                          context.tr!.amount,
                        ),
                        "amount_must_be_greater_than": context.tr!
                            .attribute_must_be_greater_than_number(
                              context.tr!.amount,
                              0,
                            ),
                        "category_is_required": context.tr!
                            .attribute_is_required(context.tr!.category),
                        "wallet_is_required": context.tr!.attribute_is_required(
                          context.tr!.wallet,
                        ),
                        "date_is_required": context.tr!.attribute_is_required(
                          context.tr!.transaction_date,
                        ),
                        "start_date_is_required": context.tr!
                            .attribute_is_required(context.tr!.start_date),
                        "end_date_is_required": context.tr!
                            .attribute_is_required(context.tr!.end_date),
                        "contact_is_required": context.tr!
                            .attribute_is_required(context.tr!.contact),
                        "to_wallet_is_required": context.tr!
                            .attribute_is_required(context.tr!.to_wallet),
                        "to_wallet_must_be_different":
                            context.tr!.to_wallet_must_be_different,
                      },
                      widget.transaction,
                      double.tryParse(_amountController.text),
                      _noteController.text,
                    )) {
                      if (!context.mounted) return;
                      Navigator.pop(context, {"refresh": true});
                    }
                  },
                  okButtonLoading: state.processing,
                  okButtonText: widget.transaction == null
                      ? context.tr!.create
                      : context.tr!.update,
                )
              : null,
          body: state is TransactionFormInitial
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      ContainerForm(
                        margin: EdgeInsets.only(
                          bottom: AppDimensions.inputBottomMargin,
                        ),
                        child: CustomTextFormField(
                          label: "${context.tr!.amount} (${state.currency})",
                          prefixIcon: SizedBox(
                            width: 30,
                            height: 30,
                            child: Center(
                              child: Text(
                                "${state.currency}",
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          controller: _amountController,
                          hintText: context.tr!.hint_text_transaction_amount(
                            state.currency ?? "",
                          ),
                          paddingBottom: 0,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          errorText: state.errors['amount'],
                          suffixIcon: IconButton(
                            onPressed: _showCalculator,
                            icon: SvgIcon(icon: AppIcons.calculator, width: 22),
                          ),
                        ),
                      ),
                      if (state.type != TransactionType.transfer)
                        CategoryPicker(
                          label: context.tr!.category,
                          categories: state.categories,
                          hasDivider: true,
                          margin: EdgeInsets.zero,
                          selectedId: state.categoryId,
                          errorText: state.errors['category_id'],
                          onPicked: (CategoryModel category) => context
                              .read<TransactionFormCubit>()
                              .setData(categoryId: category.id),
                        ),
                      CustomDropdownMenu(
                        label: context.tr!.wallet,
                        options: state.wallets
                            .map(
                              (WalletModel wallet) => CustomDropdownMenuOption(
                                id: wallet.id,
                                name: wallet.name,
                                subtitle: wallet.type.toTrans(context),
                                trailingText: wallet.balanceMoney.format(),
                                icon: wallet.type.icon,
                                color: wallet.type.color,
                              ),
                            )
                            .toList(),
                        selectedId: state.walletId,
                        errorText: state.errors['wallet_id'],
                        onSelect: (dynamic id) {
                          context.read<TransactionFormCubit>().setData(
                            walletId: id,
                          );
                        },
                      ),
                      if (state.type == TransactionType.transfer)
                        Builder(
                          builder: (context) {
                            final currentWallet = state.wallets.firstWhere(
                              (w) => w.id == state.walletId,
                              orElse: () => state.wallets.first,
                            );
                            final eligibleWallets = state.wallets
                                .where(
                                  (WalletModel wallet) =>
                                      wallet.id != state.walletId &&
                                      wallet.currency == currentWallet.currency,
                                )
                                .toList();

                            if (eligibleWallets.isEmpty) {
                              return CustomDropdownTile(
                                label: context.tr!.no_eligible_wallet_for_transfer,
                                icon: AppIcons.wallets,
                                color: context.colors.disabled,
                                onTap: null,
                              );
                            }

                            return CustomDropdownMenu(
                              label: context.tr!.to_wallet,
                              options: eligibleWallets
                                  .map(
                                    (WalletModel wallet) =>
                                        CustomDropdownMenuOption(
                                          id: wallet.id,
                                          name: wallet.name,
                                          subtitle: wallet.type.toTrans(context),
                                          trailingText: wallet.balanceMoney
                                              .format(),
                                          icon: wallet.type.icon,
                                          color: wallet.type.color,
                                        ),
                                  )
                                  .toList(),
                              selectedId: state.toWalletId,
                              errorText: state.errors['to_wallet_id'],
                              onSelect: (dynamic id) {
                                context.read<TransactionFormCubit>().setData(
                                  toWalletId: id,
                                );
                              },
                            );
                          },
                        ),
                      CustomDateTimePicker(
                        label: context.tr!.transaction_date,
                        dateTime: state.date,
                        errorText: state.errors['date'],
                        lastDate: DateTime.now(),
                        onPicked: (DateTime dateTime) => context
                            .read<TransactionFormCubit>()
                            .setData(date: dateTime),
                      ),
                      if (state.type != TransactionType.transfer)
                        ContactPicker(
                          selectedContact: state.contact,
                          errorText: state.errors['contact'],
                          onPicked: (ContactModel contact) => context
                              .read<TransactionFormCubit>()
                              .setData(contactId: contact.id, contact: contact),
                        ),
                      Builder(
                        builder: (context) {
                          final selectedCategory = state.categories
                              .where((c) => c.id == state.categoryId)
                              .firstOrNull;
                          final isBorrowedDebt = state.type == TransactionType.debts &&
                              selectedCategory?.identifier ==
                                  'receiving_debts_and_installments';
                          if (!isBorrowedDebt) return const SizedBox.shrink();

                          return AnimatedBuilder(
                            animation: Listenable.merge(
                              [_amountController, _interestController],
                            ),
                            builder: (context, _) {
                              final amount =
                                  double.tryParse(_amountController.text) ?? 0;
                              final rate =
                                  double.tryParse(_interestController.text) ?? 0;
                              final interest = amount * (rate / 100);
                              final total = amount + interest;

                              return ContainerForm(
                                margin: EdgeInsets.only(
                                  bottom: AppDimensions.inputBottomMargin,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextFormField(
                                      label: 'Interest Rate (%)',
                                      controller: _interestController,
                                      hintText: 'e.g. 5',
                                      required: false,
                                      keyboardType: TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      paddingBottom: 0,
                                    ),
                                    if (rate > 0) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Interest: ${interest.toStringAsFixed(2)}  •  '
                                        'Total to repay: ${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (state.type == TransactionType.debts)
                        ContainerForm(
                          paddingVertical: 0,
                          paddingHorizontal: 0,
                          margin: EdgeInsets.only(
                            bottom: AppDimensions.inputBottomMargin,
                          ),
                          child: Column(
                            children: [
                              CustomDateTimePicker(
                                label: context.tr!.start_date,
                                errorText: state.errors['start_date'],
                                onlyDate: true,
                                dateTime: state.startDate,
                                margin: EdgeInsets.zero,
                                hasDivider: true,
                                onPicked: (DateTime date) => context
                                    .read<TransactionFormCubit>()
                                    .setData(startDate: date, endDate: date),
                              ),
                              CustomDateTimePicker(
                                label: context.tr!.end_date,
                                errorText: state.errors['end_date'],
                                onlyDate: true,
                                margin: EdgeInsets.zero,
                                dateTime: state.endDate,
                                firstDate: state.startDate,
                                onPicked: (DateTime date) => context
                                    .read<TransactionFormCubit>()
                                    .setData(endDate: date),
                              ),
                            ],
                          ),
                        ),
                      CustomDropdownMenu(
                        label: context.tr!.tags,
                        defaultIcon: AppIcons.tags,
                        isMultiple: true,
                        hiddenLeading: true,
                        options: state.tags
                            .map(
                              (TagModel tag) => CustomDropdownMenuOption(
                                id: tag.id,
                                name: tag.name,
                              ),
                            )
                            .toList(),
                        selectedId: state.tagIds,
                        onSelect: (dynamic ids) {
                          context.read<TransactionFormCubit>().setData(
                            tagIds: (ids as List).cast<int>(),
                          );
                        },
                      ),
                      ContainerForm(
                        paddingVertical: AppDimensions.padding,
                        child: Column(
                          children: [
                            CustomTextFormField(
                              label: context.tr!.note,
                              controller: _noteController,
                              hintText:
                                  context.tr!.transaction_note_placeholder,
                              required: false,
                              errorText: state.errors['note'],
                              keyboardType: TextInputType.multiline,
                              maxLength: 200,
                              paddingBottom: 20,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr!.no_impact_on_balance,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        context
                                            .tr!
                                            .no_impact_on_balance_description,
                                        style: TextStyle(
                                          color: context.colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: state.noImpactOnBalance,
                                    onChanged: (bool value) => context
                                        .read<TransactionFormCubit>()
                                        .setData(noImpactOnBalance: value),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.transaction == null &&
                                state.type == TransactionType.expenses) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Repeat this expense',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "You'll get a reminder each time it's due",
                                          style: TextStyle(
                                            color: context.colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: state.isRecurring,
                                      onChanged: (bool value) => context
                                          .read<TransactionFormCubit>()
                                          .setData(isRecurring: value),
                                    ),
                                  ),
                                ],
                              ),
                              if (state.isRecurring) ...[
                                const SizedBox(height: 10),
                                SegmentedButton<RecurrenceFrequency>(
                                  segments: RecurrenceFrequency.values
                                      .map(
                                        (f) => ButtonSegment(
                                          value: f,
                                          label: Text(f.label),
                                        ),
                                      )
                                      .toList(),
                                  selected: {state.recurrenceFrequency},
                                  onSelectionChanged: (selection) => context
                                      .read<TransactionFormCubit>()
                                      .setData(
                                        recurrenceFrequency: selection.first,
                                      ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _showCalculator() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.60,
      ),
      backgroundColor: context.colors.background,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (_) => CalculatorModalBottomSheet(
        defaultInput: _amountController.text,
        onPressOk: (double value) {
          _amountController.text = value.toString();
        },
      ),
    );
  }
}
