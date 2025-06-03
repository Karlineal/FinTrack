import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates';
  static const String _cacheTimeKey = 'exchange_rates_time';
  static const Duration _cacheExpiry = Duration(hours: 1); // 缓存1小时

  // 支持的货币列表
  static const Map<String, String> supportedCurrencies = {
    'CNY': '¥',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥JP',
    'KRW': '₩',
    'HKD': 'HK\$',
    'TWD': 'NT\$',
  };

  // 获取汇率数据
  static Future<Map<String, double>> getExchangeRates(
    String baseCurrency,
  ) async {
    try {
      // 先尝试从缓存获取
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      // 从API获取最新汇率
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$baseCurrency'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(data['rates']);

        // 缓存汇率数据
        await _cacheRates(baseCurrency, rates);

        return rates;
      } else {
        throw Exception(
          'Failed to fetch exchange rates: ${response.statusCode}',
        );
      }
    } catch (e) {
      // 如果网络请求失败，尝试使用缓存的数据（即使过期）
      final cachedRates = await _getCachedRates(
        baseCurrency,
        ignoreExpiry: true,
      );
      if (cachedRates != null) {
        return cachedRates;
      }

      // 如果没有缓存数据，返回默认汇率（以CNY为基准的近似汇率）
      return _getDefaultRates(baseCurrency);
    }
  }

  // 转换金额
  static Future<double> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    try {
      final rates = await getExchangeRates(fromCurrency);
      final rate = rates[toCurrency];

      if (rate != null) {
        return amount * rate;
      } else {
        throw Exception('Currency $toCurrency not supported');
      }
    } catch (e) {
      // 转换失败时返回原金额
      return amount;
    }
  }

  // 获取缓存的汇率
  static Future<Map<String, double>?> _getCachedRates(
    String baseCurrency, {
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$baseCurrency';
      final timeKey = '${_cacheTimeKey}_$baseCurrency';

      final cachedData = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt(timeKey);

      if (cachedData != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final isExpired =
            DateTime.now().difference(cacheDateTime) > _cacheExpiry;

        if (!isExpired || ignoreExpiry) {
          final data = json.decode(cachedData);
          return Map<String, double>.from(data);
        }
      }
    } catch (e) {
      // 缓存读取失败，返回null
    }

    return null;
  }

  // 缓存汇率数据
  static Future<void> _cacheRates(
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$baseCurrency';
      final timeKey = '${_cacheTimeKey}_$baseCurrency';

      await prefs.setString(cacheKey, json.encode(rates));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // 缓存失败，忽略错误
    }
  }

  // 获取默认汇率（离线时使用）
  static Map<String, double> _getDefaultRates(String baseCurrency) {
    // 这里提供一些常用货币的近似汇率，以CNY为基准
    const defaultRatesFromCNY = {
      'CNY': 1.0,
      'USD': 0.14,
      'EUR': 0.13,
      'GBP': 0.11,
      'JPY': 20.0,
      'KRW': 190.0,
      'HKD': 1.1,
      'TWD': 4.5,
    };

    if (baseCurrency == 'CNY') {
      return Map<String, double>.from(defaultRatesFromCNY);
    }

    // 如果基准货币不是CNY，需要转换
    final baseRate = defaultRatesFromCNY[baseCurrency] ?? 1.0;
    final convertedRates = <String, double>{};

    for (final entry in defaultRatesFromCNY.entries) {
      convertedRates[entry.key] = entry.value / baseRate;
    }

    return convertedRates;
  }

  // 获取货币符号
  static String getCurrencySymbol(String currencyCode) {
    return supportedCurrencies[currencyCode] ?? currencyCode;
  }

  // 获取支持的货币代码列表
  static List<String> getSupportedCurrencies() {
    return supportedCurrencies.keys.toList();
  }
}
