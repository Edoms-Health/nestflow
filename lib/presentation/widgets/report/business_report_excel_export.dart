import 'dart:io';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportBranchReportExcel(
  BuildContext context, {
  required BusinessLoaded loaded,
  required BranchModel branch,
  required bool isDaily,
  required DateTime selectedDate,
}) async {
  final dateFmt = DateFormat('dd MMM yyyy');

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

  final excel = Excel.createExcel();
  final defaultSheetName = excel.getDefaultSheet();

  // ── Summary sheet ──────────────────────────────────────────
  final summary = excel['Summary'];
  summary.updateCell(CellIndex.indexByString('A1'), TextCellValue(branch.name));
  summary.updateCell(CellIndex.indexByString('A2'), TextCellValue(loaded.active?.name ?? 'Business'));
  summary.updateCell(CellIndex.indexByString('A3'), TextCellValue('${isDaily ? 'Daily' : 'Monthly'} Report — $periodLabel'));
  summary.updateCell(CellIndex.indexByString('A4'), TextCellValue('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'));

  summary.updateCell(CellIndex.indexByString('A6'), TextCellValue('Metric'));
  summary.updateCell(CellIndex.indexByString('B6'), TextCellValue('Amount'));
  summary.updateCell(CellIndex.indexByString('A7'), TextCellValue('Total Sales'));
  summary.updateCell(CellIndex.indexByString('B7'), DoubleCellValue(totalSales));
  summary.updateCell(CellIndex.indexByString('A8'), TextCellValue('Total Expenses'));
  summary.updateCell(CellIndex.indexByString('B8'), DoubleCellValue(totalExpenses));
  summary.updateCell(CellIndex.indexByString('A9'), TextCellValue('Other Entries (net)'));
  summary.updateCell(CellIndex.indexByString('B9'), DoubleCellValue(totalOthers));
  summary.updateCell(CellIndex.indexByString('A10'), TextCellValue('Net Balance'));
  summary.updateCell(CellIndex.indexByString('B10'), DoubleCellValue(netProfit));

  // ── Sales sheet ─────────────────────────────────────────────
  final salesSheet = excel['Sales'];
  salesSheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Date'));
  salesSheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Description'));
  salesSheet.updateCell(CellIndex.indexByString('C1'), TextCellValue('Amount'));
  for (var i = 0; i < sales.length; i++) {
    final row = i + 2;
    final s = sales[i];
    salesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1), TextCellValue(dateFmt.format(s.saleDate)));
    salesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1), TextCellValue(s.description));
    salesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1), DoubleCellValue(s.amount));
  }

  // ── Expenses sheet ──────────────────────────────────────────
  final expensesSheet = excel['Expenses'];
  expensesSheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Date'));
  expensesSheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Description'));
  expensesSheet.updateCell(CellIndex.indexByString('C1'), TextCellValue('Category'));
  expensesSheet.updateCell(CellIndex.indexByString('D1'), TextCellValue('Amount'));
  for (var i = 0; i < expenses.length; i++) {
    final row = i + 2;
    final e = expenses[i];
    expensesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1), TextCellValue(dateFmt.format(e.expenseDate)));
    expensesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1), TextCellValue(e.description));
    expensesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1), TextCellValue(e.category));
    expensesSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1), DoubleCellValue(e.amount));
  }

  // ── Other Entries sheet ─────────────────────────────────────
  if (others.isNotEmpty) {
    final othersSheet = excel['Other Entries'];
    othersSheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Date'));
    othersSheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Description'));
    othersSheet.updateCell(CellIndex.indexByString('C1'), TextCellValue('Type'));
    othersSheet.updateCell(CellIndex.indexByString('D1'), TextCellValue('Amount'));
    for (var i = 0; i < others.length; i++) {
      final row = i + 2;
      final o = others[i];
      othersSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1), TextCellValue(dateFmt.format(o.entryDate)));
      othersSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1), TextCellValue(o.description));
      othersSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1), TextCellValue(o.isInflow ? 'Inflow' : 'Outflow'));
      othersSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1), DoubleCellValue(o.amount));
    }
  }

  // Remove the default empty "Sheet1" if it's not one we used
  if (defaultSheetName != null &&
      defaultSheetName != 'Summary' &&
      defaultSheetName != 'Sales' &&
      defaultSheetName != 'Expenses' &&
      defaultSheetName != 'Other Entries') {
    excel.delete(defaultSheetName);
  }

  final bytes = excel.save();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final fileName = '${branch.name}_Report_${DateFormat('yyyyMMdd').format(selectedDate)}.xlsx';
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath)], text: '$periodLabel report for ${branch.name}'),
  );
}
