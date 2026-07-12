import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class BranchFormScreen extends StatefulWidget {
  final BusinessLoaded loaded;
  final BranchModel? branch;
  const BranchFormScreen({super.key, required this.loaded, this.branch});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _managerCtrl;
  bool _isMain = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.branch?.name ?? '');
    _locationCtrl = TextEditingController(text: widget.branch?.location ?? '');
    _phoneCtrl = TextEditingController(text: widget.branch?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.branch?.email ?? '');
    _managerCtrl = TextEditingController(text: widget.branch?.managerName ?? '');
    _isMain = widget.branch?.isMain ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _managerCtrl.dispose();
    super.dispose();
  }

  String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final cubit = context.read<BusinessCubit>();
    if (widget.branch == null) {
      cubit.createBranch(BranchModel(
        id: 0, businessId: widget.loaded.active!.id,
        name: _nameCtrl.text.trim(),
        location: _blankToNull(_locationCtrl.text),
        phone: _blankToNull(_phoneCtrl.text),
        email: _blankToNull(_emailCtrl.text),
        managerName: _blankToNull(_managerCtrl.text),
        isMain: _isMain, createdAt: DateTime.now(),
      ));
    } else {
      cubit.updateBranch(widget.branch!.copyWith(
        name: _nameCtrl.text.trim(),
        location: _blankToNull(_locationCtrl.text),
        phone: _blankToNull(_phoneCtrl.text),
        email: _blankToNull(_emailCtrl.text),
        managerName: _blankToNull(_managerCtrl.text),
        isMain: _isMain,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.branch == null ? 'Add Branch' : 'Edit Branch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Branch name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _managerCtrl,
              decoration: const InputDecoration(labelText: 'Branch manager (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Main branch'),
              value: _isMain,
              onChanged: (v) => setState(() => _isMain = v),
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
