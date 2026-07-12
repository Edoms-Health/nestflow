import 'dart:io';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportReportExcel(BuildContext context, ReportLoaded state) async {
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

  String filterSummary() {
    final parts = <String>[];
    if (state.dateRange != null) {
      parts.add(
          '${dateFmt.format(state.dateRange!.start)} - ${dateFmt.format(state.dateRange!.end)}');
    } else {
      parts.add('All time');
    }
    if (state.type != null) parts.add(state.type!.name);
    if (state.category != null) parts.add('Category: ${state.category!.name}');
    if (state.contact != null) parts.add('Contact: ${state.contact!.name}');
    return parts.join(' | ');
  }

  final excel = Excel.createExcel();
  final defaultSheetName = excel.getDefaultSheet();

  final summary = excel['Summary'];
  summary.updateCell(CellIndex.indexByString('A1'), TextCellValue('NestFlow Financial Report'));
  summary.updateCell(CellIndex.indexByString('A2'), TextCellValue(filterSummary()));
  summary.updateCell(CellIndex.indexByString('A3'),
      TextCellValue('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'));

  summary.updateCell(CellIndex.indexByString('A5'), TextCellValue('Metric'));
  summary.updateCell(CellIndex.indexByString('B5'), TextCellValue('Amount'));
  summary.updateCell(CellIndex.indexByString('A6'), TextCellValue('Total Income'));
  summary.updateCell(CellIndex.indexByString('B6'), DoubleCellValue(state.totalIncome.amount));
  summary.updateCell(CellIndex.indexByString('A7'), TextCellValue('Total Expenses'));
  summary.updateCell(CellIndex.indexByString('B7'), DoubleCellValue(state.totalExpenses.amount));
  summary.updateCell(CellIndex.indexByString('A8'), TextCellValue('Net Balance'));
  summary.updateCell(CellIndex.indexByString('B8'), DoubleCellValue(state.netBalance.amount));
  summary.updateCell(CellIndex.indexByString('A9'), TextCellValue('Debts Paid'));
  summary.updateCell(CellIndex.indexByString('B9'), DoubleCellValue(state.debtsPaid.amount));
  summary.updateCell(CellIndex.indexByString('A10'), TextCellValue('Debts Received'));
  summary.updateCell(CellIndex.indexByString('B10'), DoubleCellValue(state.debtsReceived.amount));
  summary.updateCell(CellIndex.indexByString('A11'), TextCellValue('Total Transferred'));
  summary.updateCell(CellIndex.indexByString('B11'), DoubleCellValue(state.transferred.amount));

  if (state.topIncomeCategories.isNotEmpty) {
    final sheet = excel['Top Income Categories'];
    sheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Category'));
    sheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Amount'));
    for (var i = 0; i < state.topIncomeCategories.length; i++) {
      final c = state.topIncomeCategories[i];
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1), TextCellValue(c.name));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1), DoubleCellValue(c.total.amount));
    }
  }

  if (state.topExpensesCategories.isNotEmpty) {
    final sheet = excel['Top Expense Categories'];
    sheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Category'));
    sheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Amount'));
    for (var i = 0; i < state.topExpensesCategories.length; i++) {
      final c = state.topExpensesCategories[i];
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1), TextCellValue(c.name));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1), DoubleCellValue(c.total.amount));
    }
  }

  final txSheet = excel['Transactions'];
  txSheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Date'));
  txSheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Category'));
  txSheet.updateCell(CellIndex.indexByString('C1'), TextCellValue('Note'));
  txSheet.updateCell(CellIndex.indexByString('D1'), TextCellValue('Amount'));
  for (var i = 0; i < transactions.length; i++) {
    final t = transactions[i];
    final row = i + 1;
    txSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), TextCellValue(dateFmt.format(t.date)));
    txSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row), TextCellValue(t.category?.name ?? '-'));
    txSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), TextCellValue(t.note ?? '-'));
    txSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row), DoubleCellValue(t.amountMoney.amount));
  }

  if (defaultSheetName != null &&
      defaultSheetName != 'Summary' &&
      defaultSheetName != 'Top Income Categories' &&
      defaultSheetName != 'Top Expense Categories' &&
      defaultSheetName != 'Transactions') {
    excel.delete(defaultSheetName);
  }

  final bytes = excel.save();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final fileName = 'NestFlow_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath)], text: 'NestFlow financial report'),
  );
}
