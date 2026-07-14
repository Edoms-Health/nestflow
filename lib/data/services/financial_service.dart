import 'package:nestflow/nestflow.dart';

class FinancialService {
  static final FinancialService _instance = FinancialService._internal();

  factory FinancialService() => _instance;

  FinancialService._internal();

  final MonthlyFinancialDao _dao = MonthlyFinancialDao(AppDatabase.instance);

  Future<List<MonthlyFinancialModel>> fetchForYear(int year) async =>
      (await _dao.getForYear(year))
          .map(MonthlyFinancialModel.fromEntity)
          .toList();

  Future<List<int>> fetchAvailableYears() => _dao.getAllYears();

  Future<void> upsert(MonthlyFinancialModel model) =>
      _dao.upsert(model.toInsertCompanion());

  Future<int> delete(int id) => _dao.deleteEntry(id);
}
