import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // 导入 provider
import '../main.dart'; // 导入 main.dart 以使用 ThemeProvider
import '../providers/transaction_provider.dart';
import 'dart:io'; // 用于 File 操作
// 用于 ListToCsvConverter
import 'package:intl/intl.dart'; // 用于 DateFormat
import 'package:path_provider/path_provider.dart'; // 用于 getApplicationDocumentsDirectory
import 'package:share_plus/share_plus.dart'; // 用于 Share
import 'package:excel/excel.dart';
import '../models/transaction.dart' as app_transaction;
import '../services/exchange_rate_service.dart';
import '../services/notification_manager.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;

  // 通知相关设置
  bool _isTransactionNotificationEnabled = false;

  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载通知详细设置
    final transactionNotificationEnabled =
        await _notificationManager.getTransactionNotificationEnabled();

    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications') ?? true;

      // 通知设置
      _isTransactionNotificationEnabled = transactionNotificationEnabled;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('notifications', _isNotificationsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildSectionHeader('外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('启用深色主题'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
                _saveSettings();
              });
              // 更新主题模式
              Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).setThemeMode(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),

          _buildSectionHeader('通知'),
          SwitchListTile(
            title: const Text('启用通知'),
            subtitle: const Text('接收预算提醒和其他通知'),
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _isNotificationsEnabled = value;
                _saveSettings();
              });
            },
          ),
          if (_isNotificationsEnabled) ..._buildNotificationSettings(),
          const Divider(),

          _buildSectionHeader('数据'),
          ListTile(
            title: const Text('刷新汇率数据'),
            subtitle: const Text('更新最新的货币汇率信息'),
            trailing: const Icon(Icons.refresh, size: 20),
            onTap: () async {
              // 在异步操作前缓存 context 相关的对象
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );

              // 显示加载指示器
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              try {
                // 刷新汇率（通过获取最新汇率来刷新缓存）
                await ExchangeRateService.getExchangeRates('CNY');
                await provider.refreshExchangeRates();

                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('汇率数据已更新')),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('更新汇率失败: ${e.toString()}')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('导出数据'),
            subtitle: const Text('将您的交易数据导出为Excel文件'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _exportData,
          ),
          const Divider(),

          _buildSectionHeader('关于'),
          ListTile(title: const Text('版本'), subtitle: const Text('1.0.0')),
          ListTile(
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('使用条款'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfUseScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  List<Widget> _buildNotificationSettings() {
    return [
      SwitchListTile(
        title: const Text('交易成功通知'),
        subtitle: const Text('添加交易记录后显示通知'),
        value: _isTransactionNotificationEnabled,
        onChanged: (value) async {
          setState(() {
            _isTransactionNotificationEnabled = value;
          });
          await _notificationManager.setTransactionNotificationEnabled(value);
        },
      ),
    ];
  }

  Future<void> _exportData() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final transactions = transactionProvider.transactions;

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可导出的数据')));
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Transactions'];

      // 添加表头
      List<String> headers = [
        'ID',
        'Type',
        'Amount',
        'Category',
        'Date',
        'Notes',
        'Currency',
      ];
      sheetObject.appendRow(headers);

      // 添加数据行
      for (var transaction in transactions) {
        List<dynamic> row = [
          transaction.id,
          transaction.type == app_transaction.TransactionType.expense
              ? 'Expense'
              : 'Income',
          transaction.amount,
          transaction.category,
          DateFormat('yyyy-MM-dd HH:mm').format(transaction.date),
          transaction.note ?? '',
          transaction.currency,
        ];
        sheetObject.appendRow(row);
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/fintrack_transactions.xlsx';
      final file = File(path);
      final onValue = await excel.encode();
      if (onValue != null) {
        await file.writeAsBytes(onValue);
        await Share.shareXFiles([XFile(path)], text: '这是您的FinTrack交易数据');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: ${e.toString()}')));
    }
  }
}
