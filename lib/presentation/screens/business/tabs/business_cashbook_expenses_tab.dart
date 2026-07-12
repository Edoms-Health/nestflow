import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class CashbookExpensesTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const CashbookExpensesTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (loaded.cashbookExpenses.isEmpty) {
      return Center(
        child: Text('No expenses recorded yet — tap + to add one',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    final fmt = NumberFormat.currency(symbol: loaded.active?.currency ?? '', decimalDigits: 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.cashbookExpenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = loaded.cashbookExpenses[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: colors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${e.branch?.name ?? 'Unassigned'} • ${e.category} • ${DateFormat.yMMMd().format(e.expenseDate)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(fmt.format(e.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.error)),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<BusinessCubit>(),
                        child: CashbookExpenseFormScreen(loaded: loaded, expense: e),
                      ),
                    ));
                  }
                  if (v == 'delete') context.read<BusinessCubit>().deleteCashbookExpense(e.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
