import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nestflow/nestflow.dart';

Future<void> exportReportPdf(BuildContext context, ReportLoaded state) async {
  final transactionService = TransactionService();

  final transactions = await transactionService.getTransactionPagination(
    category: state.category,
    contact: state.contact,
    dateRange: state.dateRange,
    type: state.type,
    walletId: state.walletId,
    tagIds: state.tagIds,
    limit: 100000,
  );

  final dateFmt = DateFormat('dd MMM yyyy');
  final pdf = pw.Document();

  String filterSummary() {
    final parts = <String>[];
    if (state.dateRange != null) {
      parts.add(
          dateFmt.format(state.dateRange!.start) + ' - ' + dateFmt.format(state.dateRange!.end));
    } else {
      parts.add('All time');
    }
    if (state.type != null) parts.add(state.type!.name);
    if (state.category != null) parts.add('Category: ' + state.category!.name);
    if (state.contact != null) parts.add('Contact: ' + state.contact!.name);
    return parts.join(' | ');
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NestFlow Financial Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(filterSummary(),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: ' + DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 14),
          pw.Divider(),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ' + ctx.pageNumber.toString() + ' of ' + ctx.pagesCount.toString(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Text('Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          children: [
            _row('Total Income', state.totalIncome.format()),
            _row('Total Expenses', state.totalExpenses.format()),
            _row('Net Balance', state.netBalance.format()),
            _row('Debts Paid', state.debtsPaid.format()),
            _row('Debts Received', state.debtsReceived.format()),
            _row('Total Transferred', state.transferred.format()),
          ],
        ),
        pw.SizedBox(height: 20),
        if (state.topIncomeCategories.isNotEmpty) ...[
          pw.Text('Top Income Categories',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            children: [
              _row('Category', 'Amount', isHeader: true),
              for (final c in state.topIncomeCategories)
                _row(c.name, c.total.format()),
            ],
          ),
          pw.SizedBox(height: 14),
        ],
        if (state.topExpensesCategories.isNotEmpty) ...[
          pw.Text('Top Expense Categories',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            children: [
              _row('Category', 'Amount', isHeader: true),
              for (final c in state.topExpensesCategories)
                _row(c.name, c.total.format()),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Text('Transactions (' + transactions.length.toString() + ')',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(1.8),
            2: const pw.FlexColumnWidth(2.2),
            3: const pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(children: [
              _cell('Date', bold: true),
              _cell('Category', bold: true),
              _cell('Note', bold: true),
              _cell('Amount', bold: true, align: pw.TextAlign.right),
            ]),
            for (final t in transactions)
              pw.TableRow(children: [
                _cell(dateFmt.format(t.date)),
                _cell(t.category?.name ?? '-'),
                _cell(t.note ?? '-'),
                _cell(
                  (t.type == TransactionType.expenses ||
                          t.type == TransactionType.transfer
                      ? '-'
                      : '') +
                      t.amountMoney.format(),
                  align: pw.TextAlign.right,
                ),
              ]),
          ],
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdf.save(),
    name: 'NestFlow_Report_' + DateFormat('yyyyMMdd').format(DateTime.now()) + '.pdf',
  );
}

pw.TableRow _row(String label, String value, {bool isHeader = false}) {
  final style = isHeader
      ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
      : const pw.TextStyle();
  return pw.TableRow(children: [
    pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(label, style: style)),
    pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(value, style: style)),
  ]);
}

pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(text,
        textAlign: align,
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );
}
