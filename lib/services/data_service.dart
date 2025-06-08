import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class DataService {
  static const String _githubRawUrl =
      'https://raw.githubusercontent.com/Karlineal/FinTrack/master/assets/transactions.json';

  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse(_githubRawUrl));

      if (response.statusCode == 200) {
        // 使用 compute 函数在后台线程解析 JSON
        // return compute(parseTransactions, response.body);

        // 或者直接在主线程解析（对于小数据量是OK的）
        List<dynamic> parsedJson = jsonDecode(utf8.decode(response.bodyBytes));
        return parsedJson.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load transactions from GitHub. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // 可以增加更详细的错误处理，比如网络错误
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}

// 如果数据量很大，可以使用这个函数配合 compute 来避免UI卡顿
// List<Transaction> parseTransactions(String responseBody) {
//   final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
//   return parsed.map<Transaction>((json) => Transaction.fromJson(json)).toList();
// }
