import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class DashboardScreen extends StatelessWidget {
  final GestureTapCallback? goToTransactions;
  final GestureTapCallback refresh;

  const DashboardScreen({
    super.key,
    this.goToTransactions,
    required this.refresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          context.read<SharedCubit>().showDialog(
            type: AlertDialogType.error,
            title: state.type.title(
              context,
              context.tr!.dashboard,
              context.tr!.dashboard,
            ),
            message: state.type.message(
              context,
              context.tr!.dashboard,
              context.tr!.dashboard,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(AppImages.logo, width: 50),
                Text(context.tr!.app_name),
              ],
            ),
          ),
          body: state is DashboardLoaded
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(AppDimensions.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FinancialSummary(
                        balance: state.totalBalance,
                        expenses: state.totalExpenses,
                        income: state.totalIncome,
                      ),
                      const SizedBox(height: 15),
                      QuickActionsGrid(
                        actions: [
                          QuickAction(
                            label: 'Add\nTransaction',
                            icon: AppIcons.addTransaction,
                            onTap: () => _openAddTransactionMenu(context),
                          ),
                          QuickAction(
                            label: 'Transactions',
                            icon: AppIcons.transaction,
                            onTap: () =>
                                (goToTransactions ?? () {}).call(),
                          ),
                          QuickAction(
                            label: 'Business',
                            icon: AppIcons.business,
                            onTap: () => _goToBusiness(context),
                          ),
                          QuickAction(
                            label: 'Wallets',
                            icon: AppIcons.wallets,
                            onTap: () => _goToWallets(context),
                          ),
                          QuickAction(
                            label: 'Budgets',
                            icon: AppIcons.budgets,
                            onTap: () => _goToBudgets(context),
                          ),
                          QuickAction(
                            label: 'Categories',
                            icon: AppIcons.categories,
                            onTap: () => _goToCategories(context),
                          ),
                          QuickAction(
                            label: 'Recurring\nExpenses',
                            icon: AppIcons.calendar,
                            onTap: () => _goToRecurringExpenses(context),
                          ),
                          QuickAction(
                            label: 'Contacts',
                            icon: AppIcons.contacts,
                            onTap: () => _goToContacts(context),
                          ),
                          QuickAction(
                            label: 'Financials',
                            icon: AppIcons.report,
                            onTap: () => _goToFinancials(context),
                          ),
                          QuickAction(
                            label: 'Send\nMoney',
                            icon: AppIcons.expense,
                            color: TransactionType.expenses.color,
                            onTap: () => startContactTransaction(
                              context,
                              type: TransactionType.expenses,
                              refresh: refresh,
                            ),
                          ),
                          QuickAction(
                            label: 'Receive\nMoney',
                            icon: AppIcons.income,
                            color: TransactionType.income.color,
                            onTap: () => startContactTransaction(
                              context,
                              type: TransactionType.income,
                              refresh: refresh,
                            ),
                          ),
                          QuickAction(
                            label: 'Pay',
                            icon: AppIcons.expense,
                            color: TransactionType.expenses.color,
                            onTap: () => startContactTransaction(
                              context,
                              type: TransactionType.expenses,
                              refresh: refresh,
                            ),
                          ),
                        ],
                      ),
                      DashboardWeeklyChart(
                        chartData: context.isRtl
                            ? state.weeklyChartData.reversed.toList()
                            : state.weeklyChartData,
                      ),
                      RecentTransactions(
                        transactions: state.recentTransactions,
                        viewAll: goToTransactions,
                        refresh: refresh,
                      ),
                    ],
                  ),
                )
              : Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _openAddTransactionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => MenuModalBottomSheet(refresh: refresh),
    );
  }

  void _goToBusiness(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => BusinessCubit()..load(),
          child: const BusinessCashbookScreen(),
        ),
      ),
    );
  }

  void _goToWallets(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WalletPinScreen(),
      ),
    );
  }

  void _goToBudgets(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => BudgetCubit()..loadBudgets(),
          child: BudgetScreen(),
        ),
      ),
    );
  }

  void _goToRecurringExpenses(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => RecurringExpenseCubit()..loadAll(),
          child: const RecurringExpenseScreen(),
        ),
      ),
    );
  }

  void _goToCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) =>
              CategoryCubit()..loadCategories(type: TransactionType.income),
          child: CategoryScreen(),
        ),
      ),
    );
  }

  void _goToFinancials(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => FinancialCubit()..loadYear()),
            BlocProvider(create: (_) => BalanceSheetCubit()..load()),
          ],
          child: const FinancialScreen(),
        ),
      ),
    );
  }

  void _goToContacts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => ContactCubit()..loadContacts(),
          child: ContactScreen(),
        ),
      ),
    );
  }
}
