import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class SaleFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final BusinessSaleModel? sale;
  const SaleFormScreen({super.key, required this.loaded, this.sale});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  int? _branchId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.sale?.description ?? '');
    _amountCtrl = TextEditingController(text: widget.sale?.amount.toString() ?? '');
    _branchId = widget.sale?.branchId;
    _date = widget.sale?.saleDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (_descCtrl.text.trim().isEmpty || amount <= 0) return;
    final cubit = context.read<BusinessCubit>();
    if (widget.sale == null) {
      cubit.createSale(BusinessSaleModel(
        id: 0, businessId: widget.loaded.active!.id, branchId: _branchId,
        description: _descCtrl.text.trim(), amount: amount,
        saleDate: _date, createdAt: DateTime.now(),
      ));
    } else {
      cubit.updateSale(widget.sale!.copyWith(
        branchId: _branchId, description: _descCtrl.text.trim(),
        amount: amount, saleDate: _date,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sale == null ? 'Record Sale' : 'Edit Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _branchId,
              decoration: const InputDecoration(labelText: 'Branch (optional)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('No branch')),
                ...widget.loaded.branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
              ],
              onChanged: (v) => setState(() => _branchId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_date.toLocal().toString().split(' ').first}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
