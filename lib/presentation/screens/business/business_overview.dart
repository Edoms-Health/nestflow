import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

// ── Overview Tab ──────────────────────────────────────────────
class BusinessOverviewTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessOverviewTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = NumberFormat('#,##0.00');
    final currency = Money.defaultCurrency;

    final isProfit = loaded.netProfit >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net Profit hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProfit
                    ? [colors.primary, colors.primary.withValues(alpha: 0.7)]
                    : [colors.error, colors.error.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Net Profit',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$currency ${fmt.format(loaded.netProfit.abs())}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat('Invoiced',
                          '$currency ${fmt.format(loaded.totalInvoiced)}'),
                    ),
                    Expanded(
                      child: _HeroStat('Paid',
                          '$currency ${fmt.format(loaded.totalPaid)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Secondary stats
          Row(
            children: [
              Expanded(
                child: _StatCard('Pending', '$currency ${fmt.format(loaded.totalPending)}',
                    Icons.pending_outlined, const Color(0xFFFFC107)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard('Expenses', '$currency ${fmt.format(loaded.totalExpenses)}',
                    Icons.money_off_outlined, colors.error),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Low stock alerts
          if (loaded.lowStockProducts.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.warning_amber_rounded, color: colors.warning, size: 18),
              const SizedBox(width: 6),
              Text('Low Stock Alerts (${loaded.lowStockProducts.length})',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: colors.warning, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            ...loaded.lowStockProducts.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${p.stockQty} ${p.unit} left',
                      style: TextStyle(color: p.isOutOfStock ? colors.error : colors.warning,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Recent invoices
          Text('Recent Invoices',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          if (loaded.invoices.isEmpty)
            Text('No invoices yet', style: TextStyle(color: colors.textSecondary))
          else
            ...loaded.invoices.take(5).map((inv) => _InvoiceQuickTile(
                invoice: inv, currency: currency, fmt: fmt)),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 13, color: color),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(label,
                  style: TextStyle(fontSize: 11,
                      color: context.colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceQuickTile extends StatelessWidget {
  final BusinessInvoiceModel invoice;
  final String currency;
  final NumberFormat fmt;
  const _InvoiceQuickTile({required this.invoice, required this.currency, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color statusColor;
    switch (invoice.status) {
      case 'paid': statusColor = const Color(0xFF1abc9c); break;
      case 'sent': statusColor = colors.primary; break;
      case 'overdue': statusColor = colors.error; break;
      default: statusColor = colors.textSecondary;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(invoice.client?.name ?? '',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$currency ${fmt.format(invoice.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(invoice.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Business Switcher Sheet ───────────────────────────────────
class BusinessSwitcherSheet extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessSwitcherSheet({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Switch Business',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16, color: colors.textPrimary)),
          const SizedBox(height: 12),
          ...loaded.businesses.map((b) => ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              child: Text(b.name[0].toUpperCase(),
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: b.address != null ? Text(b.address!) : null,
            trailing: b.isActive
                ? Icon(Icons.check_circle, color: colors.primary)
                : null,
            onTap: () {
              context.read<BusinessCubit>().switchBusiness(b.id);
              Navigator.pop(context);
            },
          )),
          const Divider(),
          ListTile(
            leading: Icon(Icons.add_business_outlined, color: colors.primary),
            title: Text('Add New Business',
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<BusinessCubit>(),
                  child: const BusinessFormScreen(business: null),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }
}

// ── Business Form Screen ──────────────────────────────────────
class BusinessFormScreen extends StatefulWidget {
  final BusinessModel? business;
  const BusinessFormScreen({super.key, this.business});

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.business != null) {
      final b = widget.business!;
      _nameCtrl.text = b.name;
      _addressCtrl.text = b.address ?? '';
      _phoneCtrl.text = b.phone ?? '';
      _emailCtrl.text = b.email ?? '';
      _tinCtrl.text = b.tin ?? '';
      _isActive = b.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _tinCtrl.dispose();
    super.dispose();
  }

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
          title: Text(widget.business == null ? 'New Business' : 'Edit Business'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Business Name *',
                    prefixIcon: Icon(Icons.business_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined))),
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
            TextField(controller: _tinCtrl,
                decoration: const InputDecoration(labelText: 'TIN (Tax ID)',
                    prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as Active Business'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.business == null ? 'Create Business' : 'Update Business'),
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
          const SnackBar(content: Text('Business name is required')));
      return;
    }
    setState(() => _loading = true);
    final b = BusinessModel(
      id: widget.business?.id ?? 0,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      tin: _tinCtrl.text.trim().isEmpty ? null : _tinCtrl.text.trim(),
      currency: widget.business?.currency ?? Money.defaultCurrency,
      isActive: _isActive,
      createdAt: widget.business?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.business == null) {
      context.read<BusinessCubit>().createBusiness(b);
    } else {
      context.read<BusinessCubit>().updateBusiness(b);
    }
  }
}
