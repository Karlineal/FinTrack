import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 修复导入错误
import '../providers/transaction_provider.dart';
import '../widgets/transaction_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTransactionScreen extends StatefulWidget {
  // 将 StatelessWidget 改为 StatefulWidget
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _currency = '¥'; // 添加 _currency 状态变量

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // 加载货币设置
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('currency') ?? '¥';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加交易')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionForm(
              currency: _currency, // 传递 currency 参数
              onSubmit: (transaction) async {
                try {
                  await Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  ).addTransaction(transaction);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('交易记录已添加')));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('添加失败: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
