import 'dart:async';

/// Lightweight app-wide event bus so cubits that don't know about each
/// other (e.g. WalletCubit and DashboardCubit) can react to shared data
/// changes without manual refresh calls scattered through the UI.
class AppEvents {
  AppEvents._();

  static final StreamController<void> _balanceChangedController =
      StreamController<void>.broadcast();

  /// Fire this whenever a transaction or wallet balance changes anywhere
  /// in the app (add balance, withdraw, transfer, edit, delete).
  static void notifyBalanceChanged() {
    _balanceChangedController.add(null);
  }

  /// Listen to this to react to any balance-affecting change.
  static Stream<void> get onBalanceChanged => _balanceChangedController.stream;
}
