import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // 导入 provider
import '../main.dart'; // 导入 main.dart 以使用 ThemeProvider
import '../providers/transaction_provider.dart';
import '../services/exchange_rate_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currency = prefs.getString('currency') ?? '¥';
      _isNotificationsEnabled = prefs.getBool('notifications') ?? true;
      _isBackupEnabled = prefs.getBool('backup') ?? false;
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
    setState(() {
      _currency = currency;
    });
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
          const Divider(),

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

                // 刷新交易提供者中的汇率数据
                await Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).refreshExchangeRates();

                // 关闭加载指示器
                Navigator.pop(context);

                // 显示成功消息
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('汇率数据已更新')));
              } catch (e) {
                // 关闭加载指示器
                Navigator.pop(context);

                // 显示错误消息
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新汇率失败: ${e.toString()}')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('导出数据'),
            subtitle: const Text('将您的交易数据导出为CSV文件'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 实现数据导出功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('导出功能即将推出')));
            },
          ),
          ListTile(
            title: const Text('导入数据'),
            subtitle: const Text('从CSV文件导入交易数据'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 实现数据导入功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('导入功能即将推出')));
            },
          ),
          const Divider(),

          _buildSectionHeader('关于'),
          ListTile(title: const Text('版本'), subtitle: const Text('1.0.0')),
          ListTile(
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 显示隐私政策
            },
          ),
          ListTile(
            title: const Text('使用条款'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 显示使用条款
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
                      setState(() {
                        _currency = currencySymbol;
                        _saveSettings();
                      });
                      // 调用 _saveCurrency 方法保存货币设置
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
}
