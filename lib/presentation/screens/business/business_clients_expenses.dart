import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

// ── Clients Tab ───────────────────────────────────────────────
class BusinessClientsTab extends StatefulWidget {
  final BusinessLoaded loaded;
  const BusinessClientsTab({super.key, required this.loaded});

  @override
  State<BusinessClientsTab> createState() => _BusinessClientsTabState();
}

class _BusinessClientsTabState extends State<BusinessClientsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        TabBar(
          controller: _tab,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [Tab(text: 'Clients'), Tab(text: 'Suppliers')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ContactList(
                items: widget.loaded.clients.map((c) => _ContactItem(
                  id: c.id, name: c.name, phone: c.phone, email: c.email,
                  address: c.address,
                )).toList(),
                type: 'client',
                loaded: widget.loaded,
                onEdit: (id) {
                  final c = widget.loaded.clients.firstWhere((c) => c.id == id);
                  _showForm(context, c, null);
                },
                onDelete: (id) => context.read<BusinessCubit>().deleteClient(id),
              ),
              _ContactList(
                items: widget.loaded.suppliers.map((s) => _ContactItem(
                  id: s.id, name: s.name, phone: s.phone, email: s.email,
                  address: s.address,
                )).toList(),
                type: 'supplier',
                loaded: widget.loaded,
                onEdit: (id) {
                  final s = widget.loaded.suppliers.firstWhere((s) => s.id == id);
                  _showForm(context, null, s);
                },
                onDelete: (id) => context.read<BusinessCubit>().deleteSupplier(id),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showForm(context, null, null, isClient: true),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Client'),
            )),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showForm(context, null, null, isClient: false),
              icon: const Icon(Icons.store_outlined),
              label: const Text('Add Supplier'),
            )),
          ]),
        ),
      ],
    );
  }

  void _showForm(BuildContext context,
      BusinessClientModel? client, BusinessSupplierModel? supplier,
      {bool? isClient}) {
    final type = isClient ?? (client != null) ? 'client' : 'supplier';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: ClientSupplierFormScreen(
          loaded: widget.loaded,
          entity: client ?? supplier,
          type: type,
        ),
      ),
    ));
  }
}

class _ContactItem {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  _ContactItem({required this.id, required this.name,
      this.phone, this.email, this.address});
}

class _ContactList extends StatelessWidget {
  final List<_ContactItem> items;
  final String type;
  final BusinessLoaded loaded;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const _ContactList({required this.items, required this.type,
      required this.loaded, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (items.isEmpty) {
      return Center(child: Text('No ${type}s yet',
          style: TextStyle(color: colors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              child: Text(item.name[0].toUpperCase(),
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.phone != null) Text(item.phone!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                if (item.email != null) Text(item.email!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit(item.id);
                if (v == 'delete') onDelete(item.id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Client/Supplier Form ──────────────────────────────────────
class ClientSupplierFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final dynamic entity; // BusinessClientModel or BusinessSupplierModel
  final String type; // 'client' or 'supplier'
  const ClientSupplierFormScreen({super.key, required this.loaded,
      this.entity, required this.type});

  @override
  State<ClientSupplierFormScreen> createState() => _ClientSupplierFormScreenState();
}

class _ClientSupplierFormScreenState extends State<ClientSupplierFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entity != null) {
      _nameCtrl.text = widget.entity.name ?? '';
      _phoneCtrl.text = widget.entity.phone ?? '';
      _emailCtrl.text = widget.entity.email ?? '';
      _addressCtrl.text = widget.entity.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  bool get _isClient => widget.type == 'client';

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessCubit, BusinessState>(
      listener: (context, state) {
        if (state is BusinessSuccess) Navigator.pop(context);
        if (state is BusinessError) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.entity == null ? 'New' : 'Edit'} '
              '${_isClient ? 'Client' : 'Supplier'}'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: '${_isClient ? 'Client' : 'Supplier'} Name *',
                    prefixIcon: Icon(_isClient
                        ? Icons.person_outline : Icons.store_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.entity == null
                        ? 'Add ${_isClient ? 'Client' : 'Supplier'}'
                        : 'Update ${_isClient ? 'Client' : 'Supplier'}'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_isClient ? 'Client' : 'Supplier'} name is required')));
      return;
    }
    setState(() => _loading = true);
    final cubit = context.read<BusinessCubit>();
    final now = DateTime.now();
    final bizId = widget.loaded.active!.id;

    if (_isClient) {
      final c = BusinessClientModel(
        id: widget.entity?.id ?? 0, businessId: bizId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        createdAt: widget.entity?.createdAt ?? now, updatedAt: now,
      );
      if (widget.entity == null) cubit.createClient(c);
      else cubit.updateClient(c);
    } else {
      final s = BusinessSupplierModel(
        id: widget.entity?.id ?? 0, businessId: bizId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        createdAt: widget.entity?.createdAt ?? now, updatedAt: now,
      );
      if (widget.entity == null) cubit.createSupplier(s);
      else cubit.updateSupplier(s);
    }
  }
}

// ── Expenses Tab ──────────────────────────────────────────────
class BusinessExpensesTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessExpensesTab({super.key, required this.loaded});

  static const _categories = [
    'General', 'Rent', 'Utilities', 'Salaries', 'Transport',
    'Marketing', 'Equipment', 'Supplies', 'Maintenance', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final currency = Money.defaultCurrency;

    if (loaded.expenses.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off_outlined, size: 70,
              color: colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No expenses yet', style: TextStyle(color: colors.textSecondary)),
        ],
      ));
    }

    // Group by category
    final Map<String, double> byCategory = {};
    for (final e in loaded.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Expenses',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              Text('$currency ${fmt.format(loaded.totalExpenses)}',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16, color: colors.error)),
            ],
          ),
        ),

        // Expense list
        ...loaded.expenses.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.error.withValues(alpha: 0.12),
              child: Icon(Icons.receipt_outlined, color: colors.error, size: 18),
            ),
            title: Text(e.description,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.category,
                    style: TextStyle(color: colors.primary, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                if (e.supplier != null)
                  Text('From: ${e.supplier!.name}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text(DateFormat('dd MMM yyyy').format(e.expenseDate),
                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$currency ${fmt.format(e.amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: colors.error, fontSize: 13)),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
                  onSelected: (v) {
                    if (v == 'edit') _showForm(context, e);
                    if (v == 'delete') context.read<BusinessCubit>().deleteExpense(e.id);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showForm(BuildContext context, BusinessExpenseModel? expense) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: ExpenseFormScreen(loaded: loaded, expense: expense),
      ),
    ));
  }
}

// ── Expense Form Screen ───────────────────────────────────────
class ExpenseFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final BusinessExpenseModel? expense;
  const ExpenseFormScreen({super.key, required this.loaded, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  String _category = 'General';
  BusinessSupplierModel? _supplier;
  DateTime _date = DateTime.now();
  bool _loading = false;

  static const _categories = [
    'General', 'Rent', 'Utilities', 'Salaries', 'Transport',
    'Marketing', 'Equipment', 'Supplies', 'Maintenance', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toString();
      _category = e.category;
      _date = e.expenseDate;
      if (e.supplierId != null) {
        try {
          _supplier = widget.loaded.suppliers
              .firstWhere((s) => s.id == e.supplierId);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = Money.defaultCurrency;
    return BlocListener<BusinessCubit, BusinessState>(
      listener: (context, state) {
        if (state is BusinessSuccess) Navigator.pop(context);
        if (state is BusinessError) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? 'New Expense' : 'Edit Expense'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description *',
                    prefixIcon: Icon(Icons.description_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Amount ($currency)',
                    prefixIcon: const Icon(Icons.attach_money))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(
                  value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            if (widget.loaded.suppliers.isNotEmpty)
              DropdownButtonFormField<BusinessSupplierModel>(
                value: _supplier,
                decoration: const InputDecoration(labelText: 'Supplier (optional)',
                    prefixIcon: Icon(Icons.store_outlined)),
                hint: const Text('Select supplier'),
                items: widget.loaded.suppliers.map((s) => DropdownMenuItem(
                    value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _supplier = v),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      color: context.colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(DateFormat('EEEE, dd MMM yyyy').format(_date)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.expense == null ? 'Add Expense' : 'Update Expense'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _submit() {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description is required')));
      return;
    }
    setState(() => _loading = true);
    final e = BusinessExpenseModel(
      id: widget.expense?.id ?? 0,
      businessId: widget.loaded.active!.id,
      supplierId: _supplier?.id,
      description: _descCtrl.text.trim(),
      category: _category,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      expenseDate: _date,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      supplier: _supplier,
    );
    if (widget.expense == null) {
      context.read<BusinessCubit>().createExpense(e);
    } else {
      context.read<BusinessCubit>().updateExpense(e);
    }
  }
}
