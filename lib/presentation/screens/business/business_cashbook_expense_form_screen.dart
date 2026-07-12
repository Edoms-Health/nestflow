import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class CashbookExpenseFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final CashbookExpenseModel? expense;
  const CashbookExpenseFormScreen({super.key, required this.loaded, this.expense});

  @override
  State<CashbookExpenseFormScreen> createState() => _CashbookExpenseFormScreenState();
}

class _CashbookExpenseFormScreenState extends State<CashbookExpenseFormScreen> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  int? _branchId;
  String _category = 'General';
  DateTime _date = DateTime.now();
  String? _error;

  static const _categories = [
    'General', 'Rent', 'Utilities', 'Salaries', 'Transport',
    'Marketing', 'Equipment', 'Supplies', 'Maintenance', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.expense?.description ?? '');
    _amountCtrl = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _branchId = widget.expense?.branchId ??
        (widget.loaded.branches.length == 1 ? widget.loaded.branches.first.id : null);
    _category = widget.expense?.category ?? 'General';
    _date = widget.expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (_descCtrl.text.trim().isEmpty || amount <= 0) {
      setState(() => _error = 'Description and a valid amount are required');
      return;
    }
    if (_branchId == null) {
      setState(() => _error = 'Please select a branch');
      return;
    }
    final cubit = context.read<BusinessCubit>();
    if (widget.expense == null) {
      cubit.createCashbookExpense(CashbookExpenseModel(
        id: 0, businessId: widget.loaded.active!.id, branchId: _branchId!,
        description: _descCtrl.text.trim(), category: _category,
        amount: amount, expenseDate: _date, createdAt: DateTime.now(),
      ));
    } else {
      cubit.updateCashbookExpense(widget.expense!.copyWith(
        branchId: _branchId, description: _descCtrl.text.trim(),
        category: _category, amount: amount, expenseDate: _date,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.expense == null ? 'New Expense' : 'Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
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
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _branchId,
              decoration: const InputDecoration(labelText: 'Branch *', border: OutlineInputBorder()),
              items: widget.loaded.branches
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
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
