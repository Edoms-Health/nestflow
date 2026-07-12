import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nestflow/data/database/tables/export.dart';
import 'package:nestflow/data/seeders/nestflow_seeder.dart';
import 'package:nestflow/data/database/daos/business/business_dao.dart';
import 'package:nestflow/data/database/tables/business_tables.dart';
import 'package:nestflow/data/database/daos/todo/todo_dao.dart';
import 'package:nestflow/data/database/daos/project/project_dao.dart';
import 'package:nestflow/data/database/daos/label/label_dao.dart';
import 'package:nestflow/nestflow.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tags,
    Categories,
    Wallets,
    Budgets,
    Transactions,
    CurrencyRates,
    TransactionTags,
    Contacts,
    Businesses,
    BusinessClients,
    BusinessSuppliers,
    BusinessProducts,
    BusinessInvoices,
    BusinessInvoiceItems,
    BusinessExpenses,
    Branches,
    BusinessSales,
    BusinessOtherEntries,
    CashbookExpenses,
    Todos,
    Projects,
    Labels,
    TodoLabels,
  ],
  daos: [
    TagDao,
    CategoryDao,
    WalletDao,
    BudgetDao,
    TransactionDao,
    CurrencyRateDao,
    ContactDao,
    BusinessDao,
    TodoDao,
    ProjectDao,
    LabelDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  static final AppDatabase _instance = AppDatabase._internal();

  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 11;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nestflow',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await NestFlowSeeder().seed();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      await m.createAll();
      if (from == 1) {
        m.addColumn(transactions, transactions.contactId);
        m.addColumn(transactions, transactions.startDate);
        m.addColumn(transactions, transactions.endDate);
      }
      if (from < 3) {
        await m.createTable(todos);
      }
      if (from < 4) {
        await m.createTable(businesses);
        await m.createTable(businessClients);
        await m.createTable(businessSuppliers);
        await m.createTable(businessProducts);
        await m.createTable(businessInvoices);
        await m.createTable(businessInvoiceItems);
        await m.createTable(businessExpenses);
      }
      if (from < 7) {
        await m.createTable(branches);
        await m.createTable(businessSales);
        await m.addColumn(businessExpenses, businessExpenses.branchId);
        await m.addColumn(businessInvoices, businessInvoices.branchId);
      }
      if (from < 8) {
        await m.createTable(businessOtherEntries);
      }
      if (from < 9) {
        await m.createTable(cashbookExpenses);
      }
      if (from < 11) {
        await m.addColumn(contacts, contacts.phone);
        await m.addColumn(contacts, contacts.provider);
      }
      if (from < 10) {
        await m.addColumn(branches, branches.phone);
        await m.addColumn(branches, branches.email);
        await m.addColumn(branches, branches.managerName);
      }
      if (from < 5) {
        await m.createTable(projects);
        await m.createTable(labels);
        await m.createTable(todoLabels);
        await m.addColumn(todos, todos.projectId);
        await m.addColumn(todos, todos.parentId);
        await m.addColumn(todos, todos.recurrenceRule);
      }
      if (from < 6) {
        await m.addColumn(transactions, transactions.toWalletId);
        final now = DateTime.now();
        await into(categories).insert(
          CategoriesCompanion(
            identifier: const Value('transfer'),
            categoryId: const Value(null),
            name: const Value('Transfer'),
            description: const Value(
              'System category for money moved between your own wallets.',
            ),
            type: const Value(TransactionType.transfer),
            icon: Value(AppIcons.transfer),
            color: const Value('3498db'),
            builtIn: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  TodoDao get todoDao => TodoDao(this);
  BusinessDao get businessDao => BusinessDao(this);
  ProjectDao get projectDao => ProjectDao(this);
  LabelDao get labelDao => LabelDao(this);

  Future<void> truncate() async {
    await delete(categories).go();
    await delete(wallets).go();
    await delete(budgets).go();
    await delete(tags).go();
    await delete(transactions).go();
    await delete(transactionTags).go();
    await delete(currencyRates).go();
    await delete(contacts).go();

    for (final table in [
      'tags',
      'categories',
      'wallets',
      'budgets',
      'transactions',
      'transaction_tags',
      'currency_rates',
      'contacts',
    ]) {
      await customStatement(
        "DELETE FROM sqlite_sequence WHERE name = '$table';",
      );
    }
  }
}
