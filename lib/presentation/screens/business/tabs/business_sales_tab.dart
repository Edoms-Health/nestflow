import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class BusinessSalesTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessSalesTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (loaded.sales.isEmpty) {
      return Center(
        child: Text('No sales recorded yet — tap + to add one',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    final fmt = NumberFormat.currency(symbol: loaded.active?.currency ?? '', decimalDigits: 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = loaded.sales[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.point_of_sale_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${s.branch?.name ?? 'No branch'} · ${DateFormat.yMMMd().format(s.saleDate)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(fmt.format(s.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<BusinessCubit>(),
                        child: SaleFormScreen(loaded: loaded, sale: s),
                      ),
                    ));
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Sale'),
                        content: Text('Delete "${s.description}"? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<BusinessCubit>().deleteSale(s.id);
                            },
                            child: Text('Delete', style: TextStyle(color: colors.error)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => const [
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
