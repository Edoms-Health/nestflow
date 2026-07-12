import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

class BusinessService {
  final BusinessDao _dao = AppDatabase.instance.businessDao;

  // ── Businesses ──────────────────────────────────────────────
  Future<List<BusinessModel>> fetchAll() async {
    final rows = await _dao.getAllBusinesses();
    return rows.map((r) => _toBusiness(r)).toList();
  }

  Future<BusinessModel?> getActive() async {
    final row = await _dao.getActiveBusiness();
    return row == null ? null : _toBusiness(row);
  }

  Future<int> create(BusinessModel b) => _dao.insertBusiness(BusinessesCompanion(
    name: Value(b.name), address: Value(b.address), phone: Value(b.phone),
    email: Value(b.email), tin: Value(b.tin), currency: Value(b.currency),
    isActive: Value(b.isActive), createdAt: Value(DateTime.now()),
    updatedAt: Value(DateTime.now()),
  ));

  Future<void> update(BusinessModel b) => _dao.updateBusiness(BusinessesCompanion(
    id: Value(b.id), name: Value(b.name), address: Value(b.address),
    phone: Value(b.phone), email: Value(b.email), tin: Value(b.tin),
    currency: Value(b.currency), isActive: Value(b.isActive),
    updatedAt: Value(DateTime.now()),
  ));

  Future<void> delete(int id) => _dao.deleteBusiness(id);
  Future<void> setActive(int id) => _dao.setActiveBusiness(id);

  // ── Clients ─────────────────────────────────────────────────
  Future<List<BusinessClientModel>> fetchClients(int businessId) async {
    final rows = await _dao.getClients(businessId);
    return rows.map((r) => _toClient(r)).toList();
  }

  Future<int> createClient(BusinessClientModel c) =>
      _dao.insertClient(BusinessClientsCompanion(
        businessId: Value(c.businessId), name: Value(c.name),
        phone: Value(c.phone), email: Value(c.email), address: Value(c.address),
        createdAt: Value(DateTime.now()), updatedAt: Value(DateTime.now()),
      ));

  Future<void> updateClient(BusinessClientModel c) =>
      _dao.updateClient(BusinessClientsCompanion(
        id: Value(c.id), businessId: Value(c.businessId), name: Value(c.name),
        phone: Value(c.phone), email: Value(c.email), address: Value(c.address),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteClient(int id) => _dao.deleteClient(id);

  // ── Suppliers ────────────────────────────────────────────────
  Future<List<BusinessSupplierModel>> fetchSuppliers(int businessId) async {
    final rows = await _dao.getSuppliers(businessId);
    return rows.map((r) => _toSupplier(r)).toList();
  }

  Future<int> createSupplier(BusinessSupplierModel s) =>
      _dao.insertSupplier(BusinessSuppliersCompanion(
        businessId: Value(s.businessId), name: Value(s.name),
        phone: Value(s.phone), email: Value(s.email), address: Value(s.address),
        createdAt: Value(DateTime.now()), updatedAt: Value(DateTime.now()),
      ));

  Future<void> updateSupplier(BusinessSupplierModel s) =>
      _dao.updateSupplier(BusinessSuppliersCompanion(
        id: Value(s.id), businessId: Value(s.businessId), name: Value(s.name),
        phone: Value(s.phone), email: Value(s.email), address: Value(s.address),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteSupplier(int id) => _dao.deleteSupplier(id);

  // ── Products ─────────────────────────────────────────────────
  Future<List<BusinessProductModel>> fetchProducts(int businessId) async {
    final rows = await _dao.getProducts(businessId);
    return rows.map((r) => _toProduct(r)).toList();
  }

  Future<List<BusinessProductModel>> fetchLowStock(int businessId) async {
    final rows = await _dao.getLowStockProducts(businessId);
    return rows.map((r) => _toProduct(r)).toList();
  }

  Future<int> createProduct(BusinessProductModel p) =>
      _dao.insertProduct(BusinessProductsCompanion(
        businessId: Value(p.businessId), name: Value(p.name),
        description: Value(p.description), unit: Value(p.unit),
        price: Value(p.price), stockQty: Value(p.stockQty),
        lowStockAlert: Value(p.lowStockAlert),
        createdAt: Value(DateTime.now()), updatedAt: Value(DateTime.now()),
      ));

  Future<void> updateProduct(BusinessProductModel p) =>
      _dao.updateProduct(BusinessProductsCompanion(
        id: Value(p.id), businessId: Value(p.businessId), name: Value(p.name),
        description: Value(p.description), unit: Value(p.unit),
        price: Value(p.price), stockQty: Value(p.stockQty),
        lowStockAlert: Value(p.lowStockAlert), updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteProduct(int id) => _dao.deleteProduct(id);
  Future<void> adjustStock(int productId, double qty) =>
      _dao.adjustStock(productId, qty);

  // ── Invoices ─────────────────────────────────────────────────
  Future<List<BusinessInvoiceModel>> fetchInvoices(int businessId) async {
    final rows = await _dao.getInvoices(businessId);
    final clients = await fetchClients(businessId);
    final clientMap = {for (var c in clients) c.id: c};
    final List<BusinessInvoiceModel> result = [];
    for (final row in rows) {
      final items = await _dao.getInvoiceItems(row.id);
      result.add(_toInvoice(row, items.map(_toInvoiceItem).toList(),
          clientMap[row.clientId]));
    }
    return result;
  }

  Future<BusinessInvoiceModel?> fetchInvoice(int id, int businessId) async {
    final row = await _dao.getInvoice(id);
    if (row == null) return null;
    final items = await _dao.getInvoiceItems(id);
    final clients = await fetchClients(businessId);
    final client = clients.firstWhere((c) => c.id == row.clientId,
        orElse: () => BusinessClientModel(
          id: 0, businessId: businessId, name: 'Unknown',
          createdAt: DateTime.now(), updatedAt: DateTime.now()));
    return _toInvoice(row, items.map(_toInvoiceItem).toList(), client);
  }

  Future<int> createInvoice(BusinessInvoiceModel inv) async {
    final id = await _dao.insertInvoice(BusinessInvoicesCompanion(
      businessId: Value(inv.businessId), clientId: Value(inv.clientId),
      invoiceNumber: Value(inv.invoiceNumber), status: Value(inv.status),
      notes: Value(inv.notes), taxPercent: Value(inv.taxPercent),
      discountPercent: Value(inv.discountPercent),
      issuedAt: Value(inv.issuedAt), dueAt: Value(inv.dueAt),
      createdAt: Value(DateTime.now()), updatedAt: Value(DateTime.now()),
    ));
    for (final item in inv.items) {
      await _dao.insertInvoiceItem(BusinessInvoiceItemsCompanion(
        invoiceId: Value(id), productId: Value(item.productId),
        name: Value(item.name), unit: Value(item.unit),
        qty: Value(item.qty), unitPrice: Value(item.unitPrice),
      ));
      // Inventory speaks to invoicing: selling an item deducts stock.
      if (item.productId != null) {
        await _dao.adjustStock(item.productId!, -item.qty);
      }
    }
    return id;
  }

  Future<void> updateInvoice(BusinessInvoiceModel inv) async {
    await _dao.updateInvoice(BusinessInvoicesCompanion(
      id: Value(inv.id), businessId: Value(inv.businessId),
      clientId: Value(inv.clientId), invoiceNumber: Value(inv.invoiceNumber),
      status: Value(inv.status), notes: Value(inv.notes),
      taxPercent: Value(inv.taxPercent), discountPercent: Value(inv.discountPercent),
      issuedAt: Value(inv.issuedAt), dueAt: Value(inv.dueAt),
      updatedAt: Value(DateTime.now()),
    ));
    await _dao.deleteInvoiceItems(inv.id);
    for (final item in inv.items) {
      await _dao.insertInvoiceItem(BusinessInvoiceItemsCompanion(
        invoiceId: Value(inv.id), productId: Value(item.productId),
        name: Value(item.name), unit: Value(item.unit),
        qty: Value(item.qty), unitPrice: Value(item.unitPrice),
      ));
    }
  }

  Future<void> deleteInvoice(int id) async {
    await _dao.deleteInvoiceItems(id);
    await _dao.deleteInvoice(id);
  }

  Future<void> updateInvoiceStatus(int id, String status) =>
      _dao.updateInvoiceStatus(id, status);

  // ── Expenses ─────────────────────────────────────────────────
  Future<List<BusinessExpenseModel>> fetchExpenses(int businessId) async {
    final rows = await _dao.getExpenses(businessId);
    final suppliers = await fetchSuppliers(businessId);
    final supplierMap = {for (var s in suppliers) s.id: s};
    return rows.map((r) => _toExpense(r, r.supplierId != null ? supplierMap[r.supplierId] : null)).toList();
  }

  Future<int> createExpense(BusinessExpenseModel e) =>
      _dao.insertExpense(BusinessExpensesCompanion(
        businessId: Value(e.businessId), branchId: Value(e.branchId), supplierId: Value(e.supplierId),
        description: Value(e.description), category: Value(e.category),
        amount: Value(e.amount), expenseDate: Value(e.expenseDate),
        createdAt: Value(DateTime.now()),
      ));

  Future<void> updateExpense(BusinessExpenseModel e) =>
      _dao.updateExpense(BusinessExpensesCompanion(
        id: Value(e.id), businessId: Value(e.businessId), branchId: Value(e.branchId),
        supplierId: Value(e.supplierId), description: Value(e.description),
        category: Value(e.category), amount: Value(e.amount),
        expenseDate: Value(e.expenseDate),
      ));

  Future<void> deleteExpense(int id) => _dao.deleteExpense(id);

  // ── Cashbook Expenses (independent of Business Management) ─────
  Future<List<CashbookExpenseModel>> fetchCashbookExpenses(int businessId) async {
    final rows = await _dao.getCashbookExpenses(businessId);
    final branches = await fetchBranches(businessId);
    final branchMap = {for (var b in branches) b.id: b};
    return rows.map((r) => _toCashbookExpense(r, branchMap[r.branchId])).toList();
  }

  Future<int> createCashbookExpense(CashbookExpenseModel e) =>
      _dao.insertCashbookExpense(CashbookExpensesCompanion(
        businessId: Value(e.businessId), branchId: Value(e.branchId),
        description: Value(e.description), category: Value(e.category),
        amount: Value(e.amount), expenseDate: Value(e.expenseDate),
        createdAt: Value(DateTime.now()),
      ));

  Future<void> updateCashbookExpense(CashbookExpenseModel e) =>
      _dao.updateCashbookExpense(CashbookExpensesCompanion(
        id: Value(e.id), businessId: Value(e.businessId), branchId: Value(e.branchId),
        description: Value(e.description), category: Value(e.category),
        amount: Value(e.amount), expenseDate: Value(e.expenseDate),
      ));

  Future<void> deleteCashbookExpense(int id) => _dao.deleteCashbookExpense(id);

  // ── Mappers ─────────────────────────────────────────────────
  BusinessModel _toBusiness(BusinessData r) => BusinessModel(
    id: r.id, name: r.name, address: r.address, phone: r.phone,
    email: r.email, tin: r.tin, currency: r.currency, isActive: r.isActive,
    createdAt: r.createdAt, updatedAt: r.updatedAt,
  );

  BusinessClientModel _toClient(BusinessClientData r) => BusinessClientModel(
    id: r.id, businessId: r.businessId, name: r.name, phone: r.phone,
    email: r.email, address: r.address, createdAt: r.createdAt, updatedAt: r.updatedAt,
  );

  BusinessSupplierModel _toSupplier(BusinessSupplierData r) => BusinessSupplierModel(
    id: r.id, businessId: r.businessId, name: r.name, phone: r.phone,
    email: r.email, address: r.address, createdAt: r.createdAt, updatedAt: r.updatedAt,
  );

  BusinessProductModel _toProduct(BusinessProductData r) => BusinessProductModel(
    id: r.id, businessId: r.businessId, name: r.name, description: r.description,
    unit: r.unit, price: r.price, stockQty: r.stockQty,
    lowStockAlert: r.lowStockAlert, createdAt: r.createdAt, updatedAt: r.updatedAt,
  );

  BusinessInvoiceModel _toInvoice(BusinessInvoiceData r,
      List<BusinessInvoiceItemModel> items, BusinessClientModel? client) =>
      BusinessInvoiceModel(
        id: r.id, businessId: r.businessId, clientId: r.clientId,
        invoiceNumber: r.invoiceNumber, status: r.status, notes: r.notes,
        taxPercent: r.taxPercent, discountPercent: r.discountPercent,
        issuedAt: r.issuedAt, dueAt: r.dueAt,
        createdAt: r.createdAt, updatedAt: r.updatedAt,
        items: items, client: client,
      );

  BusinessInvoiceItemModel _toInvoiceItem(BusinessInvoiceItemData r) =>
      BusinessInvoiceItemModel(
        id: r.id, invoiceId: r.invoiceId, productId: r.productId,
        name: r.name, unit: r.unit, qty: r.qty, unitPrice: r.unitPrice,
      );

  BusinessExpenseModel _toExpense(BusinessExpenseData r, BusinessSupplierModel? supplier) =>
      BusinessExpenseModel(
        id: r.id, businessId: r.businessId, branchId: r.branchId, supplierId: r.supplierId,
        description: r.description, category: r.category,
        amount: r.amount, expenseDate: r.expenseDate,
        createdAt: r.createdAt, supplier: supplier,
      );

  CashbookExpenseModel _toCashbookExpense(CashbookExpenseData r, BranchModel? branch) =>
      CashbookExpenseModel(
        id: r.id, businessId: r.businessId, branchId: r.branchId,
        description: r.description, category: r.category,
        amount: r.amount, expenseDate: r.expenseDate,
        createdAt: r.createdAt, branch: branch,
      );

  // ── Branches ────────────────────────────────────────────────
  Future<List<BranchModel>> fetchBranches(int businessId) async {
    final rows = await _dao.getBranches(businessId);
    return rows.map(_toBranch).toList();
  }

  Future<int> createBranch(BranchModel b) =>
      _dao.insertBranch(BranchesCompanion(
        businessId: Value(b.businessId), name: Value(b.name),
        location: Value(b.location), phone: Value(b.phone),
        email: Value(b.email), managerName: Value(b.managerName),
        isMain: Value(b.isMain), createdAt: Value(DateTime.now()),
      ));

  Future<void> updateBranch(BranchModel b) =>
      _dao.updateBranch(BranchesCompanion(
        id: Value(b.id), businessId: Value(b.businessId), name: Value(b.name),
        location: Value(b.location), phone: Value(b.phone),
        email: Value(b.email), managerName: Value(b.managerName),
        isMain: Value(b.isMain),
      ));

  Future<void> deleteBranch(int id) => _dao.deleteBranch(id);

  // ── Sales ───────────────────────────────────────────────────
  Future<List<BusinessSaleModel>> fetchSales(int businessId) async {
    final rows = await _dao.getSales(businessId);
    final branches = await fetchBranches(businessId);
    final branchMap = {for (var b in branches) b.id: b};
    return rows.map((r) => _toSale(r, r.branchId != null ? branchMap[r.branchId] : null)).toList();
  }

  Future<int> createSale(BusinessSaleModel s) =>
      _dao.insertSale(BusinessSalesCompanion(
        businessId: Value(s.businessId), branchId: Value(s.branchId),
        clientId: Value(s.clientId), description: Value(s.description),
        amount: Value(s.amount), saleDate: Value(s.saleDate),
        createdAt: Value(DateTime.now()),
      ));

  Future<void> updateSale(BusinessSaleModel s) =>
      _dao.updateSale(BusinessSalesCompanion(
        id: Value(s.id), businessId: Value(s.businessId), branchId: Value(s.branchId),
        clientId: Value(s.clientId), description: Value(s.description),
        amount: Value(s.amount), saleDate: Value(s.saleDate),
      ));

  Future<void> deleteSale(int id) => _dao.deleteSale(id);

  // ── Reports ─────────────────────────────────────────────────
  Future<BusinessReportModel> fetchDailyReport(int businessId, DateTime day, {int? branchId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final t = await _dao.getReport(businessId: businessId, branchId: branchId, start: start, end: end);
    return BusinessReportModel(totalSales: t['sales']!, totalExpenses: t['expenses']!, totalOthers: t['others'] ?? 0, netProfit: t['net']!);
  }

  Future<BusinessReportModel> fetchMonthlyReport(int businessId, int year, int month, {int? branchId}) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final t = await _dao.getReport(businessId: businessId, branchId: branchId, start: start, end: end);
    return BusinessReportModel(totalSales: t['sales']!, totalExpenses: t['expenses']!, totalOthers: t['others'] ?? 0, netProfit: t['net']!);
  }

  // ── Mappers ─────────────────────────────────────────────────
  BranchModel _toBranch(BranchData r) => BranchModel(
    id: r.id, businessId: r.businessId, name: r.name,
    location: r.location, phone: r.phone, email: r.email,
    managerName: r.managerName, isMain: r.isMain, createdAt: r.createdAt,
  );

  BusinessSaleModel _toSale(BusinessSaleData r, BranchModel? branch) => BusinessSaleModel(
    id: r.id, businessId: r.businessId, branchId: r.branchId, clientId: r.clientId,
    description: r.description, amount: r.amount,
    saleDate: r.saleDate, createdAt: r.createdAt, branch: branch,
  );

  // ── Other Entries ─────────────────────────────────────────────
  Future<List<BusinessOtherModel>> fetchOthers(int businessId) async {
    final rows = await _dao.getOtherEntries(businessId);
    final branches = await fetchBranches(businessId);
    final branchMap = {for (var b in branches) b.id: b};
    return rows.map((r) => _toOther(r, r.branchId != null ? branchMap[r.branchId] : null)).toList();
  }

  Future<int> createOther(BusinessOtherModel o) =>
      _dao.insertOtherEntry(BusinessOtherEntriesCompanion(
        businessId: Value(o.businessId), branchId: Value(o.branchId),
        description: Value(o.description), amount: Value(o.amount),
        isInflow: Value(o.isInflow), entryDate: Value(o.entryDate),
        createdAt: Value(DateTime.now()),
      ));

  Future<void> updateOther(BusinessOtherModel o) =>
      _dao.updateOtherEntry(BusinessOtherEntriesCompanion(
        id: Value(o.id), businessId: Value(o.businessId), branchId: Value(o.branchId),
        description: Value(o.description), amount: Value(o.amount),
        isInflow: Value(o.isInflow), entryDate: Value(o.entryDate),
      ));

  Future<void> deleteOther(int id) => _dao.deleteOtherEntry(id);

  BusinessOtherModel _toOther(BusinessOtherEntryData r, BranchModel? branch) => BusinessOtherModel(
    id: r.id, businessId: r.businessId, branchId: r.branchId,
    description: r.description, amount: r.amount, isInflow: r.isInflow,
    entryDate: r.entryDate, createdAt: r.createdAt, branch: branch,
  );
}
