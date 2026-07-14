import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

/// Starts the Send Money / Receive Money / Pay flow:
/// 1. Pick or create a contact.
/// 2. Fill in a normal transaction (amount, wallet, category, etc.) tagged
///    to that contact, reusing the existing transaction form.
///
/// NestFlow only records the transaction locally — the actual money
/// movement happens outside the app, completed manually by the user.
Future<void> startContactTransaction(
  BuildContext context, {
  required TransactionType type,
  required GestureTapCallback refresh,
}) async {
  final ContactModel? contact = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (_) => ContactCubit()..loadContacts(),
        child: ContactScreen(isPickerMode: true),
      ),
    ),
  );
  if (contact == null || !context.mounted) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (_) =>
            TransactionFormCubit()..init(type: type, initialContact: contact),
        child: const TransactionFormScreen(),
      ),
    ),
  );

  if (result != null && result is Map && result['refresh'] == true) {
    refresh();
  }
}
