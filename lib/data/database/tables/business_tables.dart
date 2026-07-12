import 'package:drift/drift.dart';

// ── Businesses ────────────────────────────────────────────────
@DataClassName('BusinessData')
class Businesses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get tin => text().nullable()(); // Tax ID
  TextColumn get currency => text().withDefault(const Constant('UGX'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Clients ───────────────────────────────────────────────────
@DataClassName('BusinessClientData')
class BusinessClients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Suppliers ─────────────────────────────────────────────────
@DataClassName('BusinessSupplierData')
class BusinessSuppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Products / Inventory ──────────────────────────────────────
@DataClassName('BusinessProductData')
class BusinessProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn get stockQty => real().withDefault(const Constant(0.0))();
  RealColumn get lowStockAlert => real().withDefault(const Constant(5.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Invoices ──────────────────────────────────────────────────
@DataClassName('BusinessInvoiceData')
class BusinessInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  IntColumn get branchId => integer().nullable().references(Branches, #id)();
  IntColumn get clientId => integer().references(BusinessClients, #id)();
  TextColumn get invoiceNumber => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get notes => text().nullable()();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get issuedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Invoice Items ─────────────────────────────────────────────
@DataClassName('BusinessInvoiceItemData')
class BusinessInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(BusinessInvoices, #id)();
  IntColumn get productId => integer().nullable().references(BusinessProducts, #id)();
  TextColumn get name => text()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get qty => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
}

// ── Business Expenses ─────────────────────────────────────────
@DataClassName('BusinessExpenseData')
class BusinessExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  IntColumn get branchId => integer().nullable().references(Branches, #id)();
  IntColumn get supplierId => integer().nullable().references(BusinessSuppliers, #id)();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}


@DataClassName('BranchData')
class Branches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get location => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get managerName => text().nullable()();
  BoolColumn get isMain => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BusinessSaleData')
class BusinessSales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  IntColumn get branchId => integer().nullable().references(Branches, #id)();
  IntColumn get clientId => integer().nullable().references(BusinessClients, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}


@DataClassName('CashbookExpenseData')
class CashbookExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  IntColumn get branchId => integer().references(Branches, #id)();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BusinessOtherEntryData')
class BusinessOtherEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  IntColumn get branchId => integer().nullable().references(Branches, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  BoolColumn get isInflow => boolean().withDefault(const Constant(true))();
  DateTimeColumn get entryDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
