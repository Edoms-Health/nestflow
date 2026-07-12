import 'package:flutter/material.dart';
import 'package:nestflow/nestflow.dart';

/// A single action shown in the [QuickActionsGrid].
class QuickAction {
  final String label;
  final String icon;
  final Color? color;
  final GestureTapCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

/// A grid of quick-access actions for the dashboard, e.g. Add Transaction,
/// View Transactions, Wallets. Visually consistent with [MenuTile]'s
/// icon-in-rounded-box style, but laid out vertically (icon over label)
/// for a 4-across grid rather than a list row.
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: actions.map((a) => _QuickActionTile(action: a)).toList(),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? context.colors.primary;

    return GestureDetector(
      onTap: action.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgIcon(icon: action.icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
