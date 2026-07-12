import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nestflow/nestflow.dart';

Future<void> exportBusinessReportPdf(
  BuildContext context, {
  required BusinessLoaded loaded,
  required BusinessReportModel report,
  required bool isDaily,
  required DateTime selectedDate,
  int? branchId,
}) async {
  final dateFmt = DateFormat('dd MMM yyyy');
  final pdf = pw.Document();

  final branchName = branchId == null
      ? 'All branches'
      : loaded.branches.firstWhere((b) => b.id == branchId).name;

  DateTime start, end;
  String periodLabel;
  if (isDaily) {
    start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    end = start.add(const Duration(days: 1));
    periodLabel = dateFmt.format(selectedDate);
  } else {
    start = DateTime(selectedDate.year, selectedDate.month, 1);
    end = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    periodLabel = DateFormat('MMMM yyyy').format(selectedDate);
  }

  bool inRange(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  bool matchesBranch(int? entryBranchId) => branchId == null || entryBranchId == branchId;

  final sales = loaded.sales.where((s) => inRange(s.saleDate) && matchesBranch(s.branchId)).toList();
  final expenses = loaded.cashbookExpenses.where((e) => inRange(e.expenseDate) && matchesBranch(e.branchId)).toList();
  final others = loaded.others.where((o) => inRange(o.entryDate) && matchesBranch(o.branchId)).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${loaded.active?.name ?? 'Business'} — Cashbook Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('${isDaily ? 'Daily' : 'Monthly'} Report — $periodLabel  |  $branchName',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 14),
          pw.Divider(),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          children: [
            _row('Total Sales', report.totalSales.toStringAsFixed(0)),
            _row('Total Expenses', report.totalExpenses.toStringAsFixed(0)),
            _row('Other Entries (net)', report.totalOthers.toStringAsFixed(0)),
            _row('Net Balance', report.netProfit.toStringAsFixed(0), isHeader: true),
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Text('Sales (${sales.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
          children: [
            pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
            for (final s in sales)
              pw.TableRow(children: [
                _cell(dateFmt.format(s.saleDate)),
                _cell(s.description),
                _cell(s.amount.toStringAsFixed(0), align: pw.TextAlign.right),
              ]),
          ],
        ),
        pw.SizedBox(height: 14),

        pw.Text('Expenses (${expenses.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
          children: [
            pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
            for (final e in expenses)
              pw.TableRow(children: [
                _cell(dateFmt.format(e.expenseDate)),
                _cell(e.description),
                _cell(e.amount.toStringAsFixed(0), align: pw.TextAlign.right),
              ]),
          ],
        ),
        pw.SizedBox(height: 14),

        if (others.isNotEmpty) ...[
          pw.Text('Other Entries (${others.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
            children: [
              pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
              for (final o in others)
                pw.TableRow(children: [
                  _cell(dateFmt.format(o.entryDate)),
                  _cell(o.description),
                  _cell('${o.isInflow ? '+' : '-'}${o.amount.toStringAsFixed(0)}', align: pw.TextAlign.right),
                ]),
            ],
          ),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdf.save(),
    name: '${loaded.active?.name ?? 'Business'}_Cashbook_${DateFormat('yyyyMMdd').format(selectedDate)}.pdf',
  );
}

Future<void> exportBranchReportPdf(
  BuildContext context, {
  required BusinessLoaded loaded,
  required BranchModel branch,
  required bool isDaily,
  required DateTime selectedDate,
}) async {
  final dateFmt = DateFormat('dd MMM yyyy');
  final pdf = pw.Document();

  DateTime start, end;
  String periodLabel;
  if (isDaily) {
    start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    end = start.add(const Duration(days: 1));
    periodLabel = dateFmt.format(selectedDate);
  } else {
    start = DateTime(selectedDate.year, selectedDate.month, 1);
    end = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    periodLabel = DateFormat('MMMM yyyy').format(selectedDate);
  }

  bool inRange(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  bool matchesBranch(int? entryBranchId) => entryBranchId == branch.id;

  final sales = loaded.sales.where((s) => inRange(s.saleDate) && matchesBranch(s.branchId)).toList();
  final expenses = loaded.cashbookExpenses.where((e) => inRange(e.expenseDate) && matchesBranch(e.branchId)).toList();
  final others = loaded.others.where((o) => inRange(o.entryDate) && matchesBranch(o.branchId)).toList();

  final totalSales = sales.fold<double>(0, (s, x) => s + x.amount);
  final totalExpenses = expenses.fold<double>(0, (s, x) => s + x.amount);
  final totalOthers = others.fold<double>(0, (s, x) => s + (x.isInflow ? x.amount : -x.amount));
  final netProfit = totalSales - totalExpenses + totalOthers;

  final contactLines = <String>[
    if (branch.location != null) branch.location!,
    if (branch.phone != null) 'Tel: ${branch.phone}',
    if (branch.email != null) branch.email!,
    if (branch.managerName != null) 'Manager: ${branch.managerName}',
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(branch.name,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(loaded.active?.name ?? 'Business',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
              if (branch.isMain)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('MAIN BRANCH', style: const pw.TextStyle(fontSize: 9)),
                ),
            ],
          ),
          if (contactLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(contactLines.join('  •  '),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 6),
          pw.Text('${isDaily ? 'Daily' : 'Monthly'} Branch Report — $periodLabel',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 14),
          pw.Divider(),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          children: [
            _row('Total Sales', totalSales.toStringAsFixed(0)),
            _row('Total Expenses', totalExpenses.toStringAsFixed(0)),
            _row('Other Entries (net)', totalOthers.toStringAsFixed(0)),
            _row('Net Balance', netProfit.toStringAsFixed(0), isHeader: true),
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Text('Sales (${sales.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
          children: [
            pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
            for (final s in sales)
              pw.TableRow(children: [
                _cell(dateFmt.format(s.saleDate)),
                _cell(s.description),
                _cell(s.amount.toStringAsFixed(0), align: pw.TextAlign.right),
              ]),
          ],
        ),
        pw.SizedBox(height: 14),

        pw.Text('Expenses (${expenses.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
          children: [
            pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
            for (final e in expenses)
              pw.TableRow(children: [
                _cell(dateFmt.format(e.expenseDate)),
                _cell('${e.description} (${e.category})'),
                _cell(e.amount.toStringAsFixed(0), align: pw.TextAlign.right),
              ]),
          ],
        ),
        pw.SizedBox(height: 14),

        if (others.isNotEmpty) ...[
          pw.Text('Other Entries (${others.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            columnWidths: {0: const pw.FlexColumnWidth(1.3), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.4)},
            children: [
              pw.TableRow(children: [_cell('Date', bold: true), _cell('Description', bold: true), _cell('Amount', bold: true, align: pw.TextAlign.right)]),
              for (final o in others)
                pw.TableRow(children: [
                  _cell(dateFmt.format(o.entryDate)),
                  _cell(o.description),
                  _cell('${o.isInflow ? '+' : '-'}${o.amount.toStringAsFixed(0)}', align: pw.TextAlign.right),
                ]),
            ],
          ),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdf.save(),
    name: '${branch.name}_Report_${DateFormat('yyyyMMdd').format(selectedDate)}.pdf',
  );
}

pw.TableRow _row(String label, String value, {bool isHeader = false}) {
  final style = isHeader ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle();
  return pw.TableRow(children: [
    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label, style: style)),
    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value, style: style)),
  ]);
}

pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(text, textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );
}
