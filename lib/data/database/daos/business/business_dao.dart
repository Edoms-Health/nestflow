import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

part 'business_dao.g.dart';

@DriftAccessor(tables: [
  Businesses,
  BusinessClients,
  BusinessSuppliers,
  BusinessProducts,
  BusinessInvoices,
  BusinessInvoiceItems,
  BusinessExpenses,
  Branches,
  BusinessSales,
  BusinessOtherEntries,
  CashbookExpenses,
])
class BusinessDao extends DatabaseAccessor<AppDatabase> with _$BusinessDaoMixin {
  BusinessDao(super.db);

  // ── Businesses ──────────────────────────────────────────────
  Future<List<BusinessData>> getAllBusinesses() => select(businesses).get();

  Future<BusinessData?> getActiveBusiness() =>
      (select(businesses)..where((b) => b.isActive.equals(true))).getSingleOrNull();

  Future<int> insertBusiness(BusinessesCompanion b) => into(businesses).insert(b);

  Future<bool> updateBusiness(BusinessesCompanion b) => update(businesses).replace(b);

  Future<int> deleteBusiness(int id) =>
      (delete(businesses)..where((b) => b.id.equals(id))).go();

  Future<void> setActiveBusiness(int id) async {
    await (update(businesses)).write(const BusinessesCompanion(isActive: Value(false)));
    await (update(businesses)..where((b) => b.id.equals(id)))
        .write(const BusinessesCompanion(isActive: Value(true)));
  }

  // ── Clients ─────────────────────────────────────────────────
  Future<List<BusinessClientData>> getClients(int businessId) =>
      (select(businessClients)..where((c) => c.businessId.equals(businessId))).get();

  Future<int> insertClient(BusinessClientsCompanion c) => into(businessClients).insert(c);
  Future<bool> updateClient(BusinessClientsCompanion c) => update(businessClients).replace(c);
  Future<int> deleteClient(int id) =>
      (delete(businessClients)..where((c) => c.id.equals(id))).go();

  // ── Suppliers ────────────────────────────────────────────────
  Future<List<BusinessSupplierData>> getSuppliers(int businessId) =>
      (select(businessSuppliers)..where((s) => s.businessId.equals(businessId))).get();

  Future<int> insertSupplier(BusinessSuppliersCompanion s) => into(businessSuppliers).insert(s);
  Future<bool> updateSupplier(BusinessSuppliersCompanion s) => update(businessSuppliers).replace(s);
  Future<int> deleteSupplier(int id) =>
      (delete(businessSuppliers)..where((s) => s.id.equals(id))).go();

  // ── Products ─────────────────────────────────────────────────
  Future<List<BusinessProductData>> getProducts(int businessId) =>
      (select(businessProducts)..where((p) => p.businessId.equals(businessId))).get();

  Future<List<BusinessProductData>> getLowStockProducts(int businessId) =>
      (select(businessProducts)
        ..where((p) => p.businessId.equals(businessId))
        ..where((p) => p.stockQty.isSmallerOrEqualValue(5.0)))
          .get();

  Future<int> insertProduct(BusinessProductsCompanion p) => into(businessProducts).insert(p);
  Future<bool> updateProduct(BusinessProductsCompanion p) => update(businessProducts).replace(p);
  Future<int> deleteProduct(int id) =>
      (delete(businessProducts)..where((p) => p.id.equals(id))).go();

  Future<void> adjustStock(int productId, double qty) async {
    final product = await (select(businessProducts)
        ..where((p) => p.id.equals(productId))).getSingle();
    await (update(businessProducts)..where((p) => p.id.equals(productId)))
        .write(BusinessProductsCompanion(
          stockQty: Value(product.stockQty + qty),
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ── Invoices ─────────────────────────────────────────────────
  Future<List<BusinessInvoiceData>> getInvoices(int businessId) =>
      (select(businessInvoices)
        ..where((i) => i.businessId.equals(businessId))
        ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  Future<BusinessInvoiceData?> getInvoice(int id) =>
      (select(businessInvoices)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<List<BusinessInvoiceItemData>> getInvoiceItems(int invoiceId) =>
      (select(businessInvoiceItems)
        ..where((i) => i.invoiceId.equals(invoiceId))).get();

  Future<int> insertInvoice(BusinessInvoicesCompanion i) => into(businessInvoices).insert(i);
  Future<bool> updateInvoice(BusinessInvoicesCompanion i) => update(businessInvoices).replace(i);
  Future<int> deleteInvoice(int id) =>
      (delete(businessInvoices)..where((i) => i.id.equals(id))).go();

  Future<int> insertInvoiceItem(BusinessInvoiceItemsCompanion i) =>
      into(businessInvoiceItems).insert(i);
  Future<int> deleteInvoiceItems(int invoiceId) =>
      (delete(businessInvoiceItems)..where((i) => i.invoiceId.equals(invoiceId))).go();

  Future<void> updateInvoiceStatus(int id, String status) async {
    await (update(businessInvoices)..where((i) => i.id.equals(id)))
        .write(BusinessInvoicesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ── Expenses ─────────────────────────────────────────────────
  Future<List<BusinessExpenseData>> getExpenses(int businessId) =>
      (select(businessExpenses)
        ..where((e) => e.businessId.equals(businessId))
        ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
          .get();

  Future<int> insertExpense(BusinessExpensesCompanion e) => into(businessExpenses).insert(e);
  Future<bool> updateExpense(BusinessExpensesCompanion e) => update(businessExpenses).replace(e);
  Future<int> deleteExpense(int id) =>
      (delete(businessExpenses)..where((e) => e.id.equals(id))).go();

  // ── Cashbook Expenses (independent of Business Management expenses) ────
  Future<List<CashbookExpenseData>> getCashbookExpenses(int businessId) =>
      (select(cashbookExpenses)
        ..where((e) => e.businessId.equals(businessId))
        ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
          .get();

  Future<int> insertCashbookExpense(CashbookExpensesCompanion e) =>
      into(cashbookExpenses).insert(e);
  Future<bool> updateCashbookExpense(CashbookExpensesCompanion e) =>
      update(cashbookExpenses).replace(e);
  Future<int> deleteCashbookExpense(int id) =>
      (delete(cashbookExpenses)..where((e) => e.id.equals(id))).go();

  // ── Branches ────────────────────────────────────────────────
  Future<List<BranchData>> getBranches(int businessId) =>
      (select(branches)..where((b) => b.businessId.equals(businessId))).get();

  Future<int> insertBranch(BranchesCompanion b) => into(branches).insert(b);
  Future<bool> updateBranch(BranchesCompanion b) => update(branches).replace(b);
  Future<int> deleteBranch(int id) =>
      (delete(branches)..where((b) => b.id.equals(id))).go();

  // ── Sales ───────────────────────────────────────────────────
  Future<List<BusinessSaleData>> getSales(int businessId) =>
      (select(businessSales)
        ..where((s) => s.businessId.equals(businessId))
        ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
          .get();

  Future<int> insertSale(BusinessSalesCompanion s) => into(businessSales).insert(s);
  Future<bool> updateSale(BusinessSalesCompanion s) => update(businessSales).replace(s);
  Future<int> deleteSale(int id) =>
      (delete(businessSales)..where((s) => s.id.equals(id))).go();

  // ── Reports ─────────────────────────────────────────────────
  Future<double> _sumSales(int businessId, int? branchId, DateTime start, DateTime end) async {
    final query = select(businessSales)
      ..where((s) =>
          s.businessId.equals(businessId) &
          s.saleDate.isBiggerOrEqualValue(start) &
          s.saleDate.isSmallerThanValue(end));
    if (branchId != null) query.where((s) => s.branchId.equals(branchId));
    final rows = await query.get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  Future<double> _sumPaidInvoices(int businessId, int? branchId, DateTime start, DateTime end) async {
    final query = select(businessInvoices)
      ..where((i) =>
          i.businessId.equals(businessId) &
          i.status.equals('paid') &
          i.issuedAt.isBiggerOrEqualValue(start) &
          i.issuedAt.isSmallerThanValue(end));
    if (branchId != null) query.where((i) => i.branchId.equals(branchId));
    final invoices = await query.get();
    double total = 0;
    for (final inv in invoices) {
      final items = await getInvoiceItems(inv.id);
      final subtotal = items.fold<double>(0.0, (sum, it) => sum + (it.qty * it.unitPrice));
      final afterDiscount = subtotal - (subtotal * inv.discountPercent / 100);
      total += afterDiscount + (afterDiscount * inv.taxPercent / 100);
    }
    return total;
  }

  Future<double> _sumExpenses(int businessId, int? branchId, DateTime start, DateTime end) async {
    final query = select(cashbookExpenses)
      ..where((e) =>
          e.businessId.equals(businessId) &
          e.expenseDate.isBiggerOrEqualValue(start) &
          e.expenseDate.isSmallerThanValue(end));
    if (branchId != null) query.where((e) => e.branchId.equals(branchId));
    final rows = await query.get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  Future<Map<String, double>> getReport({
    required int businessId,
    int? branchId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Independent of Business Management: sales + cashbook expenses + others only.
    final salesTotal = await _sumSales(businessId, branchId, start, end);
    final expenseTotal = await _sumExpenses(businessId, branchId, start, end);
    final othersNet = await _sumOthers(businessId, branchId, start, end);
    return {
      'sales': salesTotal,
      'expenses': expenseTotal,
      'others': othersNet,
      'net': salesTotal - expenseTotal + othersNet,
    };
  }

  // ── Other Entries ───────────────────────────────────────────
  Future<List<BusinessOtherEntryData>> getOtherEntries(int businessId) =>
      (select(businessOtherEntries)
        ..where((o) => o.businessId.equals(businessId))
        ..orderBy([(o) => OrderingTerm.desc(o.entryDate)]))
          .get();

  Future<int> insertOtherEntry(BusinessOtherEntriesCompanion o) =>
      into(businessOtherEntries).insert(o);
  Future<bool> updateOtherEntry(BusinessOtherEntriesCompanion o) =>
      update(businessOtherEntries).replace(o);
  Future<int> deleteOtherEntry(int id) =>
      (delete(businessOtherEntries)..where((o) => o.id.equals(id))).go();

  Future<double> _sumOthers(int businessId, int? branchId, DateTime start, DateTime end) async {
    final query = select(businessOtherEntries)
      ..where((o) =>
          o.businessId.equals(businessId) &
          o.entryDate.isBiggerOrEqualValue(start) &
          o.entryDate.isSmallerThanValue(end));
    if (branchId != null) query.where((o) => o.branchId.equals(branchId));
    final rows = await query.get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.isInflow ? r.amount : -r.amount));
  }
}
