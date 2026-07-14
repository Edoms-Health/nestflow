import 'dart:io';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

Future<void> exportProfitLossExcel(
  BuildContext context, {
  required FinancialLoaded state,
}) async {
  final excel = Excel.createExcel();
  final defaultSheetName = excel.getDefaultSheet();

  final summary = excel['Summary'];
  summary.updateCell(CellIndex.indexByString('A1'), TextCellValue('Profit & Loss Statement'));
  summary.updateCell(CellIndex.indexByString('A2'), TextCellValue('Year ${state.year}'));
  summary.updateCell(
    CellIndex.indexByString('A3'),
    TextCellValue('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
  );

  summary.updateCell(CellIndex.indexByString('A5'), TextCellValue('Metric'));
  summary.updateCell(CellIndex.indexByString('B5'), TextCellValue('Amount'));
  summary.updateCell(CellIndex.indexByString('A6'), TextCellValue('Annual Revenue'));
  summary.updateCell(CellIndex.indexByString('B6'), DoubleCellValue(state.annualIncome));
  summary.updateCell(CellIndex.indexByString('A7'), TextCellValue('Annual Expense'));
  summary.updateCell(CellIndex.indexByString('B7'), DoubleCellValue(state.annualExpense));
  summary.updateCell(
    CellIndex.indexByString('A8'),
    TextCellValue(state.annualProfit >= 0 ? 'Net Profit' : 'Net Loss'),
  );
  summary.updateCell(CellIndex.indexByString('B8'), DoubleCellValue(state.annualProfit));

  final monthly = excel['Monthly Breakdown'];
  monthly.updateCell(CellIndex.indexByString('A1'), TextCellValue('Month'));
  monthly.updateCell(CellIndex.indexByString('B1'), TextCellValue('Income'));
  monthly.updateCell(CellIndex.indexByString('C1'), TextCellValue('Expense'));
  monthly.updateCell(CellIndex.indexByString('D1'), TextCellValue('Profit / Loss'));
  for (var m = 1; m <= 12; m++) {
    final row = m; // header is row 1 (index 0), months start row 2 (index 1)
    final entry = state.entriesByMonth[m];
    monthly.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      TextCellValue(_kMonthNames[m - 1]),
    );
    monthly.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      DoubleCellValue(entry?.income ?? 0),
    );
    monthly.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      DoubleCellValue(entry?.expense ?? 0),
    );
    monthly.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      DoubleCellValue(entry?.profit ?? 0),
    );
  }

  if (defaultSheetName != null &&
      defaultSheetName != 'Summary' &&
      defaultSheetName != 'Monthly Breakdown') {
    excel.delete(defaultSheetName);
  }

  final bytes = excel.save();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final fileName = 'Profit_Loss_${state.year}.xlsx';
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath)], text: 'Profit & Loss ${state.year}'),
  );
}

Future<void> exportBalanceSheetExcel(
  BuildContext context, {
  required BalanceSheetLoaded state,
}) async {
  final excel = Excel.createExcel();
  final defaultSheetName = excel.getDefaultSheet();

  void writeSection(String sheetName, List<BalanceSheetAccountModel> accounts, double total) {
    final sheet = excel[sheetName];
    sheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Account'));
    sheet.updateCell(CellIndex.indexByString('B1'), TextCellValue('Amount'));
    for (var i = 0; i < accounts.length; i++) {
      final row = i + 1;
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        TextCellValue(accounts[i].name),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        DoubleCellValue(accounts[i].amount),
      );
    }
    final totalRow = accounts.length + 1;
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      TextCellValue('Total $sheetName'),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow),
      DoubleCellValue(total),
    );
  }

  writeSection('Assets', state.assets, state.totalAssets);
  writeSection('Liabilities', state.liabilities, state.totalLiabilities);
  writeSection('Equity', state.equity, state.totalEquity);

  final summary = excel['Summary'];
  summary.updateCell(CellIndex.indexByString('A1'), TextCellValue('Balance Sheet'));
  summary.updateCell(
    CellIndex.indexByString('A2'),
    TextCellValue('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
  );
  summary.updateCell(CellIndex.indexByString('A4'), TextCellValue('Total Assets'));
  summary.updateCell(CellIndex.indexByString('B4'), DoubleCellValue(state.totalAssets));
  summary.updateCell(CellIndex.indexByString('A5'), TextCellValue('Total Liabilities'));
  summary.updateCell(CellIndex.indexByString('B5'), DoubleCellValue(state.totalLiabilities));
  summary.updateCell(CellIndex.indexByString('A6'), TextCellValue('Total Equity'));
  summary.updateCell(CellIndex.indexByString('B6'), DoubleCellValue(state.totalEquity));
  summary.updateCell(CellIndex.indexByString('A7'), TextCellValue('Balanced'));
  summary.updateCell(CellIndex.indexByString('B7'), TextCellValue(state.isBalanced ? 'Yes' : 'No'));

  if (defaultSheetName != null &&
      defaultSheetName != 'Summary' &&
      defaultSheetName != 'Assets' &&
      defaultSheetName != 'Liabilities' &&
      defaultSheetName != 'Equity') {
    excel.delete(defaultSheetName);
  }

  final bytes = excel.save();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final fileName = 'Balance_Sheet_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath)], text: 'Balance Sheet export'),
  );
}
