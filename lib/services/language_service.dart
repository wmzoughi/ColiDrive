import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _currentLocale = const Locale('fr');
  bool _isRtl = false;

  Locale get currentLocale => _currentLocale;
  bool get isRtl => _isRtl;
  bool get isFrench => _currentLocale.languageCode == 'fr';
  bool get isArabic => _currentLocale.languageCode == 'ar';

  LanguageService() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'fr';
    _currentLocale = Locale(languageCode);
    _isRtl = languageCode == 'ar';
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    _currentLocale = Locale(languageCode);
    _isRtl = languageCode == 'ar';
    notifyListeners();
  }

  void toggleLanguage() {
    if (_currentLocale.languageCode == 'fr') {
      setLocale('ar');
    } else {
      setLocale('fr');
    }
  }
}