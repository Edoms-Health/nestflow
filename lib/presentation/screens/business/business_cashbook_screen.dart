import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class BusinessCashbookScreen extends StatefulWidget {
  const BusinessCashbookScreen({super.key});

  @override
  State<BusinessCashbookScreen> createState() => _BusinessCashbookScreenState();
}

class _BusinessCashbookScreenState extends State<BusinessCashbookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<BusinessCubit, BusinessState>(
      listener: (context, state) {
        if (state is BusinessSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        } else if (state is BusinessError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: colors.error,
          ));
        }
      },
      buildWhen: (p, c) => c is BusinessLoaded || c is BusinessLoading || c is BusinessError,
      builder: (context, state) {
        if (state is BusinessLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is BusinessLoaded && state.businesses.isEmpty) {
          return _NoBusinessSetup(
            onCreate: (name, currency) =>
                context.read<BusinessCubit>().createBusiness(BusinessModel(
                  id: 0, name: name, currency: currency, isActive: true,
                  createdAt: DateTime.now(), updatedAt: DateTime.now(),
                )),
          );
        }

        final loaded = state is BusinessLoaded ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Business'),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'Manage Branches',
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<BusinessCubit>(),
                    child: _BranchManagementScreen(loaded: loaded!),
                  ),
                )),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colors.primary,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Sales'),
                Tab(text: 'Expenses'),
                Tab(text: 'Others'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          body: loaded == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    BusinessDashboardTab(loaded: loaded),
                    BusinessSalesTab(loaded: loaded),
                    CashbookExpensesTab(loaded: loaded),
                    BusinessOthersTab(loaded: loaded),
                    BusinessReportsTab(loaded: loaded),
                  ],
                ),
          floatingActionButton: loaded == null ? null : _buildFab(context, loaded),
        );
      },
    );
  }

  Widget? _buildFab(BuildContext context, BusinessLoaded loaded) {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BusinessCubit>(),
              child: SaleFormScreen(loaded: loaded, sale: null),
            ),
          )),
          icon: const Icon(Icons.add),
          label: const Text('Sale'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BusinessCubit>(),
              child: CashbookExpenseFormScreen(loaded: loaded, expense: null),
            ),
          )),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BusinessCubit>(),
              child: OtherFormScreen(loaded: loaded, entry: null),
            ),
          )),
          icon: const Icon(Icons.add),
          label: const Text('Entry'),
        );
      default:
        return null;
    }
  }
}

class _NoBusinessSetup extends StatefulWidget {
  final void Function(String name, String currency) onCreate;
  const _NoBusinessSetup({required this.onCreate});

  @override
  State<_NoBusinessSetup> createState() => _NoBusinessSetupState();
}

class _NoBusinessSetupState extends State<_NoBusinessSetup> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('My Business')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 72, color: colors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Set up your business',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Business name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  widget.onCreate(_nameCtrl.text.trim(), 'UGX');
                },
                child: const Text('Create Business'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchManagementScreen extends StatelessWidget {
  final BusinessLoaded loaded;
  const _BranchManagementScreen({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: BusinessBranchesTab(loaded: loaded),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<BusinessCubit>(),
            child: BranchFormScreen(loaded: loaded, branch: null),
          ),
        )),
        icon: const Icon(Icons.add),
        label: const Text('Branch'),
      ),
    );
  }
}
