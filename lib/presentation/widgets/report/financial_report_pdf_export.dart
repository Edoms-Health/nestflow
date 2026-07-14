import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

Future<void> exportProfitLossPdf(
  BuildContext context, {
  required FinancialLoaded state,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Profit & Loss Statement',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Year ${state.year}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (ctx) => [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          children: [
            _row('Annual Revenue', state.annualIncome.toStringAsFixed(0)),
            _row('Annual Expense', state.annualExpense.toStringAsFixed(0)),
            _row(
              state.annualProfit >= 0 ? 'Net Profit' : 'Net Loss',
              state.annualProfit.toStringAsFixed(0),
              isHeader: true,
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Text(
          'Monthly Breakdown',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.6),
            1: const pw.FlexColumnWidth(1.3),
            2: const pw.FlexColumnWidth(1.3),
            3: const pw.FlexColumnWidth(1.3),
          },
          children: [
            pw.TableRow(
              children: [
                _cell('Month', bold: true),
                _cell('Income', bold: true, align: pw.TextAlign.right),
                _cell('Expense', bold: true, align: pw.TextAlign.right),
                _cell('Profit / Loss', bold: true, align: pw.TextAlign.right),
              ],
            ),
            for (var m = 1; m <= 12; m++)
              pw.TableRow(
                children: [
                  _cell(_kMonthNames[m - 1]),
                  _cell(
                    (state.entriesByMonth[m]?.income ?? 0).toStringAsFixed(0),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    (state.entriesByMonth[m]?.expense ?? 0).toStringAsFixed(0),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    (state.entriesByMonth[m]?.profit ?? 0).toStringAsFixed(0),
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdf.save(),
    name: 'Profit_Loss_${state.year}.pdf',
  );
}

Future<void> exportBalanceSheetPdf(
  BuildContext context, {
  required BalanceSheetLoaded state,
}) async {
  final pdf = pw.Document();

  pw.Widget accountTable(String title, List<BalanceSheetAccountModel> accounts, double total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.3),
          },
          children: [
            pw.TableRow(
              children: [
                _cell('Account', bold: true),
                _cell('Amount', bold: true, align: pw.TextAlign.right),
              ],
            ),
            for (final a in accounts)
              pw.TableRow(
                children: [
                  _cell(a.name),
                  _cell(a.amount.toStringAsFixed(0), align: pw.TextAlign.right),
                ],
              ),
            pw.TableRow(
              children: [
                _cell('Total $title', bold: true),
                _cell(total.toStringAsFixed(0), bold: true, align: pw.TextAlign.right),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Balance Sheet',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (ctx) => [
        accountTable('Assets', state.assets, state.totalAssets),
        accountTable('Liabilities', state.liabilities, state.totalLiabilities),
        accountTable('Equity', state.equity, state.totalEquity),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Text(
          state.isBalanced
              ? 'Balanced: Assets = Liabilities + Equity'
              : 'Not balanced: Assets does not equal Liabilities + Equity',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: state.isBalanced ? PdfColors.green700 : PdfColors.red700,
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => pdf.save(),
    name: 'Balance_Sheet_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
  );
}

pw.TableRow _row(String label, String value, {bool isHeader = false}) {
  final style = isHeader
      ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
      : const pw.TextStyle();
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(label, style: style),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(value, style: style),
      ),
    ],
  );
}

pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}
