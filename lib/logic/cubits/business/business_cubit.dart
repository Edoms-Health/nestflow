import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

// ── States ────────────────────────────────────────────────────
abstract class BusinessState extends Equatable {
  @override List<Object?> get props => [];
}

class BusinessLoading extends BusinessState {}

class BusinessLoaded extends BusinessState {
  final List<BusinessModel> businesses;
  final BusinessModel? active;
  final List<BusinessClientModel> clients;
  final List<BusinessSupplierModel> suppliers;
  final List<BusinessProductModel> products;
  final List<BusinessInvoiceModel> invoices;
  final List<BusinessExpenseModel> expenses;
  final List<BusinessProductModel> lowStockProducts;
  final List<BranchModel> branches;
  final List<BusinessSaleModel> sales;
  final List<BusinessOtherModel> others;
  final List<CashbookExpenseModel> cashbookExpenses;

  BusinessLoaded({
    required this.businesses, this.active,
    this.clients = const [], this.suppliers = const [],
    this.products = const [], this.invoices = const [],
    this.expenses = const [], this.lowStockProducts = const [],
    this.branches = const [], this.sales = const [], this.others = const [],
    this.cashbookExpenses = const [],
  });

  @override
  List<Object?> get props => [businesses, active, clients, suppliers,
      products, invoices, expenses, lowStockProducts, branches, sales, others, cashbookExpenses];

  double get totalExpenses => expenses.fold(0, (s, e) => s + e.amount);
  double get totalInvoiced => invoices.fold(0, (s, i) => s + i.total);
  double get totalPaid => invoices.where((i) => i.isPaid).fold(0, (s, i) => s + i.total);
  double get totalPending => totalInvoiced - totalPaid;
  double get netProfit => totalPaid - totalExpenses;

  // ── Cashbook (My Business) — independent of Business Management ────
  double get totalCashbookSales => sales.fold(0, (s, x) => s + x.amount);
  double get totalCashbookExpenses => cashbookExpenses.fold(0, (s, x) => s + x.amount);
  double get totalOthersNet => others.fold(0, (s, x) => s + (x.isInflow ? x.amount : -x.amount));
  double get netCashbook => totalCashbookSales - totalCashbookExpenses + totalOthersNet;
}

class BusinessError extends BusinessState {
  final String message;
  BusinessError(this.message);
  @override List<Object?> get props => [message];
}

class BusinessSuccess extends BusinessState {
  final String message;
  BusinessSuccess(this.message);
  @override List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class BusinessCubit extends Cubit<BusinessState> {
  final BusinessService _service = BusinessService();

  BusinessCubit() : super(BusinessLoading());

  Future<void> load() async {
    try {
      final businesses = await _service.fetchAll();
      final active = businesses.isEmpty ? null :
          businesses.firstWhere((b) => b.isActive, orElse: () => businesses.first);

      if (active == null) {
        emit(BusinessLoaded(businesses: businesses));
        return;
      }

      final clients = await _service.fetchClients(active.id);
      final suppliers = await _service.fetchSuppliers(active.id);
      final products = await _service.fetchProducts(active.id);
      final invoices = await _service.fetchInvoices(active.id);
      final expenses = await _service.fetchExpenses(active.id);
      final lowStock = await _service.fetchLowStock(active.id);
      final branches = await _service.fetchBranches(active.id);
      final sales = await _service.fetchSales(active.id);
      final others = await _service.fetchOthers(active.id);
      final cashbookExpenses = await _service.fetchCashbookExpenses(active.id);

      emit(BusinessLoaded(
        businesses: businesses, active: active,
        clients: clients, suppliers: suppliers,
        products: products, invoices: invoices,
        expenses: expenses, lowStockProducts: lowStock,
        branches: branches, sales: sales, others: others,
        cashbookExpenses: cashbookExpenses,
      ));
    } catch (e) {
      emit(BusinessError('Failed to load business data'));
    }
  }

  // ── Business CRUD ────────────────────────────────────────────
  Future<void> createBusiness(BusinessModel b) async {
    try {
      final id = await _service.create(b);
      if (b.isActive) await _service.setActive(id);
      await load();
      emit(BusinessSuccess('Business created!'));
    } catch (e) { emit(BusinessError('Failed to create business')); }
  }

  Future<void> updateBusiness(BusinessModel b) async {
    try {
      await _service.update(b);
      await load();
      emit(BusinessSuccess('Business updated!'));
    } catch (e) { emit(BusinessError('Failed to update business')); }
  }

  Future<void> switchBusiness(int id) async {
    try {
      await _service.setActive(id);
      await load();
    } catch (e) { emit(BusinessError('Failed to switch business')); }
  }

  Future<void> deleteBusiness(int id) async {
    try {
      await _service.delete(id);
      await load();
      emit(BusinessSuccess('Business deleted'));
    } catch (e) { emit(BusinessError('Failed to delete business')); }
  }

  // ── Client CRUD ──────────────────────────────────────────────
  Future<void> createClient(BusinessClientModel c) async {
    try {
      await _service.createClient(c);
      await load();
      emit(BusinessSuccess('Client added!'));
    } catch (e) { emit(BusinessError('Failed to add client')); }
  }

  Future<void> updateClient(BusinessClientModel c) async {
    try {
      await _service.updateClient(c);
      await load();
      emit(BusinessSuccess('Client updated!'));
    } catch (e) { emit(BusinessError('Failed to update client')); }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _service.deleteClient(id);
      await load();
      emit(BusinessSuccess('Client deleted'));
    } catch (e) { emit(BusinessError('Failed to delete client')); }
  }

  // ── Supplier CRUD ────────────────────────────────────────────
  Future<void> createSupplier(BusinessSupplierModel s) async {
    try {
      await _service.createSupplier(s);
      await load();
      emit(BusinessSuccess('Supplier added!'));
    } catch (e) { emit(BusinessError('Failed to add supplier')); }
  }

  Future<void> updateSupplier(BusinessSupplierModel s) async {
    try {
      await _service.updateSupplier(s);
      await load();
      emit(BusinessSuccess('Supplier updated!'));
    } catch (e) { emit(BusinessError('Failed to update supplier')); }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _service.deleteSupplier(id);
      await load();
      emit(BusinessSuccess('Supplier deleted'));
    } catch (e) { emit(BusinessError('Failed to delete supplier')); }
  }

  // ── Product CRUD ─────────────────────────────────────────────
  Future<void> createProduct(BusinessProductModel p) async {
    try {
      await _service.createProduct(p);
      await load();
      emit(BusinessSuccess('Product added!'));
    } catch (e) { emit(BusinessError('Failed to add product')); }
  }

  Future<void> updateProduct(BusinessProductModel p) async {
    try {
      await _service.updateProduct(p);
      await load();
      emit(BusinessSuccess('Product updated!'));
    } catch (e) { emit(BusinessError('Failed to update product')); }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _service.deleteProduct(id);
      await load();
      emit(BusinessSuccess('Product deleted'));
    } catch (e) { emit(BusinessError('Failed to delete product')); }
  }

  Future<void> adjustStock(int productId, double qty, String action) async {
    try {
      await _service.adjustStock(productId, action == 'add' ? qty : -qty);
      await load();
      emit(BusinessSuccess('Stock ${action == 'add' ? 'added' : 'removed'}!'));
    } catch (e) { emit(BusinessError('Failed to adjust stock')); }
  }

  // ── Invoice CRUD ─────────────────────────────────────────────
  Future<void> createInvoice(BusinessInvoiceModel inv) async {
    try {
      await _service.createInvoice(inv);
      await load();
      emit(BusinessSuccess('Invoice created!'));
    } catch (e) { emit(BusinessError('Failed to create invoice')); }
  }

  Future<void> updateInvoice(BusinessInvoiceModel inv) async {
    try {
      await _service.updateInvoice(inv);
      await load();
      emit(BusinessSuccess('Invoice updated!'));
    } catch (e) { emit(BusinessError('Failed to update invoice')); }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _service.deleteInvoice(id);
      await load();
      emit(BusinessSuccess('Invoice deleted'));
    } catch (e) { emit(BusinessError('Failed to delete invoice')); }
  }

  Future<void> updateInvoiceStatus(int id, String status) async {
    try {
      await _service.updateInvoiceStatus(id, status);
      await load();
      emit(BusinessSuccess('Invoice marked as $status'));
    } catch (e) { emit(BusinessError('Failed to update invoice status')); }
  }

  // ── Expense CRUD ─────────────────────────────────────────────
  Future<void> createExpense(BusinessExpenseModel e) async {
    try {
      await _service.createExpense(e);
      await load();
      emit(BusinessSuccess('Expense added!'));
    } catch (e) { emit(BusinessError('Failed to add expense')); }
  }

  Future<void> updateExpense(BusinessExpenseModel e) async {
    try {
      await _service.updateExpense(e);
      await load();
      emit(BusinessSuccess('Expense updated!'));
    } catch (e) { emit(BusinessError('Failed to update expense')); }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _service.deleteExpense(id);
      await load();
      emit(BusinessSuccess('Expense deleted'));
    } catch (e) { emit(BusinessError('Failed to delete expense')); }
  }
  // ── Cashbook Expense CRUD (My Business, independent) ────────────
  Future<void> createCashbookExpense(CashbookExpenseModel e) async {
    try {
      await _service.createCashbookExpense(e);
      await load();
      emit(BusinessSuccess('Expense added!'));
    } catch (e) { emit(BusinessError('Failed to add expense')); }
  }
  Future<void> updateCashbookExpense(CashbookExpenseModel e) async {
    try {
      await _service.updateCashbookExpense(e);
      await load();
      emit(BusinessSuccess('Expense updated!'));
    } catch (e) { emit(BusinessError('Failed to update expense')); }
  }
  Future<void> deleteCashbookExpense(int id) async {
    try {
      await _service.deleteCashbookExpense(id);
      await load();
      emit(BusinessSuccess('Expense deleted'));
    } catch (e) { emit(BusinessError('Failed to delete expense')); }
  }

  // ── Invoice number generator ──────────────────────────────────
  String generateInvoiceNumber(List<BusinessInvoiceModel> invoices) {
    final count = invoices.length + 1;
    final year = DateTime.now().year;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }

  // ── Branch CRUD ───────────────────────────────────────────────
  Future<void> createBranch(BranchModel b) async {
    try {
      await _service.createBranch(b);
      await load();
      emit(BusinessSuccess('Branch added!'));
    } catch (e) { emit(BusinessError('Failed to add branch')); }
  }

  Future<void> updateBranch(BranchModel b) async {
    try {
      await _service.updateBranch(b);
      await load();
      emit(BusinessSuccess('Branch updated!'));
    } catch (e) { emit(BusinessError('Failed to update branch')); }
  }

  Future<void> deleteBranch(int id) async {
    try {
      await _service.deleteBranch(id);
      await load();
      emit(BusinessSuccess('Branch deleted'));
    } catch (e) { emit(BusinessError('Failed to delete branch')); }
  }

  // ── Sale CRUD ─────────────────────────────────────────────────
  Future<void> createSale(BusinessSaleModel s) async {
    try {
      await _service.createSale(s);
      await load();
      emit(BusinessSuccess('Sale recorded!'));
    } catch (e) { emit(BusinessError('Failed to record sale')); }
  }

  Future<void> updateSale(BusinessSaleModel s) async {
    try {
      await _service.updateSale(s);
      await load();
      emit(BusinessSuccess('Sale updated!'));
    } catch (e) { emit(BusinessError('Failed to update sale')); }
  }

  Future<void> deleteSale(int id) async {
    try {
      await _service.deleteSale(id);
      await load();
      emit(BusinessSuccess('Sale deleted'));
    } catch (e) { emit(BusinessError('Failed to delete sale')); }
  }

  // ── Reports ───────────────────────────────────────────────────
  Future<BusinessReportModel> getDailyReport(int businessId, DateTime day, {int? branchId}) =>
      _service.fetchDailyReport(businessId, day, branchId: branchId);

  Future<BusinessReportModel> getMonthlyReport(int businessId, int year, int month, {int? branchId}) =>
      _service.fetchMonthlyReport(businessId, year, month, branchId: branchId);

  // ── Other Entry CRUD ────────────────────────────────────────────
  Future<void> createOther(BusinessOtherModel o) async {
    try {
      await _service.createOther(o);
      await load();
      emit(BusinessSuccess('Entry added!'));
    } catch (e) { emit(BusinessError('Failed to add entry')); }
  }

  Future<void> updateOther(BusinessOtherModel o) async {
    try {
      await _service.updateOther(o);
      await load();
      emit(BusinessSuccess('Entry updated!'));
    } catch (e) { emit(BusinessError('Failed to update entry')); }
  }

  Future<void> deleteOther(int id) async {
    try {
      await _service.deleteOther(id);
      await load();
      emit(BusinessSuccess('Entry deleted'));
    } catch (e) { emit(BusinessError('Failed to delete entry')); }
  }
}
