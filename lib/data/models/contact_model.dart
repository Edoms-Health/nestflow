import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:nestflow/data/database/database.dart';

class ContactModel {
  final int id;
  final String name;
  final String color;
  final String? phone;
  final String? provider;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.color,
    this.phone,
    this.provider,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactModel.fromEntity(Contact entity) {
    return ContactModel(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      phone: entity.phone,
      provider: entity.provider,
      note: entity.note,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Contact toEntity() {
    return Contact(
      id: id,
      name: name,
      color: color,
      phone: phone,
      provider: provider,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ContactModel copyWith({
    int? id,
    String? name,
    String? color,
    String? phone,
    String? provider,
    String? note,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      phone: phone ?? this.phone,
      provider: provider ?? this.provider,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ContactsCompanion toInsertCompanion() {
    return ContactsCompanion(
      name: Value(name),
      color: Value(color),
      phone: Value(phone),
      provider: Value(provider),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  Color get nativeColor => Color(int.parse("0XFF$color"));
}
