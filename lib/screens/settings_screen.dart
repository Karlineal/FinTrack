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
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';

import '../models/transaction.dart' as app_transaction;
import '../services/exchange_rate_service.dart';
import '../services/notification_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _currency = '¥';
  bool _isNotificationsEnabled = true;
  bool _isBackupEnabled = false;

  // 通知相关设置
  bool _isLargeExpenseAlertEnabled = true;
  double _largeExpenseThreshold = 1000.0;
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
    final largeExpenseSettings =
        await _notificationManager.getLargeExpenseSettings();
    final transactionNotificationEnabled =
        await _notificationManager.getTransactionNotificationEnabled();

    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currency = prefs.getString('currency') ?? '¥';
      _isNotificationsEnabled = prefs.getBool('notifications') ?? true;
      _isBackupEnabled = prefs.getBool('backup') ?? false;

      // 通知设置
      _isLargeExpenseAlertEnabled = largeExpenseSettings['enabled'];
      _largeExpenseThreshold = largeExpenseSettings['threshold'];
      _isTransactionNotificationEnabled = transactionNotificationEnabled;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('currency', _currency);
    await prefs.setBool('notifications', _isNotificationsEnabled);
    await prefs.setBool('backup', _isBackupEnabled);
  }

  // 新增方法：保存货币设置
  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);

    // 同时保存货币代码到defaultInputCurrency键，供首页使用
    final currencyCode = _getCurrencyCodeFromSymbol(currency);
    await prefs.setString('defaultInputCurrency', currencyCode);

    setState(() {
      _currency = currency;
    });
  }

  // 根据货币符号获取货币代码
  String _getCurrencyCodeFromSymbol(String symbol) {
    final currencies = ExchangeRateService.supportedCurrencies;
    for (final entry in currencies.entries) {
      if (entry.value == symbol) {
        return entry.key;
      }
    }
    return 'CNY'; // 默认返回人民币代码
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

          _buildSectionHeader('首选项'),
          ListTile(
            title: const Text('货币'),
            subtitle: Text('当前: $_currency'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCurrencyPicker(),
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

          _buildSectionHeader('数据'),
          SwitchListTile(
            title: const Text('自动备份'),
            subtitle: const Text('定期备份您的数据'),
            value: _isBackupEnabled,
            onChanged: (value) {
              setState(() {
                _isBackupEnabled = value;
                _saveSettings();
              });
            },
          ),
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
          ListTile(
            title: const Text('导入数据'),
            subtitle: const Text('从Excel文件导入交易数据'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _importData,
          ),
          const Divider(),

          _buildSectionHeader('关于'),
          ListTile(title: const Text('版本'), subtitle: const Text('1.0.0')),
          ListTile(
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL('https://fintrack.app/privacy'),
          ),
          ListTile(
            title: const Text('使用条款'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchURL('https://fintrack.app/terms'),
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
      // 大额支出提醒设置
      SwitchListTile(
        title: const Text('大额支出提醒'),
        subtitle: Text(
          _isLargeExpenseAlertEnabled
              ? '支出超过 ¥${_largeExpenseThreshold.toStringAsFixed(0)} 时提醒'
              : '已关闭',
        ),
        value: _isLargeExpenseAlertEnabled,
        onChanged: (value) async {
          setState(() {
            _isLargeExpenseAlertEnabled = value;
          });
          await _notificationManager.setLargeExpenseAlertEnabled(value);
        },
      ),
      if (_isLargeExpenseAlertEnabled)
        ListTile(
          title: const Text('大额支出阈值'),
          subtitle: Text('¥${_largeExpenseThreshold.toStringAsFixed(0)}'),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _showThresholdPicker(),
        ),

      // 交易成功通知
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

  void _showThresholdPicker() {
    final TextEditingController controller = TextEditingController(
      text: _largeExpenseThreshold.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置大额支出阈值'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '金额 (¥)',
              hintText: '输入阈值金额',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 在异步操作前缓存 context 相关的对象
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final double? threshold = double.tryParse(controller.text);
                if (threshold != null && threshold > 0) {
                  setState(() {
                    _largeExpenseThreshold = threshold;
                  });
                  await _notificationManager.setLargeExpenseThreshold(
                    threshold,
                  );

                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '大额支出阈值已设置为 ¥${threshold.toStringAsFixed(0)}',
                      ),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('请输入有效的金额')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyPicker() {
    final currencies = ExchangeRateService.supportedCurrencies;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择货币'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final entry = currencies.entries.elementAt(index);
                  final currencyCode = entry.key;
                  final currencySymbol = entry.value;

                  return ListTile(
                    title: Text('$currencySymbol ($currencyCode)'),
                    onTap: () {
                      // _saveCurrency 已经包含了 setState 和保存首选项的逻辑
                      _saveCurrency(currencySymbol);
                      Navigator.pop(context);
                    },
                    trailing:
                        _currency == currencySymbol
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  Future<void> _launchURL(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
      // 在当前应用中无法启动时，尝试在外部浏览器中启动
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
      }
    }
  }

  Future<void> _exportData() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions =
          Provider.of<TransactionProvider>(context, listen: false).transactions;

      if (transactions.isEmpty) {
        navigator.pop(); // 关闭加载指示器
        messenger.showSnackBar(const SnackBar(content: Text('没有可导出的数据')));
        return;
      }

      // 创建Excel文件
      final excel = Excel.createExcel();
      final sheet = excel.sheets.values.first;

      // 添加表头
      sheet.appendRow(['ID', '日期', '标题', '金额', '货币', '类别', '笔记']);

      // 添加数据行
      for (final app_transaction.Transaction t in transactions) {
        sheet.appendRow([
          t.id,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(t.date),
          t.title,
          t.amount.toString(),
          t.currency,
          t.category.name,
          t.note ?? '',
        ]);
      }

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/fintrack_transactions.xlsx';
      final file = File(path);

      // 保存Excel文件
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      }

      // 关闭加载指示器
      navigator.pop();

      // 分享文件
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(path)],
        text: '这是您的FinTrack交易数据。',
        subject: 'FinTrack 数据导出',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('导出数据失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _importData() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        messenger.showSnackBar(const SnackBar(content: Text('未选择文件')));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // 获取第一个工作表
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;

      if (rows.length < 2) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Excel文件为空或格式不正确')),
        );
        return;
      }

      // 跳过标题行
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        try {
          if (row.length < 7) continue; // 跳过不完整的行

          final dateStr = row[0]?.value?.toString() ?? '';
          final categoryStr = row[2]?.value?.toString() ?? 'other'; // 记账分类
          final typeStr = row[3]?.value?.toString() ?? '支出'; // 收支类型
          final noteStr = row[4]?.value?.toString() ?? '';
          final amountStr = row[5]?.value?.toString() ?? '0';
          final currencyStr = row[6]?.value?.toString() ?? 'CNY';

          final isIncome = typeStr.contains('收入');

          final transaction = app_transaction.Transaction(
            id: const Uuid().v4(),
            date: DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr),
            title: noteStr, // 备注作为标题
            amount: double.parse(amountStr),
            currency: currencyStr,
            category: app_transaction.Category.values.firstWhere(
              (e) => e.name == categoryStr,
              orElse: () => app_transaction.Category.other,
            ),
            note: noteStr, // 备注也作为note
            type:
                isIncome
                    ? app_transaction.TransactionType.income
                    : app_transaction.TransactionType.expense,
          );
          await provider.addTransaction(transaction);
        } catch (e) {
          // 忽略无法解析的行
          debugPrint('无法解析行 $i: $e');
        }
      }

      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('数据导入成功')));
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('导入数据失败: ${e.toString()}')),
      );
    }
  }
}
