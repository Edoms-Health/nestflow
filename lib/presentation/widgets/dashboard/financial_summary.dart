import 'package:flutter/material.dart';
import 'package:nestflow/nestflow.dart';

class FinancialSummary extends StatefulWidget {
  final Money balance;
  final Money income;
  final Money expenses;
  const FinancialSummary({
    super.key,
    required this.balance,
    required this.expenses,
    required this.income,
  });

  @override
  State<FinancialSummary> createState() => _FinancialSummaryState();
}

class _FinancialSummaryState extends State<FinancialSummary> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenPref();
  }

  Future<void> _loadHiddenPref() async {
    final hidden = await _prefs.getBalanceHidden();
    if (mounted) setState(() => _hidden = hidden);
  }

  void _toggleHidden() {
    setState(() => _hidden = !_hidden);
    _prefs.saveBalanceHidden(_hidden);
  }

  String _mask(String formatted) {
    // Replace every digit with '•' while keeping currency symbols/separators intact
    return formatted.replaceAll(RegExp(r'\d'), '•');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr!.total_balance,
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      Text(
                        _hidden ? _mask(widget.balance.format()) : widget.balance.format(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleHidden,
                        child: Icon(
                          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletPinScreen(),
                  ),
                ),
                icon: SvgIcon(icon: AppIcons.wallets, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DashboardFinancialSummaryTypeTile(
                type: TransactionType.income,
                icon: Icons.arrow_downward_outlined,
                total: widget.income,
                hidden: _hidden,
              ),
              DashboardFinancialSummaryTypeTile(
                type: TransactionType.expenses,
                icon: Icons.arrow_upward_outlined,
                total: widget.expenses,
                hidden: _hidden,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardFinancialSummaryTypeTile extends StatelessWidget {
  final TransactionType type;
  final IconData icon;
  final Money total;
  final bool hidden;
  const DashboardFinancialSummaryTypeTile({
    super.key,
    required this.type,
    required this.icon,
    required this.total,
    this.hidden = false,
  });

  String _mask(String formatted) {
    return formatted.replaceAll(RegExp(r'\d'), '•');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: type.color, size: 16),
        ),
        SizedBox(width: 6),
        Column(
          children: [
            Text(
              type.toTrans(context),
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            Text(
              hidden ? _mask(total.format()) : total.format(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
