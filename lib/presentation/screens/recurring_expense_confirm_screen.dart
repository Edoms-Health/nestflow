import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class RecurringExpenseConfirmScreen extends StatefulWidget {
  final RecurringExpenseModel recurringExpense;

  const RecurringExpenseConfirmScreen({
    super.key,
    required this.recurringExpense,
  });

  @override
  State<RecurringExpenseConfirmScreen> createState() =>
      _RecurringExpenseConfirmScreenState();
}

class _RecurringExpenseConfirmScreenState
    extends State<RecurringExpenseConfirmScreen> {
  final RecurringExpenseService _service = RecurringExpenseService();

  bool _loading = true;
  bool _processing = false;
  CategoryModel? _category;
  WalletModel? _wallet;
  ContactModel? _contact;

  @override
  void initState() {
    super.initState();
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    final model = widget.recurringExpense;

    final category = await CategoryService().find(model.categoryId);
    final wallet = await WalletService().find(model.walletId);
    ContactModel? contact;
    if (model.contactId != null) {
      final contacts = await ContactService().fetchAll();
      contact = contacts.where((c) => c.id == model.contactId).firstOrNull;
    }

    if (!mounted) return;
    setState(() {
      _category = category;
      _wallet = wallet;
      _contact = contact;
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      await _service.confirm(widget.recurringExpense);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _processing = true);
    try {
      await _service.skip(widget.recurringExpense);
      if (!mounted) return;
      Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.recurringExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Expense')),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding),
                child: Row(
                  children: [
                    Expanded(
                      child: FullElevatedButton(
                        label: 'Skip',
                        isGrayColor: true,
                        onPressed: _processing ? null : _skip,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FullElevatedButton(
                        label: 'Confirm',
                        onPressed: _processing ? null : _confirm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.padding),
              children: [
                ContainerForm(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.amountMoney.format(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${model.frequency.label} \u2022 due ${DateFormat.yMMMd().format(model.nextDueDate)}',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ContainerForm(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Category', value: _category?.name ?? '\u2014'),
                      _DetailRow(label: 'Wallet', value: _wallet?.name ?? '\u2014'),
                      if (_contact != null)
                        _DetailRow(label: 'Contact', value: _contact!.name),
                      if (model.note?.trim().isNotEmpty == true)
                        _DetailRow(label: 'Note', value: model.note!.trim()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
