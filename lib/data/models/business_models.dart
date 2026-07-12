// ── Business Model ────────────────────────────────────────────
class BusinessModel {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? tin;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.tin,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessModel copyWith({
    int? id, String? name, String? address, String? phone,
    String? email, String? tin, String? currency, bool? isActive,
    DateTime? createdAt, DateTime? updatedAt,
  }) => BusinessModel(
    id: id ?? this.id, name: name ?? this.name,
    address: address ?? this.address, phone: phone ?? this.phone,
    email: email ?? this.email, tin: tin ?? this.tin,
    currency: currency ?? this.currency, isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ── Client Model ──────────────────────────────────────────────
class BusinessClientModel {
  final int id;
  final int businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessClientModel({
    required this.id, required this.businessId, required this.name,
    this.phone, this.email, this.address,
    required this.createdAt, required this.updatedAt,
  });

  BusinessClientModel copyWith({
    int? id, int? businessId, String? name, String? phone,
    String? email, String? address, DateTime? createdAt, DateTime? updatedAt,
  }) => BusinessClientModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    name: name ?? this.name, phone: phone ?? this.phone,
    email: email ?? this.email, address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ── Supplier Model ────────────────────────────────────────────
class BusinessSupplierModel {
  final int id;
  final int businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessSupplierModel({
    required this.id, required this.businessId, required this.name,
    this.phone, this.email, this.address,
    required this.createdAt, required this.updatedAt,
  });

  BusinessSupplierModel copyWith({
    int? id, int? businessId, String? name, String? phone,
    String? email, String? address, DateTime? createdAt, DateTime? updatedAt,
  }) => BusinessSupplierModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    name: name ?? this.name, phone: phone ?? this.phone,
    email: email ?? this.email, address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ── Product Model ─────────────────────────────────────────────
class BusinessProductModel {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final String unit;
  final double price;
  final double stockQty;
  final double lowStockAlert;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProductModel({
    required this.id, required this.businessId, required this.name,
    this.description, required this.unit, required this.price,
    required this.stockQty, required this.lowStockAlert,
    required this.createdAt, required this.updatedAt,
  });

  bool get isLowStock => stockQty <= lowStockAlert;
  bool get isOutOfStock => stockQty <= 0;

  BusinessProductModel copyWith({
    int? id, int? businessId, String? name, String? description,
    String? unit, double? price, double? stockQty, double? lowStockAlert,
    DateTime? createdAt, DateTime? updatedAt,
  }) => BusinessProductModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    name: name ?? this.name, description: description ?? this.description,
    unit: unit ?? this.unit, price: price ?? this.price,
    stockQty: stockQty ?? this.stockQty, lowStockAlert: lowStockAlert ?? this.lowStockAlert,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ── Invoice Item Model ────────────────────────────────────────
class BusinessInvoiceItemModel {
  final int id;
  final int invoiceId;
  final int? productId;
  final String name;
  final String unit;
  final double qty;
  final double unitPrice;

  const BusinessInvoiceItemModel({
    required this.id, required this.invoiceId, this.productId,
    required this.name, required this.unit,
    required this.qty, required this.unitPrice,
  });

  double get total => qty * unitPrice;

  BusinessInvoiceItemModel copyWith({
    int? id, int? invoiceId, int? productId, String? name,
    String? unit, double? qty, double? unitPrice,
  }) => BusinessInvoiceItemModel(
    id: id ?? this.id, invoiceId: invoiceId ?? this.invoiceId,
    productId: productId ?? this.productId, name: name ?? this.name,
    unit: unit ?? this.unit, qty: qty ?? this.qty, unitPrice: unitPrice ?? this.unitPrice,
  );
}

// ── Invoice Model ─────────────────────────────────────────────
class BusinessInvoiceModel {
  final int id;
  final int businessId;
  final int? branchId;
  final int clientId;
  final String invoiceNumber;
  final String status; // draft, sent, paid, overdue
  final String? notes;
  final double taxPercent;
  final double discountPercent;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BusinessInvoiceItemModel> items;
  final BusinessClientModel? client;

  const BusinessInvoiceModel({
    required this.id, required this.businessId, this.branchId, required this.clientId,
    required this.invoiceNumber, required this.status, this.notes,
    required this.taxPercent, required this.discountPercent,
    required this.issuedAt, required this.dueAt,
    required this.createdAt, required this.updatedAt,
    this.items = const [], this.client,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * discountPercent / 100;
  double get taxAmount => (subtotal - discountAmount) * taxPercent / 100;
  double get total => subtotal - discountAmount + taxAmount;

  bool get isPaid => status == 'paid';
  bool get isOverdue => status != 'paid' && dueAt.isBefore(DateTime.now());

  BusinessInvoiceModel copyWith({
    int? id, int? businessId, int? branchId, int? clientId, String? invoiceNumber,
    String? status, String? notes, double? taxPercent, double? discountPercent,
    DateTime? issuedAt, DateTime? dueAt, DateTime? createdAt, DateTime? updatedAt,
    List<BusinessInvoiceItemModel>? items, BusinessClientModel? client,
  }) => BusinessInvoiceModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    clientId: clientId ?? this.clientId, invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    status: status ?? this.status, notes: notes ?? this.notes,
    taxPercent: taxPercent ?? this.taxPercent, discountPercent: discountPercent ?? this.discountPercent,
    issuedAt: issuedAt ?? this.issuedAt, dueAt: dueAt ?? this.dueAt,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    items: items ?? this.items, client: client ?? this.client,
  );
}

// ── Business Expense Model ────────────────────────────────────
class CashbookExpenseModel {
  final int id;
  final int businessId;
  final int branchId;
  final String description;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final DateTime createdAt;
  final BranchModel? branch;

  const CashbookExpenseModel({
    required this.id, required this.businessId, required this.branchId,
    required this.description, required this.category,
    required this.amount, required this.expenseDate,
    required this.createdAt, this.branch,
  });

  CashbookExpenseModel copyWith({
    int? id, int? businessId, int? branchId, String? description,
    String? category, double? amount, DateTime? expenseDate,
    DateTime? createdAt, BranchModel? branch,
  }) => CashbookExpenseModel(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    description: description ?? this.description,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    expenseDate: expenseDate ?? this.expenseDate,
    createdAt: createdAt ?? this.createdAt,
    branch: branch ?? this.branch,
  );
}

class BusinessExpenseModel {
  final int id;
  final int businessId;
  final int? branchId;
  final int? supplierId;
  final String description;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final DateTime createdAt;
  final BusinessSupplierModel? supplier;

  const BusinessExpenseModel({
    required this.id, required this.businessId, this.branchId, this.supplierId,
    required this.description, required this.category,
    required this.amount, required this.expenseDate,
    required this.createdAt, this.supplier,
  });

  BusinessExpenseModel copyWith({
    int? id, int? businessId, int? branchId, int? supplierId, String? description,
    String? category, double? amount, DateTime? expenseDate,
    DateTime? createdAt, BusinessSupplierModel? supplier,
  }) => BusinessExpenseModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    supplierId: supplierId ?? this.supplierId,
    description: description ?? this.description,
    category: category ?? this.category,
    amount: amount ?? this.amount, expenseDate: expenseDate ?? this.expenseDate,
    createdAt: createdAt ?? this.createdAt, supplier: supplier ?? this.supplier,
  );
}

// ?? Branch Model ?????????????????????????????????????????????
class BranchModel {
  final int id;
  final int businessId;
  final String name;
  final String? location;
  final String? phone;
  final String? email;
  final String? managerName;
  final bool isMain;
  final DateTime createdAt;

  const BranchModel({
    required this.id, required this.businessId, required this.name,
    this.location, this.phone, this.email, this.managerName,
    required this.isMain, required this.createdAt,
  });

  BranchModel copyWith({
    int? id, int? businessId, String? name, String? location,
    String? phone, String? email, String? managerName,
    bool? isMain, DateTime? createdAt,
  }) => BranchModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    name: name ?? this.name, location: location ?? this.location,
    phone: phone ?? this.phone, email: email ?? this.email,
    managerName: managerName ?? this.managerName,
    isMain: isMain ?? this.isMain, createdAt: createdAt ?? this.createdAt,
  );
}

// ?? Business Sale Model ??????????????????????????????????????
class BusinessSaleModel {
  final int id;
  final int businessId;
  final int? branchId;
  final int? clientId;
  final String description;
  final double amount;
  final DateTime saleDate;
  final DateTime createdAt;
  final BranchModel? branch;

  const BusinessSaleModel({
    required this.id, required this.businessId, this.branchId, this.clientId,
    required this.description, required this.amount,
    required this.saleDate, required this.createdAt, this.branch,
  });

  BusinessSaleModel copyWith({
    int? id, int? businessId, int? branchId, int? clientId,
    String? description, double? amount, DateTime? saleDate,
    DateTime? createdAt, BranchModel? branch,
  }) => BusinessSaleModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId, clientId: clientId ?? this.clientId,
    description: description ?? this.description, amount: amount ?? this.amount,
    saleDate: saleDate ?? this.saleDate, createdAt: createdAt ?? this.createdAt,
    branch: branch ?? this.branch,
  );
}

// ?? Business Report Model ????????????????????????????????????
class BusinessReportModel {
  final double totalSales;
  final double totalExpenses;
  final double totalOthers;
  final double netProfit;

  const BusinessReportModel({
    required this.totalSales, required this.totalExpenses,
    this.totalOthers = 0, required this.netProfit,
  });
}




class BusinessOtherModel {
  final int id;
  final int businessId;
  final int? branchId;
  final String description;
  final double amount;
  final bool isInflow;
  final DateTime entryDate;
  final DateTime createdAt;
  final BranchModel? branch;

  const BusinessOtherModel({
    required this.id, required this.businessId, this.branchId,
    required this.description, required this.amount, required this.isInflow,
    required this.entryDate, required this.createdAt, this.branch,
  });

  BusinessOtherModel copyWith({
    int? id, int? businessId, int? branchId, String? description,
    double? amount, bool? isInflow, DateTime? entryDate,
    DateTime? createdAt, BranchModel? branch,
  }) => BusinessOtherModel(
    id: id ?? this.id, businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId, description: description ?? this.description,
    amount: amount ?? this.amount, isInflow: isInflow ?? this.isInflow,
    entryDate: entryDate ?? this.entryDate, createdAt: createdAt ?? this.createdAt,
    branch: branch ?? this.branch,
  );
}
