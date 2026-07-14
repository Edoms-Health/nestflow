import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

const List<String> _kMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financials'),
          actions: [
            Builder(
              builder: (context) => PopupMenuButton<String>(
                icon: const Icon(Icons.ios_share),
                onSelected: (value) async {
                  switch (value) {
                    case 'pl_pdf':
                      final state = context.read<FinancialCubit>().state;
                      if (state is FinancialLoaded) {
                        await exportProfitLossPdf(context, state: state);
                      }
                      break;
                    case 'pl_excel':
                      final state = context.read<FinancialCubit>().state;
                      if (state is FinancialLoaded) {
                        await exportProfitLossExcel(context, state: state);
                      }
                      break;
                    case 'bs_pdf':
                      final state = context.read<BalanceSheetCubit>().state;
                      if (state is BalanceSheetLoaded) {
                        await exportBalanceSheetPdf(context, state: state);
                      }
                      break;
                    case 'bs_excel':
                      final state = context.read<BalanceSheetCubit>().state;
                      if (state is BalanceSheetLoaded) {
                        await exportBalanceSheetExcel(context, state: state);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'pl_pdf', child: Text('Export P&L (PDF)')),
                  PopupMenuItem(value: 'pl_excel', child: Text('Export P&L (Excel)')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'bs_pdf', child: Text('Export Balance Sheet (PDF)')),
                  PopupMenuItem(value: 'bs_excel', child: Text('Export Balance Sheet (Excel)')),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profit & Loss'),
              Tab(text: 'Balance Sheet'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProfitLossTab(),
            _BalanceSheetTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfitLossTab extends StatelessWidget {
  const _ProfitLossTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinancialCubit, FinancialState>(
      listener: (context, state) {
        if (state is FinancialError) {
          context.read<SharedCubit>().showDialog(
            type: AlertDialogType.error,
            title: 'Error',
            message: 'Something went wrong. Please try again.',
          );
        }
      },
      buildWhen: (previous, current) =>
          [FinancialLoaded, FinancialLoading, FinancialError]
              .any((type) => current.runtimeType == type),
      builder: (context, state) {
        if (state is! FinancialLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _YearSelector(
                year: state.year,
                availableYears: state.availableYears,
                onChanged: (y) => context.read<FinancialCubit>().loadYear(y),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Annual Revenue',
                      value: state.annualIncome,
                      color: context.colors.success,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Annual Expense',
                      value: state.annualExpense,
                      color: context.colors.error,
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: state.annualProfit >= 0
                          ? 'Net Profit'
                          : 'Net Loss',
                      value: state.annualProfit,
                      color: state.annualProfit >= 0
                          ? context.colors.success
                          : context.colors.error,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ...List.generate(12, (i) {
                final month = i + 1;
                final entry = state.entriesByMonth[month];
                return _MonthTile(
                  year: state.year,
                  month: month,
                  entry: entry,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final List<int> availableYears;
  final ValueChanged<int> onChanged;

  const _YearSelector({
    required this.year,
    required this.availableYears,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final years = {...availableYears, year}.toList()
      ..sort((a, b) => b.compareTo(a));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => onChanged(year - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        DropdownButton<int>(
          value: year,
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
          onChanged: (y) {
            if (y != null) onChanged(y);
          },
        ),
        IconButton(
          onPressed: () => onChanged(year + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Money.inDefaultCurrency(value).format(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MonthTile extends StatelessWidget {
  final int year;
  final int month;
  final MonthlyFinancialModel? entry;

  const _MonthTile({required this.year, required this.month, this.entry});

  @override
  Widget build(BuildContext context) {
    final income = entry?.income ?? 0;
    final expense = entry?.expense ?? 0;
    final profit = income - expense;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<FinancialCubit>(),
              child: FinancialEntryFormScreen(
                year: year,
                month: month,
                entry: entry,
              ),
            ),
          ),
        );
        if (result == true && context.mounted) {
          context.read<FinancialCubit>().loadYear(year);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_kMonthShort[month - 1]} $year',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (entry == null)
              Text(
                'Not set',
                style: TextStyle(color: context.colors.textSecondary),
              )
            else
              Text(
                Money.inDefaultCurrency(profit).format(),
                style: TextStyle(
                  color: profit >= 0
                      ? context.colors.success
                      : context.colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSheetTab extends StatelessWidget {
  const _BalanceSheetTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BalanceSheetCubit, BalanceSheetState>(
      listener: (context, state) {
        if (state is BalanceSheetError) {
          context.read<SharedCubit>().showDialog(
            type: AlertDialogType.error,
            title: 'Error',
            message: 'Something went wrong. Please try again.',
          );
        }
      },
      buildWhen: (previous, current) =>
          [BalanceSheetLoaded, BalanceSheetLoading, BalanceSheetError]
              .any((type) => current.runtimeType == type),
      builder: (context, state) {
        if (state is! BalanceSheetLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openForm(context),
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: state.isBalanced
                        ? context.colors.success.withValues(alpha: 0.1)
                        : context.colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isBalanced
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: state.isBalanced
                            ? context.colors.success
                            : context.colors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.isBalanced
                              ? 'Balanced: Assets = Liabilities + Equity'
                              : 'Not balanced: Assets \u2260 Liabilities + Equity',
                          style: TextStyle(
                            color: state.isBalanced
                                ? context.colors.success
                                : context.colors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _AccountSection(
                  title: 'Assets',
                  total: state.totalAssets,
                  accounts: state.assets,
                ),
                const SizedBox(height: 20),
                _AccountSection(
                  title: 'Liabilities',
                  total: state.totalLiabilities,
                  accounts: state.liabilities,
                ),
                const SizedBox(height: 20),
                _AccountSection(
                  title: 'Equity',
                  total: state.totalEquity,
                  accounts: state.equity,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {BalanceSheetAccountModel? account}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BalanceSheetCubit>(),
          child: BalanceSheetAccountFormScreen(account: account),
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final String title;
  final double total;
  final List<BalanceSheetAccountModel> accounts;

  const _AccountSection({
    required this.title,
    required this.total,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              Money.inDefaultCurrency(total).format(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No $title added yet.',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          )
        else
          ...accounts.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<BalanceSheetCubit>(),
                          child: BalanceSheetAccountFormScreen(account: a),
                        ),
                      ),
                    ),
                    child: Text(a.name),
                  ),
                  Row(
                    children: [
                      Text(Money.inDefaultCurrency(a.amount).format()),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context
                            .read<BalanceSheetCubit>()
                            .deleteAccount(a),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: context.colors.error.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
