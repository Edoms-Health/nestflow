import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class BalanceSheetAccountFormScreen extends StatefulWidget {
  final BalanceSheetAccountModel? account;

  const BalanceSheetAccountFormScreen({super.key, this.account});

  @override
  State<BalanceSheetAccountFormScreen> createState() =>
      _BalanceSheetAccountFormScreenState();
}

class _BalanceSheetAccountFormScreenState
    extends State<BalanceSheetAccountFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BalanceSheetCubit>().formInit(account: widget.account);
    _nameController.text = widget.account?.name ?? '';
    _amountController.text = widget.account?.amount.toString() ?? '';
    _noteController.text = widget.account?.note ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _typeLabel(BalanceSheetAccountType type) {
    switch (type) {
      case BalanceSheetAccountType.asset:
        return 'Asset';
      case BalanceSheetAccountType.liability:
        return 'Liability';
      case BalanceSheetAccountType.equity:
        return 'Equity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceSheetCubit, BalanceSheetState>(
      buildWhen: (previous, current) =>
          current.runtimeType == BalanceSheetFormInitial,
      builder: (context, state) {
        if (state is BalanceSheetFormInitial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.account != null
                    ? context.tr!.edit_resource('Account')
                    : context.tr!.create_resource('Account'),
              ),
            ),
            bottomNavigationBar: FormBottomNavigationBar(
              okButtonOnPressed: () async {
                if (await context.read<BalanceSheetCubit>().submit(
                  {
                    'name_is_required': context.tr!.attribute_is_required(
                      context.tr!.name,
                    ),
                    'amount_must_be_greater_than':
                        'Amount must be zero or greater',
                  },
                  widget.account,
                  _nameController.text,
                  double.tryParse(_amountController.text.trim()),
                  _noteController.text.trim().isEmpty
                      ? null
                      : _noteController.text.trim(),
                )) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              okButtonLoading: false,
              okButtonText: widget.account == null
                  ? context.tr!.create
                  : context.tr!.update,
            ),
            body: Column(
              children: [
                ContainerForm(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      CustomTextFormField(
                        label: context.tr!.name,
                        controller: _nameController,
                        hintText: 'e.g. Cash at Bank',
                        errorText: state.errors['name'],
                        maxLength: 50,
                      ),
                    ],
                  ),
                ),
                ContainerForm(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SegmentedButton<BalanceSheetAccountType>(
                          segments: BalanceSheetAccountType.values
                              .map(
                                (t) => ButtonSegment(
                                  value: t,
                                  label: Text(_typeLabel(t)),
                                ),
                              )
                              .toList(),
                          selected: {state.type},
                          onSelectionChanged: (selection) => context
                              .read<BalanceSheetCubit>()
                              .setType(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
                ContainerForm(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      CustomTextFormField(
                        label: 'Amount',
                        controller: _amountController,
                        hintText: '0.00',
                        errorText: state.errors['amount'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                ),
                ContainerForm(
                  child: CustomTextFormField(
                    label: context.tr!.note,
                    controller: _noteController,
                    hintText: '',
                    required: false,
                    maxLength: 100,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
