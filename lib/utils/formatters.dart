// lib/utils/formatters.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class Formatters {
  static String formatMAD(double amount, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ${localizations.currency}';
  }
}