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
}
