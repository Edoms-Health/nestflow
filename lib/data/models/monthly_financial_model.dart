import 'package:drift/drift.dart';
import 'package:nestflow/data/database/database.dart';

class MonthlyFinancialModel {
  final int id;
  final int year;
  final int month;
  final double income;
  final double expense;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyFinancialModel({
    required this.id,
    required this.year,
    required this.month,
    this.income = 0.0,
    this.expense = 0.0,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  double get profit => income - expense;

  factory MonthlyFinancialModel.fromEntity(MonthlyFinancial e) {
    return MonthlyFinancialModel(
      id: e.id,
      year: e.year,
      month: e.month,
      income: e.income,
      expense: e.expense,
      note: e.note,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  MonthlyFinancialsCompanion toInsertCompanion() {
    return MonthlyFinancialsCompanion(
      year: Value(year),
      month: Value(month),
      income: Value(income),
      expense: Value(expense),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  MonthlyFinancial toEntity() {
    return MonthlyFinancial(
      id: id,
      year: year,
      month: month,
      income: income,
      expense: expense,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
