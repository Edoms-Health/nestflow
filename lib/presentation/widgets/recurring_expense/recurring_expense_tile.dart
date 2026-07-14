import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class RecurringExpenseTile extends StatelessWidget {
  final RecurringExpenseModel item;
  final Function(RecurringExpenseModel item) onPressedEdit;
  final Function(RecurringExpenseModel item) onPressedDelete;

  const RecurringExpenseTile({
    super.key,
    required this.item,
    required this.onPressedEdit,
    required this.onPressedDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      tileColor: context.colors.surface,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.repeat, color: context.colors.primary, size: 20),
      ),
      title: Text(
        item.amountMoney.format(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${item.category?.name ?? '\u2014'} \u2022 ${item.wallet?.name ?? '\u2014'} \u2022 '
        '${item.frequency.label}, next ${DateFormat.yMMMd().format(item.nextDueDate)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onPressedEdit(item),
            child: SvgIcon(
              icon: AppIcons.edit,
              width: 15,
              color: context.colors.success.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onPressedDelete(item),
            child: SvgIcon(
              icon: AppIcons.delete,
              width: 15,
              color: context.colors.error.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
