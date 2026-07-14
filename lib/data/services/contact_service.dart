import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:nestflow/nestflow.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();

  factory ContactService() => _instance;

  ContactService._internal();

  final ContactDao _dao = ContactDao(AppDatabase.instance);

  Future<List<ContactModel>> fetchAll() async =>
      (await _dao.getAll()).map(ContactModel.fromEntity).toList();

  Future<bool> nameExists(String name, {int? excludeId}) =>
      _dao.existsByName(name, excludeId: excludeId);

  Future<int> create(ContactModel contact) =>
      _dao.insertContact(contact.toInsertCompanion());

  Future<void> update(ContactModel contact) async =>
      await _dao.updateContact(contact.toEntity());

  Future<int> delete(int id) => _dao.deleteContact(id);

  Future<void> insertAll(List<ContactModel> data) async => _dao.insertAll(data);

  Future<bool> requestDevicePermission() async {
    final status = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.read,
    );
    return status == fc.PermissionStatus.granted;
  }

  /// Imports every contact from the phone's address book that has a name
  /// and isn't already present locally (matched by phone number, ignoring
  /// formatting/country-code differences). Returns how many were imported.
  Future<int> importFromDevice() async {
    final deviceContacts = await fc.FlutterContacts.getAll(
      properties: {fc.ContactProperty.phone},
    );

    final existing = await _dao.getAll();
    final existingPhones = existing
        .map((c) => c.phone)
        .whereType<String>()
        .map(_normalizePhone)
        .where((p) => p.isNotEmpty)
        .toSet();

    final now = DateTime.now();
    final toImport = <ContactModel>[];

    for (final dc in deviceContacts) {
      final name = (dc.displayName ?? '').trim();
      if (name.isEmpty) continue;

      final phone = dc.phones.isNotEmpty ? dc.phones.first.number : null;
      final normalized = phone != null ? _normalizePhone(phone) : '';

      if (normalized.isNotEmpty && existingPhones.contains(normalized)) {
        continue;
      }
      if (normalized.isNotEmpty) existingPhones.add(normalized);

      toImport.add(
        ContactModel(
          id: 0,
          name: name,
          color: ColorUtils.generateRandomColorHex(),
          phone: phone,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (toImport.isNotEmpty) {
      await _dao.insertAll(toImport);
    }
    return toImport.length;
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }
}
