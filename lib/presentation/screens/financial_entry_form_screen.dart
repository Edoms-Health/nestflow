import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class FinancialEntryFormScreen extends StatefulWidget {
  final int year;
  final int month;
  final MonthlyFinancialModel? entry;

  const FinancialEntryFormScreen({
    super.key,
    required this.year,
    required this.month,
    this.entry,
  });

  @override
  State<FinancialEntryFormScreen> createState() =>
      _FinancialEntryFormScreenState();
}

class _FinancialEntryFormScreenState extends State<FinancialEntryFormScreen> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FinancialCubit>().formInit(
      year: widget.year,
      month: widget.month,
      entry: widget.entry,
    );
    _incomeController.text = widget.entry?.income.toString() ?? '';
    _expenseController.text = widget.entry?.expense.toString() ?? '';
    _noteController.text = widget.entry?.note ?? '';
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancialCubit, FinancialState>(
      buildWhen: (previous, current) =>
          current.runtimeType == FinancialFormInitial,
      builder: (context, state) {
        if (state is FinancialFormInitial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '${_kMonthNames[state.month - 1]} ${state.year}',
              ),
            ),
            bottomNavigationBar: FormBottomNavigationBar(
              okButtonOnPressed: () async {
                if (await context.read<FinancialCubit>().submit(
                  {
                    'amount_must_be_greater_than':
                        'Amount must be zero or greater',
                  },
                  double.tryParse(_incomeController.text.trim()),
                  double.tryParse(_expenseController.text.trim()),
                  _noteController.text.trim().isEmpty
                      ? null
                      : _noteController.text.trim(),
                )) {
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                }
              },
              okButtonLoading: false,
              okButtonText: widget.entry == null
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
                        label: 'Income',
                        controller: _incomeController,
                        hintText: '0.00',
                        errorText: state.errors['income'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
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
                        label: 'Expense',
                        controller: _expenseController,
                        hintText: '0.00',
                        errorText: state.errors['expense'],
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
