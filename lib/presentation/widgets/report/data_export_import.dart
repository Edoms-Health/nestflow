import 'dart:io';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

// ============================================================
// Cell <-> Dart value helpers
// ============================================================

String? _cellText(CellValue? v) {
  if (v == null) return null;
  if (v is TextCellValue) {
    final t = v.value.text ?? v.value.toString();
    return t.isEmpty ? null : t;
  }
  return v.toString();
}

double? _cellDouble(CellValue? v) {
  if (v == null) return null;
  if (v is DoubleCellValue) return v.value;
  if (v is IntCellValue) return v.value.toDouble();
  final t = _cellText(v);
  return t == null ? null : double.tryParse(t);
}

int? _cellInt(CellValue? v) {
  if (v == null) return null;
  if (v is IntCellValue) return v.value;
  if (v is DoubleCellValue) return v.value.toInt();
  final t = _cellText(v);
  return t == null ? null : int.tryParse(t);
}

bool? _cellBool(CellValue? v) {
  if (v == null) return null;
  if (v is BoolCellValue) return v.value;
  final t = _cellText(v)?.toLowerCase();
  if (t == null) return null;
  return t == 'true' || t == '1';
}

DateTime? _cellDateTime(CellValue? v) {
  final t = _cellText(v);
  return t == null ? null : DateTime.tryParse(t);
}

// ============================================================
// Sheet writing
// ============================================================

void _writeSheet(
  Sheet sheet,
  List<String> columns,
  List<Map<String, Object?>> rows,
) {
  for (var c = 0; c < columns.length; c++) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      TextCellValue(columns[c]),
    );
  }
  for (var r = 0; r < rows.length; r++) {
    final data = rows[r];
    for (var c = 0; c < columns.length; c++) {
      final value = data[columns[c]];
      if (value == null) continue;
      final cellIndex = CellIndex.indexByColumnRow(
        columnIndex: c,
        rowIndex: r + 1,
      );
      if (value is String) {
        sheet.updateCell(cellIndex, TextCellValue(value));
      } else if (value is bool) {
        sheet.updateCell(cellIndex, BoolCellValue(value));
      } else if (value is int) {
        sheet.updateCell(cellIndex, IntCellValue(value));
      } else if (value is double) {
        sheet.updateCell(cellIndex, DoubleCellValue(value));
      } else if (value is DateTime) {
        sheet.updateCell(cellIndex, TextCellValue(value.toIso8601String()));
      }
    }
  }
}

// ============================================================
// Sheet reading
// ============================================================

List<Map<String, CellValue?>> _sheetRows(Sheet sheet) {
  final rows = sheet.rows;
  if (rows.isEmpty) return [];
  final header = rows[0].map((c) => _cellText(c?.value) ?? '').toList();
  final out = <Map<String, CellValue?>>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    final map = <String, CellValue?>{};
    for (var c = 0; c < header.length && c < row.length; c++) {
      map[header[c]] = row[c]?.value;
    }
    out.add(map);
  }
  return out;
}

// ============================================================
// Column definitions (write & read share these)
// ============================================================

const _kWalletCols = [
  'id', 'name', 'type', 'currency', 'balance',
  'isLocked', 'isHidden', 'createdAt', 'updatedAt',
];
const _kCategoryCols = [
  'id', 'identifier', 'categoryId', 'name', 'description',
  'type', 'icon', 'color', 'builtIn', 'createdAt', 'updatedAt',
];
const _kTransactionCols = [
  'id', 'amount', 'type', 'walletId', 'categoryId', 'contactId', 'toWalletId',
  'date', 'startDate', 'endDate', 'interestRate', 'interestIsDaily', 'note',
  'currency', 'currencyRate', 'noImpactOnBalance', 'createdAt', 'updatedAt',
];
const _kBudgetCols = [
  'id', 'name', 'startDate', 'endDate', 'categoryId', 'walletId',
  'amount', 'spent', 'note', 'createdAt', 'updatedAt',
];
const _kRecurringCols = [
  'id', 'amount', 'walletId', 'categoryId', 'contactId', 'note', 'currency',
  'frequency', 'nextDueDate', 'endDate', 'isActive', 'createdAt', 'updatedAt',
];

// ============================================================
// EXPORT
// ============================================================

/// Exports Wallets, Categories, Transactions, Budgets and Recurring Expenses
/// into one .xlsx workbook, and lets the user pick the save location.
/// Returns the saved file path, or null if the user cancelled.
///
/// NOTE: contactId (Transactions, Recurring Expenses) and tag links
/// (Transactions) are NOT exported/imported — Contacts and Tags were out
/// of scope, so those links can't be safely round-tripped.
Future<String?> exportAllDataExcel() async {
  final walletService = WalletService();
  final categoryService = CategoryService();
  final transactionService = TransactionService();
  final budgetService = BudgetService();
  final recurringExpenseService = RecurringExpenseService();

  final wallets = await walletService.fetchAll();
  final categories = await categoryService.fetchAll();
  // No fetchAll() exists on TransactionService yet; pagination with a large
  // limit is used instead. Consider adding a proper fetchAll() later.
  final transactions = await transactionService.getTransactionPagination(
    limit: 1000000,
  );
  final budgets = await budgetService.fetchAll();
  final recurringExpenses = await recurringExpenseService.fetchAll();

  final excel = Excel.createExcel();
  final defaultSheetName = excel.getDefaultSheet();

  _writeSheet(
    excel['Wallets'],
    _kWalletCols,
    wallets
        .map(
          (w) => {
            'id': w.id,
            'name': w.name,
            'type': w.type.name,
            'currency': w.currency,
            'balance': w.balance,
            'isLocked': w.isLocked,
            'isHidden': w.isHidden,
            'createdAt': w.createdAt,
            'updatedAt': w.updatedAt,
          },
        )
        .toList(),
  );

  _writeSheet(
    excel['Categories'],
    _kCategoryCols,
    categories
        .map(
          (c) => {
            'id': c.id,
            'identifier': c.identifier,
            'categoryId': c.categoryId,
            'name': c.name,
            'description': c.description,
            'type': c.type.name,
            'icon': c.icon,
            'color': c.color,
            'builtIn': c.builtIn,
            'createdAt': c.createdAt,
            'updatedAt': c.updatedAt,
          },
        )
        .toList(),
  );

  _writeSheet(
    excel['Transactions'],
    _kTransactionCols,
    transactions
        .map(
          (t) => {
            'id': t.id,
            'amount': t.amount,
            'type': t.type.name,
            'walletId': t.walletId,
            'categoryId': t.categoryId,
            'contactId': t.contactId,
            'toWalletId': t.toWalletId,
            'date': t.date,
            'startDate': t.startDate,
            'endDate': t.endDate,
            'interestRate': t.interestRate,
            'interestIsDaily': t.interestIsDaily,
            'note': t.note,
            'currency': t.currency,
            'currencyRate': t.currencyRate,
            'noImpactOnBalance': t.noImpactOnBalance,
            'createdAt': t.createdAt,
            'updatedAt': t.updatedAt,
          },
        )
        .toList(),
  );

  _writeSheet(
    excel['Budgets'],
    _kBudgetCols,
    budgets
        .map(
          (b) => {
            'id': b.id,
            'name': b.name,
            'startDate': b.startDate,
            'endDate': b.endDate,
            'categoryId': b.categoryId,
            'walletId': b.walletId,
            'amount': b.amount,
            'spent': b.spent,
            'note': b.note,
            'createdAt': b.createdAt,
            'updatedAt': b.updatedAt,
          },
        )
        .toList(),
  );

  _writeSheet(
    excel['RecurringExpenses'],
    _kRecurringCols,
    recurringExpenses
        .map(
          (e) => {
            'id': e.id,
            'amount': e.amount,
            'walletId': e.walletId,
            'categoryId': e.categoryId,
            'contactId': e.contactId,
            'note': e.note,
            'currency': e.currency,
            'frequency': e.frequency.name,
            'nextDueDate': e.nextDueDate,
            'endDate': e.endDate,
            'isActive': e.isActive,
            'createdAt': e.createdAt,
            'updatedAt': e.updatedAt,
          },
        )
        .toList(),
  );

  const keepSheets = {
    'Wallets',
    'Categories',
    'Transactions',
    'Budgets',
    'RecurringExpenses',
  };
  if (defaultSheetName != null && !keepSheets.contains(defaultSheetName)) {
    excel.delete(defaultSheetName);
  }

  final bytes = excel.save();
  if (bytes == null) return null;
  final byteData = Uint8List.fromList(bytes);

  final fileName =
      'NestFlow_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

  final savePath = await FilePicker.saveFile(
    dialogTitle: 'Save NestFlow export',
    fileName: fileName,
    bytes: byteData,
  );
  if (savePath == null) return null;

  // saveFile's `bytes` param writes the file on some platforms (Android)
  // but not reliably on desktop, so we also write manually as a fallback.
  // If Android already wrote it via a content:// URI, this second write
  // will simply fail silently, which is fine.
  try {
    await File(savePath).writeAsBytes(byteData);
  } catch (_) {
    // Already written by the platform-native saveFile call above.
  }

  return savePath;
}

// ============================================================
// IMPORT
// ============================================================

class ImportSummary {
  final int wallets;
  final int categories;
  final int transactions;
  final int budgets;
  final int recurringExpenses;

  const ImportSummary({
    this.wallets = 0,
    this.categories = 0,
    this.transactions = 0,
    this.budgets = 0,
    this.recurringExpenses = 0,
  });
}

/// Picks a NestFlow-exported .xlsx and imports it. All records are always
/// inserted as NEW rows with new IDs (never overwrites existing data);
/// wallet/category foreign keys are remapped from old IDs to the new ones
/// created during this import. Returns null if the user cancelled or the
/// file had no data.
Future<ImportSummary?> importAllDataExcel() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final bytes = result.files.first.bytes;
  if (bytes == null) return null;

  final excel = Excel.decodeBytes(bytes);

  final walletService = WalletService();
  final categoryService = CategoryService();
  final transactionService = TransactionService();
  final budgetService = BudgetService();
  final recurringExpenseService = RecurringExpenseService();

  // ---------- Wallets ----------
  final walletIdMap = <int, int>{};
  final walletSheet = excel.tables['Wallets'];
  if (walletSheet != null) {
    for (final row in _sheetRows(walletSheet)) {
      final oldId = _cellInt(row['id']);
      if (oldId == null) continue;
      final now = DateTime.now();
      final newId = await walletService.create(
        WalletModel(
          id: 0,
          name: _cellText(row['name']) ?? 'Imported Wallet',
          type: WalletType.values.byName(
            _cellText(row['type']) ?? WalletType.values.first.name,
          ),
          currency: _cellText(row['currency']) ?? 'USD',
          balance: _cellDouble(row['balance']) ?? 0,
          isLocked: _cellBool(row['isLocked']) ?? false,
          isHidden: _cellBool(row['isHidden']) ?? false,
          createdAt: _cellDateTime(row['createdAt']) ?? now,
          updatedAt: _cellDateTime(row['updatedAt']) ?? now,
        ),
      );
      walletIdMap[oldId] = newId;
    }
  }

  // ---------- Categories (two-pass: insert as root, then remap parent) ----------
  final categoryIdMap = <int, int>{};
  final createdCategoryModels = <int, CategoryModel>{};
  final pendingParents = <int, int>{}; // newId -> oldParentId
  final categorySheet = excel.tables['Categories'];
  if (categorySheet != null) {
    for (final row in _sheetRows(categorySheet)) {
      final oldId = _cellInt(row['id']);
      if (oldId == null) continue;
      final now = DateTime.now();
      final oldParentId = _cellInt(row['categoryId']);
      final model = CategoryModel(
        id: 0,
        categoryId: null, // patched in second pass
        name: _cellText(row['name']) ?? 'Imported Category',
        description: _cellText(row['description']),
        type: TransactionType.values.byName(
          _cellText(row['type']) ?? TransactionType.values.first.name,
        ),
        icon: _cellText(row['icon']) ?? 'category',
        color: _cellText(row['color']) ?? '607D8B',
        builtIn: false, // imported categories are never treated as built-in
        createdAt: _cellDateTime(row['createdAt']) ?? now,
        updatedAt: _cellDateTime(row['updatedAt']) ?? now,
      );
      final newId = await categoryService.create(model);
      categoryIdMap[oldId] = newId;
      createdCategoryModels[newId] = model;
      if (oldParentId != null) pendingParents[newId] = oldParentId;
    }

    for (final entry in pendingParents.entries) {
      final newParentId = categoryIdMap[entry.value];
      if (newParentId == null) continue; // parent wasn't in this export
      final base = createdCategoryModels[entry.key]!;
      await categoryService.update(
        CategoryModel(
          id: entry.key,
          categoryId: newParentId,
          name: base.name,
          description: base.description,
          type: base.type,
          icon: base.icon,
          color: base.color,
          builtIn: base.builtIn,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
        ),
      );
    }
  }

  // ---------- Transactions ----------
  var transactionCount = 0;
  final transactionSheet = excel.tables['Transactions'];
  if (transactionSheet != null) {
    final toInsert = <TransactionModel>[];
    for (final row in _sheetRows(transactionSheet)) {
      final oldWalletId = _cellInt(row['walletId']);
      final oldCategoryId = _cellInt(row['categoryId']);
      final newWalletId = oldWalletId == null
          ? null
          : walletIdMap[oldWalletId];
      final newCategoryId = oldCategoryId == null
          ? null
          : categoryIdMap[oldCategoryId];
      if (newWalletId == null || newCategoryId == null) {
        continue; // orphaned row — wallet/category wasn't in this export
      }
      final oldToWalletId = _cellInt(row['toWalletId']);
      final now = DateTime.now();
      toInsert.add(
        TransactionModel(
          id: 0,
          amount: _cellDouble(row['amount']) ?? 0,
          type: TransactionType.values.byName(
            _cellText(row['type']) ?? TransactionType.values.first.name,
          ),
          walletId: newWalletId,
          categoryId: newCategoryId,
          toWalletId: oldToWalletId == null
              ? null
              : walletIdMap[oldToWalletId],
          date: _cellDateTime(row['date']) ?? now,
          startDate: _cellDateTime(row['startDate']),
          endDate: _cellDateTime(row['endDate']),
          interestRate: _cellDouble(row['interestRate']),
          interestIsDaily: _cellBool(row['interestIsDaily']) ?? false,
          note: _cellText(row['note']),
          currency: _cellText(row['currency']) ?? 'USD',
          currencyRate: _cellDouble(row['currencyRate']) ?? 1,
          noImpactOnBalance: _cellBool(row['noImpactOnBalance']) ?? false,
          createdAt: _cellDateTime(row['createdAt']) ?? now,
          updatedAt: _cellDateTime(row['updatedAt']) ?? now,
        ),
      );
    }
    if (toInsert.isNotEmpty) {
      // insertAll (not create) deliberately: wallet balances were already
      // imported verbatim above, so we don't want per-row recalculation.
      await transactionService.insertAll(toInsert);
      transactionCount = toInsert.length;
    }
  }

  // ---------- Budgets ----------
  var budgetCount = 0;
  final budgetSheet = excel.tables['Budgets'];
  if (budgetSheet != null) {
    final toInsert = <BudgetModel>[];
    for (final row in _sheetRows(budgetSheet)) {
      final oldCategoryId = _cellInt(row['categoryId']);
      final newCategoryId = oldCategoryId == null
          ? null
          : categoryIdMap[oldCategoryId];
      if (newCategoryId == null) continue;
      final oldWalletId = _cellInt(row['walletId']);
      final now = DateTime.now();
      toInsert.add(
        BudgetModel(
          id: 0,
          name: _cellText(row['name']) ?? 'Imported Budget',
          startDate: _cellDateTime(row['startDate']) ?? now,
          endDate: _cellDateTime(row['endDate']) ?? now,
          categoryId: newCategoryId,
          walletId: oldWalletId == null ? null : walletIdMap[oldWalletId],
          amount: _cellDouble(row['amount']) ?? 0,
          note: _cellText(row['note']),
          createdAt: _cellDateTime(row['createdAt']) ?? now,
          updatedAt: _cellDateTime(row['updatedAt']) ?? now,
        ),
      );
    }
    if (toInsert.isNotEmpty) {
      await budgetService.insertAll(toInsert);
      budgetCount = toInsert.length;
    }
  }

  // ---------- Recurring Expenses ----------
  var recurringCount = 0;
  final recurringSheet = excel.tables['RecurringExpenses'];
  if (recurringSheet != null) {
    for (final row in _sheetRows(recurringSheet)) {
      final oldWalletId = _cellInt(row['walletId']);
      final oldCategoryId = _cellInt(row['categoryId']);
      final newWalletId = oldWalletId == null
          ? null
          : walletIdMap[oldWalletId];
      final newCategoryId = oldCategoryId == null
          ? null
          : categoryIdMap[oldCategoryId];
      if (newWalletId == null || newCategoryId == null) continue;
      final now = DateTime.now();
      await recurringExpenseService.create(
        RecurringExpenseModel(
          id: 0,
          amount: _cellDouble(row['amount']) ?? 0,
          walletId: newWalletId,
          categoryId: newCategoryId,
          note: _cellText(row['note']),
          currency: _cellText(row['currency']) ?? 'USD',
          frequency: RecurrenceFrequency.values.byName(
            _cellText(row['frequency']) ??
                RecurrenceFrequency.values.first.name,
          ),
          nextDueDate: _cellDateTime(row['nextDueDate']) ?? now,
          endDate: _cellDateTime(row['endDate']),
          isActive: _cellBool(row['isActive']) ?? true,
          createdAt: _cellDateTime(row['createdAt']) ?? now,
          updatedAt: _cellDateTime(row['updatedAt']) ?? now,
        ),
      );
      recurringCount++;
    }
  }

  return ImportSummary(
    wallets: walletIdMap.length,
    categories: categoryIdMap.length,
    transactions: transactionCount,
    budgets: budgetCount,
    recurringExpenses: recurringCount,
  );
}
