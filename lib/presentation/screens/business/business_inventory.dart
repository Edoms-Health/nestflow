import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

// ── Inventory Tab ─────────────────────────────────────────────
class BusinessInventoryTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessInventoryTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final currency = Money.defaultCurrency;

    if (loaded.products.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 70,
              color: colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No products yet', style: TextStyle(color: colors.textSecondary)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.products.length,
      itemBuilder: (context, i) {
        final p = loaded.products[i];
        Color stockColor = const Color(0xFF1abc9c);
        if (p.isOutOfStock) stockColor = colors.error;
        else if (p.isLowStock) stockColor = const Color(0xFFFFC107);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: p.isLowStock ? stockColor.withValues(alpha: 0.4) : colors.divider,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: stockColor.withValues(alpha: 0.15),
              child: Icon(Icons.inventory_2_outlined, color: stockColor, size: 20),
            ),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$currency ${fmt.format(p.price)} / ${p.unit}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                if (p.description != null)
                  Text(p.description!,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p.stockQty}',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 18, color: stockColor)),
                Text(p.unit,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
            onTap: () => _showProductActions(context, p),
          ),
        );
      },
    );
  }

  void _showProductActions(BuildContext context, BusinessProductModel p) {
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
              Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: colors.primary),
                title: const Text('Add Stock'),
                onTap: () {
                  Navigator.pop(context);
                  _showStockDialog(context, p, 'add');
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: colors.warning),
                title: const Text('Remove Stock'),
                onTap: () {
                  Navigator.pop(context);
                  _showStockDialog(context, p, 'remove');
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colors.primary),
                title: const Text('Edit Product'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<BusinessCubit>(),
                      child: ProductFormScreen(loaded: loaded, product: p),
                    ),
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.error),
                title: Text('Delete Product',
                    style: TextStyle(color: colors.error)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<BusinessCubit>().deleteProduct(p.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context, BusinessProductModel p, String action) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${action == 'add' ? 'Add' : 'Remove'} Stock — ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Quantity (${p.unit})',
            prefixIcon: const Icon(Icons.numbers_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(ctrl.text) ?? 0;
              if (qty > 0) {
                context.read<BusinessCubit>().adjustStock(p.id, qty, action);
              }
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ── Product Form Screen ───────────────────────────────────────
class ProductFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final BusinessProductModel? product;
  const ProductFormScreen({super.key, required this.loaded, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _priceCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '0');
  final _alertCtrl = TextEditingController(text: '5');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _unitCtrl.text = p.unit;
      _priceCtrl.text = p.price.toString();
      _stockCtrl.text = p.stockQty.toString();
      _alertCtrl.text = p.lowStockAlert.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _unitCtrl.dispose();
    _priceCtrl.dispose(); _stockCtrl.dispose(); _alertCtrl.dispose();
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
          title: Text(widget.product == null ? 'New Product' : 'Edit Product'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name *',
                    prefixIcon: Icon(Icons.inventory_2_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description',
                    prefixIcon: Icon(Icons.notes_outlined))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _unitCtrl,
                  decoration: const InputDecoration(labelText: 'Unit (pcs, kg, L...)',
                      prefixIcon: Icon(Icons.straighten_outlined)))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Unit Price ($currency)',
                      prefixIcon: const Icon(Icons.attach_money)))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Stock',
                      prefixIcon: Icon(Icons.storage_outlined)))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _alertCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Low Stock Alert At',
                      prefixIcon: Icon(Icons.warning_amber_outlined)))),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.product == null ? 'Add Product' : 'Update Product'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product name is required')));
      return;
    }
    setState(() => _loading = true);
    final p = BusinessProductModel(
      id: widget.product?.id ?? 0,
      businessId: widget.loaded.active!.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      stockQty: double.tryParse(_stockCtrl.text) ?? 0,
      lowStockAlert: double.tryParse(_alertCtrl.text) ?? 5,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.product == null) {
      context.read<BusinessCubit>().createProduct(p);
    } else {
      context.read<BusinessCubit>().updateProduct(p);
    }
  }
}
