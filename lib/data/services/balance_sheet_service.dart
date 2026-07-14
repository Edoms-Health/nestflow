import 'package:nestflow/nestflow.dart';

class BalanceSheetService {
  static final BalanceSheetService _instance =
      BalanceSheetService._internal();

  factory BalanceSheetService() => _instance;

  BalanceSheetService._internal();

  final BalanceSheetAccountDao _dao = BalanceSheetAccountDao(
    AppDatabase.instance,
  );

  Future<List<BalanceSheetAccountModel>> fetchAll() async =>
      (await _dao.getAll()).map(BalanceSheetAccountModel.fromEntity).toList();

  Future<int> create(BalanceSheetAccountModel model) =>
      _dao.insertAccount(model.toInsertCompanion());

  Future<void> update(BalanceSheetAccountModel model) async =>
      await _dao.updateAccount(model.toEntity());

  Future<int> delete(int id) => _dao.deleteAccount(id);
}
