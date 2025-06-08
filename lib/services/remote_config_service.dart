// lib/services/remote_config_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class RemoteConfigService {
  // ！！！请将这里的 URL 替换为你自己的 Raw URL ！！！
  static const String _categoriesUrl =
      'https://raw.githubusercontent.com/Karline-source/fintrack-data/main/transaction_categories.json';

  // 获取交易分类列表的静态方法
  static Future<List<Category>> getTransactionCategories() async {
    try {
      final response = await http.get(Uri.parse(_categoriesUrl));

      if (response.statusCode == 200) {
        // UTF8 解码以支持中文字符
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<Category> categories =
            data
                .map((item) => Category.fromJson(item as Map<String, dynamic>))
                .toList();
        return categories;
      } else {
        // 如果服务器返回的不是 200 OK，则抛出异常。
        throw Exception('Failed to load categories from network');
      }
    } catch (e) {
      // 处理网络或其他异常，可以返回一个默认的本地列表作为备用
      print('Error fetching categories: $e');
      return _getDefaultCategories();
    }
  }

  // 备用方案：如果网络请求失败，返回一个硬编码的默认列表
  static List<Category> _getDefaultCategories() {
    return [
      Category(name: '餐饮美食 (本地)', icon: 0xe25c),
      Category(name: '交通出行 (本地)', icon: 0xe1d5),
    ];
  }
}
