import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:nestflow/nestflow.dart';

// ── Invoices Tab ─────────────────────────────────────────────
class BusinessInvoicesTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessInvoicesTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final currency = Money.defaultCurrency;

    if (loaded.invoices.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 70,
              color: colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No invoices yet', style: TextStyle(color: colors.textSecondary)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.invoices.length,
      itemBuilder: (context, i) {
        final inv = loaded.invoices[i];
        Color statusColor;
        switch (inv.status) {
          case 'paid': statusColor = const Color(0xFF1abc9c); break;
          case 'sent': statusColor = colors.primary; break;
          case 'overdue': statusColor = colors.error; break;
          default: statusColor = colors.textSecondary;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inv.isOverdue
                ? colors.error.withValues(alpha: 0.4) : colors.divider),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Row(children: [
              Text(inv.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(inv.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.client?.name ?? 'Unknown Client',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('Due: ${DateFormat('dd MMM yyyy').format(inv.dueAt)}',
                    style: TextStyle(
                        color: inv.isOverdue ? colors.error : colors.textSecondary,
                        fontSize: 11)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$currency ${fmt.format(inv.total)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${inv.items.length} items',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
            onTap: () => _showInvoiceActions(context, inv, loaded),
          ),
        );
      },
    );
  }

  void _showInvoiceActions(BuildContext context, BusinessInvoiceModel inv,
      BusinessLoaded loaded) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(inv.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              // Status options
              if (inv.status != 'paid')
                ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF1abc9c)),
                  title: const Text('Mark as Paid'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<BusinessCubit>()
                        .updateInvoiceStatus(inv.id, 'paid');
                  },
                ),
              if (inv.status == 'draft')
                ListTile(
                  leading: Icon(Icons.send_outlined, color: colors.primary),
                  title: const Text('Mark as Sent'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<BusinessCubit>()
                        .updateInvoiceStatus(inv.id, 'sent');
                  },
                ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined, color: colors.primary),
                title: const Text('Generate PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await _generatePdf(context, inv, loaded);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colors.primary),
                title: const Text('Edit Invoice'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<BusinessCubit>(),
                      child: InvoiceFormScreen(loaded: loaded, invoice: inv),
                    ),
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.error),
                title: Text('Delete Invoice',
                    style: TextStyle(color: colors.error)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<BusinessCubit>().deleteInvoice(inv.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, BusinessInvoiceModel inv,
      BusinessLoaded loaded) async {
    if (loaded.active == null) return;
    try {
      final file = await InvoicePdfGenerator.generate(
          invoice: inv, business: loaded.active!);
      if (!context.mounted) return;
      await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: '${inv.invoiceNumber}.pdf');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')));
    }
  }
}

// ── Invoice Form Screen ───────────────────────────────────────
class InvoiceFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final BusinessInvoiceModel? invoice;
  const InvoiceFormScreen({super.key, required this.loaded, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _notesCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  BusinessClientModel? _selectedClient;
  DateTime _issuedAt = DateTime.now();
  DateTime _dueAt = DateTime.now().add(const Duration(days: 14));
  List<_ItemRow> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      final inv = widget.invoice!;
      _notesCtrl.text = inv.notes ?? '';
      _taxCtrl.text = inv.taxPercent.toString();
      _discountCtrl.text = inv.discountPercent.toString();
      _issuedAt = inv.issuedAt;
      _dueAt = inv.dueAt;
      _selectedClient = inv.client;
      _items = inv.items.map((item) => _ItemRow(
        nameCtrl: TextEditingController(text: item.name),
        unitCtrl: TextEditingController(text: item.unit),
        qtyCtrl: TextEditingController(text: item.qty.toString()),
        priceCtrl: TextEditingController(text: item.unitPrice.toString()),
        productId: item.productId,
      )).toList();
    } else {
      _items.add(_ItemRow.empty());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
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
          title: Text(widget.invoice == null ? 'New Invoice' : 'Edit Invoice'),
          actions: [
            TextButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? '...' : 'Save',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client selector
              _SectionTitle('Client'),
              DropdownButtonFormField<BusinessClientModel>(
                value: _selectedClient,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline)),
                hint: const Text('Select client'),
                items: widget.loaded.clients.map((c) => DropdownMenuItem(
                  value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedClient = v),
              ),
              const SizedBox(height: 16),

              // Dates
              Row(children: [
                Expanded(child: _DateField('Issue Date', _issuedAt,
                    (d) => setState(() => _issuedAt = d))),
                const SizedBox(width: 12),
                Expanded(child: _DateField('Due Date', _dueAt,
                    (d) => setState(() => _dueAt = d))),
              ]),
              const SizedBox(height: 20),

              // Items
              _SectionTitle('Items'),
              ..._items.asMap().entries.map((e) =>
                  _InvoiceItemRow(
                    row: e.value,
                    products: widget.loaded.products,
                    currency: currency,
                    onRemove: _items.length > 1
                        ? () => setState(() => _items.removeAt(e.key))
                        : null,
                    onProductSelected: (p) {
                      setState(() {
                        _items[e.key].nameCtrl.text = p.name;
                        _items[e.key].unitCtrl.text = p.unit;
                        _items[e.key].priceCtrl.text = p.price.toString();
                        _items[e.key].productId = p.id;
                      });
                    },
                  )),
              TextButton.icon(
                onPressed: () => setState(() => _items.add(_ItemRow.empty())),
                icon: Icon(Icons.add, color: colors.primary),
                label: Text('Add Item', style: TextStyle(color: colors.primary)),
              ),
              const SizedBox(height: 16),

              // Tax & Discount
              Row(children: [
                Expanded(child: TextField(
                  controller: _taxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Tax %', prefixIcon: Icon(Icons.percent)),
                  onChanged: (_) => setState(() {}),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: _discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Discount %', prefixIcon: Icon(Icons.discount_outlined)),
                  onChanged: (_) => setState(() {}),
                )),
              ]),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes', prefixIcon: Icon(Icons.notes_outlined)),
              ),
              const SizedBox(height: 20),

              // Total summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  _TotalRow('Subtotal', _subtotal, currency, fmt),
                  if (_discount > 0)
                    _TotalRow('Discount (${_discountCtrl.text}%)', -_discountAmt, currency, fmt),
                  if (_tax > 0)
                    _TotalRow('Tax (${_taxCtrl.text}%)', _taxAmt, currency, fmt),
                  const Divider(),
                  _TotalRow('TOTAL', _total, currency, fmt, bold: true),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _subtotal => _items.fold(0, (s, r) {
    final qty = double.tryParse(r.qtyCtrl.text) ?? 0;
    final price = double.tryParse(r.priceCtrl.text) ?? 0;
    return s + qty * price;
  });
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _tax => double.tryParse(_taxCtrl.text) ?? 0;
  double get _discountAmt => _subtotal * _discount / 100;
  double get _taxAmt => (_subtotal - _discountAmt) * _tax / 100;
  double get _total => _subtotal - _discountAmt + _taxAmt;

  void _submit() {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')));
      return;
    }
    setState(() => _loading = true);
    final cubit = context.read<BusinessCubit>();
    final number = widget.invoice?.invoiceNumber ??
        cubit.generateInvoiceNumber(widget.loaded.invoices);
    final items = _items.map((r) => BusinessInvoiceItemModel(
      id: 0, invoiceId: widget.invoice?.id ?? 0,
      productId: r.productId, name: r.nameCtrl.text.trim(),
      unit: r.unitCtrl.text.trim().isEmpty ? 'pcs' : r.unitCtrl.text.trim(),
      qty: double.tryParse(r.qtyCtrl.text) ?? 1,
      unitPrice: double.tryParse(r.priceCtrl.text) ?? 0,
    )).toList();

    final inv = BusinessInvoiceModel(
      id: widget.invoice?.id ?? 0,
      businessId: widget.loaded.active!.id,
      clientId: _selectedClient!.id,
      invoiceNumber: number,
      status: widget.invoice?.status ?? 'draft',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      taxPercent: _tax,
      discountPercent: _discount,
      issuedAt: _issuedAt,
      dueAt: _dueAt,
      createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      items: items,
      client: _selectedClient,
    );

    if (widget.invoice == null) {
      cubit.createInvoice(inv);
    } else {
      cubit.updateInvoice(inv);
    }
  }
}

class _ItemRow {
  TextEditingController nameCtrl;
  TextEditingController unitCtrl;
  TextEditingController qtyCtrl;
  TextEditingController priceCtrl;
  int? productId;

  _ItemRow({required this.nameCtrl, required this.unitCtrl,
      required this.qtyCtrl, required this.priceCtrl, this.productId});

  factory _ItemRow.empty() => _ItemRow(
    nameCtrl: TextEditingController(),
    unitCtrl: TextEditingController(text: 'pcs'),
    qtyCtrl: TextEditingController(text: '1'),
    priceCtrl: TextEditingController(text: '0'),
  );
}

class _InvoiceItemRow extends StatelessWidget {
  final _ItemRow row;
  final List<BusinessProductModel> products;
  final String currency;
  final VoidCallback? onRemove;
  final Function(BusinessProductModel) onProductSelected;

  const _InvoiceItemRow({required this.row, required this.products,
      required this.currency, this.onRemove, required this.onProductSelected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(
            controller: row.nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Item name', isDense: true),
          )),
          if (products.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.inventory_2_outlined, color: colors.primary, size: 20),
              onPressed: () => _pickProduct(context),
              tooltip: 'Pick from inventory',
            ),
          ],
          if (onRemove != null)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colors.error, size: 20),
              onPressed: onRemove,
            ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextField(
            controller: row.qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qty', isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: row.unitCtrl,
            decoration: const InputDecoration(labelText: 'Unit', isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: TextField(
            controller: row.priceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: 'Unit Price ($currency)', isDense: true),
          )),
        ]),
      ]),
    );
  }

  void _pickProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick from Inventory'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: products.map((p) => ListTile(
              title: Text(p.name),
              subtitle: Text('${p.stockQty} ${p.unit} in stock'),
              trailing: Text('${p.unit}'),
              onTap: () {
                onProductSelected(p);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final Function(DateTime) onChanged;

  const _DateField(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11,
              color: context.colors.textSecondary)),
          const SizedBox(height: 2),
          Text(DateFormat('dd MMM yyyy').format(value),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold,
        fontSize: 13, color: context.colors.textSecondary)),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final NumberFormat fmt;
  final bool bold;
  const _TotalRow(this.label, this.amount, this.currency, this.fmt,
      {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text('$currency ${fmt.format(amount)}',
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? context.colors.primary : null)),
    ]),
  );
}
