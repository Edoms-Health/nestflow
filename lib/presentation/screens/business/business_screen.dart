import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
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
          context.read<BusinessCubit>().load();
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
          return _NoBusinessView(onSetup: () => _showBusinessForm(context, null));
        }

        final loaded = state is BusinessLoaded ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showBusinessSwitcher(context, loaded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loaded?.active?.name ?? 'Business',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: colors.primary, size: 20),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.business_outlined),
                onPressed: () => _showBusinessForm(context, loaded?.active),
                tooltip: 'Edit Business',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colors.primary,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Invoices'),
                Tab(text: 'Inventory'),
                Tab(text: 'Clients'),
                Tab(text: 'Expenses'),
                Tab(text: 'Branches'),
                Tab(text: 'Sales'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          body: loaded == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    BusinessOverviewTab(loaded: loaded),
                    BusinessInvoicesTab(loaded: loaded),
                    BusinessInventoryTab(loaded: loaded),
                    BusinessClientsTab(loaded: loaded),
                    BusinessExpensesTab(loaded: loaded),
                    BusinessBranchesTab(loaded: loaded),
                    BusinessSalesTab(loaded: loaded),
                    BusinessReportsTab(loaded: loaded),
                  ],
                ),
          floatingActionButton: _buildFab(context, loaded),
        );
      },
    );
  }

  Widget? _buildFab(BuildContext context, BusinessLoaded? loaded) {
    if (loaded == null) return null;
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showInvoiceForm(context, loaded, null),
          icon: const Icon(Icons.add),
          label: const Text('Invoice'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => _showProductForm(context, loaded, null),
          icon: const Icon(Icons.add),
          label: const Text('Product'),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () => _showExpenseForm(context, loaded, null),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        );
      case 5:
        return FloatingActionButton.extended(
          onPressed: () => _showBranchForm(context, loaded, null),
          icon: const Icon(Icons.add),
          label: const Text('Branch'),
        );
      case 6:
        return FloatingActionButton.extended(
          onPressed: () => _showSaleForm(context, loaded, null),
          icon: const Icon(Icons.add),
          label: const Text('Sale'),
        );
      default:
        // Overview (0) has no single add action, and Clients (3) already
        // has its own Add Client / Add Supplier buttons ? showing a FAB
        // there was both non-functional and covering those buttons.
        return null;
    }
  }

  void _showBusinessSwitcher(BuildContext context, BusinessLoaded? loaded) {
    if (loaded == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: BusinessSwitcherSheet(loaded: loaded),
      ),
    );
  }

  void _showBusinessForm(BuildContext context, BusinessModel? business) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: BusinessFormScreen(business: business),
      ),
    ));
  }

  void _showInvoiceForm(BuildContext context, BusinessLoaded loaded, BusinessInvoiceModel? invoice) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: InvoiceFormScreen(loaded: loaded, invoice: invoice),
      ),
    ));
  }

  void _showProductForm(BuildContext context, BusinessLoaded loaded, BusinessProductModel? product) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: ProductFormScreen(loaded: loaded, product: product),
      ),
    ));
  }

  void _showClientForm(BuildContext context, BusinessLoaded loaded,
      dynamic entity, String type) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: ClientSupplierFormScreen(
          loaded: loaded, entity: entity, type: type),
      ),
    ));
  }

  void _showExpenseForm(BuildContext context, BusinessLoaded loaded,
      BusinessExpenseModel? expense) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: ExpenseFormScreen(loaded: loaded, expense: expense),
      ),
    ));
  }

  void _showBranchForm(BuildContext context, BusinessLoaded loaded, BranchModel? branch) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: BranchFormScreen(loaded: loaded, branch: branch),
      ),
    ));
  }

  void _showSaleForm(BuildContext context, BusinessLoaded loaded, BusinessSaleModel? sale) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<BusinessCubit>(),
        child: SaleFormScreen(loaded: loaded, sale: sale),
      ),
    ));
  }
}

// ── No Business View ─────────────────────────────────────────
class _NoBusinessView extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoBusinessView({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Business')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 80,
                color: colors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No Business Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Set up your first business to get started',
                style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.add),
              label: const Text('Set Up Business'),
            ),
          ],
        ),
      ),
    );
  }
}
