import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class BusinessOthersTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessOthersTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (loaded.others.isEmpty) {
      return Center(
        child: Text('No other entries yet — tap + to add one',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    final fmt = NumberFormat.currency(symbol: loaded.active?.currency ?? '', decimalDigits: 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.others.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final o = loaded.others[i];
        final color = o.isInflow ? Colors.green : Colors.red;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(o.isInflow ? Icons.add_circle_outline : Icons.remove_circle_outline, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${o.branch?.name ?? 'No branch'} · ${DateFormat.yMMMd().format(o.entryDate)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text('${o.isInflow ? '+' : '-'}${fmt.format(o.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<BusinessCubit>(),
                        child: OtherFormScreen(loaded: loaded, entry: o),
                      ),
                    ));
                  } else if (v == 'delete') {
                    context.read<BusinessCubit>().deleteOther(o.id);
                  }
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
