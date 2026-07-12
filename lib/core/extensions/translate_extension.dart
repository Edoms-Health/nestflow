import 'package:flutter/widgets.dart';
import 'package:nestflow/nestflow.dart';

extension TranslateExtension on BuildContext {
  AppLocalizations? get tr => AppLocalizations.of(this);
}
