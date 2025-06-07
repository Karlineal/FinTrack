import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _defaultInputCurrencyKey = 'defaultInputCurrency'; // 键名更新
  String _defaultInputCurrency = 'CNY'; // 默认记账货币为CNY
  SharedPreferences? _prefs;

  SettingsProvider() {
    _initPrefsAndLoad();
  }

  Future<void> _initPrefsAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    _loadDefaultInputCurrency();
  }

  String get defaultInputCurrency => _defaultInputCurrency;

  void _loadDefaultInputCurrency() {
    if (_prefs != null) {
      _defaultInputCurrency =
          _prefs!.getString(_defaultInputCurrencyKey) ?? 'CNY';
      notifyListeners();
    } else {
      if (kDebugMode) {
        debugPrint(
          "SharedPreferences not initialized in SettingsProvider yet.",
        );
      }
    }
  }

  Future<void> setDefaultInputCurrency(String currency) async {
    // 方法名更新
    if (_prefs == null) {
      /* ... */
      return;
    }
    _defaultInputCurrency = currency.toUpperCase();
    await _prefs!.setString(_defaultInputCurrencyKey, _defaultInputCurrency);
    notifyListeners();
    if (kDebugMode) {
      debugPrint("Default input currency set to: $_defaultInputCurrency");
    }
  }
}
