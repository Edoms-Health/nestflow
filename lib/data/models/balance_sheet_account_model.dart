import 'package:drift/drift.dart';
import 'package:nestflow/data/database/database.dart';

enum BalanceSheetAccountType {
  asset,
  liability,
  equity;

  String get value => name;

  static BalanceSheetAccountType fromValue(String value) {
    return BalanceSheetAccountType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => BalanceSheetAccountType.asset,
    );
  }
}

class BalanceSheetAccountModel {
  final int id;
  final String name;
  final BalanceSheetAccountType type;
  final double amount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  BalanceSheetAccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.amount = 0.0,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BalanceSheetAccountModel.fromEntity(BalanceSheetAccount e) {
    return BalanceSheetAccountModel(
      id: e.id,
      name: e.name,
      type: BalanceSheetAccountType.fromValue(e.type),
      amount: e.amount,
      note: e.note,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  BalanceSheetAccountsCompanion toInsertCompanion() {
    return BalanceSheetAccountsCompanion(
      name: Value(name),
      type: Value(type.value),
      amount: Value(amount),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  BalanceSheetAccount toEntity() {
    return BalanceSheetAccount(
      id: id,
      name: name,
      type: type.value,
      amount: amount,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
