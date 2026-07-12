import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class BusinessReportsTab extends StatefulWidget {
  final BusinessLoaded loaded;
  const BusinessReportsTab({super.key, required this.loaded});

  @override
  State<BusinessReportsTab> createState() => _BusinessReportsTabState();
}

class _BusinessReportsTabState extends State<BusinessReportsTab> {
  bool _isDaily = true;
  DateTime _selectedDate = DateTime.now();

  DateTime get _start => _isDaily
      ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
      : DateTime(_selectedDate.year, _selectedDate.month, 1);

  DateTime get _end => _isDaily
      ? _start.add(const Duration(days: 1))
      : DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

  bool _inRange(DateTime d) => !d.isBefore(_start) && d.isBefore(_end);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat.currency(symbol: widget.loaded.active?.currency ?? '', decimalDigits: 0);
    final entryFmt = NumberFormat('#,##0');
    final branches = widget.loaded.branches;

    final sales = widget.loaded.sales.where((s) => _inRange(s.saleDate)).toList();
    final expenses = widget.loaded.cashbookExpenses.where((e) => _inRange(e.expenseDate)).toList();
    final others = widget.loaded.others.where((o) => _inRange(o.entryDate)).toList();

    final totalSales = sales.fold<double>(0, (s, x) => s + x.amount);
    final totalExpenses = expenses.fold<double>(0, (s, x) => s + x.amount);
    final totalOthers = others.fold<double>(0, (s, x) => s + (x.isInflow ? x.amount : -x.amount));
    final netProfit = totalSales - totalExpenses + totalOthers;

    final report = BusinessReportModel(
      totalSales: totalSales, totalExpenses: totalExpenses,
      totalOthers: totalOthers, netProfit: netProfit,
    );

    // ── Group everything by branch ──────────────────────────────
    final Map<int?, List<BusinessSaleModel>> salesByBranch = {};
    for (final s in sales) { (salesByBranch[s.branchId] ??= []).add(s); }
    final Map<int?, List<CashbookExpenseModel>> expensesByBranch = {};
    for (final e in expenses) { (expensesByBranch[e.branchId] ??= []).add(e); }
    final Map<int?, List<BusinessOtherModel>> othersByBranch = {};
    for (final o in others) { (othersByBranch[o.branchId] ??= []).add(o); }

    final branchKeys = <int?>{...salesByBranch.keys, ...expensesByBranch.keys, ...othersByBranch.keys};
    final orderedKeys = <int?>[
      for (final b in branches) if (branchKeys.contains(b.id)) b.id,
      if (branchKeys.contains(null)) null,
    ];

    String branchName(int? id) {
      if (id == null) return 'Unassigned';
      final match = branches.where((b) => b.id == id);
      return match.isNotEmpty ? match.first.name : 'Unknown branch';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Daily')),
            ButtonSegment(value: false, label: Text('Monthly')),
          ],
          selected: {_isDaily},
          onSelectionChanged: (s) => setState(() => _isDaily = s.first),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(_isDaily
              ? DateFormat.yMMMd().format(_selectedDate)
              : DateFormat.yMMM().format(_selectedDate)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context, initialDate: _selectedDate,
              firstDate: DateTime(2020), lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => exportBusinessReportPdf(
              context,
              loaded: widget.loaded,
              report: report,
              isDaily: _isDaily,
              selectedDate: _selectedDate,
              branchId: null,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Download PDF'),
          ),
        ),
        const SizedBox(height: 8),
        _ReportCard(label: 'Total Sales', value: fmt.format(totalSales), color: Colors.green),
        const SizedBox(height: 12),
        _ReportCard(label: 'Total Expenses', value: fmt.format(totalExpenses), color: Colors.red),
        const SizedBox(height: 12),
        _ReportCard(
          label: 'Net Profit',
          value: fmt.format(netProfit),
          color: netProfit >= 0 ? colors.primary : Colors.red,
          bold: true,
        ),
        const SizedBox(height: 24),
        Text('By Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
        const SizedBox(height: 10),
        if (orderedKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No entries for this period', style: TextStyle(color: colors.textSecondary))),
          )
        else
          ...orderedKeys.map((key) {
            final bSales = salesByBranch[key] ?? const <BusinessSaleModel>[];
            final bExpenses = expensesByBranch[key] ?? const <CashbookExpenseModel>[];
            final bOthers = othersByBranch[key] ?? const <BusinessOtherModel>[];
            final bSalesTotal = bSales.fold<double>(0, (s, x) => s + x.amount);
            final bExpensesTotal = bExpenses.fold<double>(0, (s, x) => s + x.amount);
            final bOthersTotal = bOthers.fold<double>(0, (s, x) => s + (x.isInflow ? x.amount : -x.amount));
            final bNet = bSalesTotal - bExpensesTotal + bOthersTotal;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  trailing: key == null
                      ? const SizedBox(width: 24)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                              tooltip: 'Download PDF',
                              onPressed: () {
                                final branchMatch = branches.where((b) => b.id == key);
                                if (branchMatch.isEmpty) return;
                                exportBranchReportPdf(
                                  context,
                                  loaded: widget.loaded,
                                  branch: branchMatch.first,
                                  isDaily: _isDaily,
                                  selectedDate: _selectedDate,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.table_chart_outlined, size: 20),
                              tooltip: 'Download Excel',
                              onPressed: () {
                                final branchMatch = branches.where((b) => b.id == key);
                                if (branchMatch.isEmpty) return;
                                exportBranchReportExcel(
                                  context,
                                  loaded: widget.loaded,
                                  branch: branchMatch.first,
                                  isDaily: _isDaily,
                                  selectedDate: _selectedDate,
                                );
                              },
                            ),
                          ],
                        ),
                  title: Text(branchName(key), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Sales ${fmt.format(bSalesTotal)}  •  Expenses ${fmt.format(bExpensesTotal)}  •  Net ${fmt.format(bNet)}',
                    style: TextStyle(fontSize: 11, color: bNet >= 0 ? colors.textSecondary : Colors.red),
                  ),
                  children: [
                    if (bSales.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('Sales', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textSecondary)),
                      ),
                      ...bSales.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.description, style: const TextStyle(fontSize: 13)),
                              Text(DateFormat.yMMMd().format(s.saleDate), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                            ],
                          )),
                          Text('+${entryFmt.format(s.amount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      )),
                    ],
                    if (bExpenses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textSecondary)),
                      ),
                      ...bExpenses.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.description} (${e.category})', style: const TextStyle(fontSize: 13)),
                              Text(DateFormat.yMMMd().format(e.expenseDate), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                            ],
                          )),
                          Text('-${entryFmt.format(e.amount)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      )),
                    ],
                    if (bOthers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('Other Entries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textSecondary)),
                      ),
                      ...bOthers.map((o) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.description, style: const TextStyle(fontSize: 13)),
                              Text(DateFormat.yMMMd().format(o.entryDate), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                            ],
                          )),
                          Text('${o.isInflow ? '+' : '-'}${entryFmt.format(o.amount)}',
                              style: TextStyle(color: o.isInflow ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      )),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _ReportCard({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: bold ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: bold ? 18 : 16)),
        ],
      ),
    );
  }
}
