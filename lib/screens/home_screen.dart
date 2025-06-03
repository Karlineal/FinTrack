import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 SharedPreferences

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [];
  String _currencySymbol = '¥'; // 添加状态变量存储货币符号

  @override
  void initState() {
    super.initState();
    _loadCurrencyPreference(); // 加载货币偏好
    // 初始化屏幕列表
    // _buildHomeContent() 需要 _currencySymbol，所以确保它在 _screens 初始化时可用
    // 或者将 _buildHomeContent 的构建延迟到 _currencySymbol 加载后
    // 为了简单起见，暂时先这样，后续可能需要调整确保 _currencySymbol 在构建时已加载

    // 加载交易数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
      // 在数据加载后，再次确保货币符号是最新的
      // 这也处理了从设置页返回时可能需要更新符号的情况
      _loadCurrencyPreference();
    });
  }

  Future<void> _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // 检查 widget 是否仍然挂载
      setState(() {
        _currencySymbol = prefs.getString('currency') ?? '¥';
        // 更新 _screens 列表中的 _buildHomeContent，以确保它使用最新的 _currencySymbol
        // 这是一个简化的处理，更健壮的方式可能是在 _buildHomeContent 中直接使用 _currencySymbol
        // 或者通过其他状态管理方式传递
        _screens.clear();
        _screens.addAll([
          _buildHomeContent(), // 重建 _buildHomeContent
          const StatisticsScreen(),
          const SettingsScreen(),
        ]);
      });
    }
  }

  // 当从设置页面返回时，也可能需要刷新货币符号
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听路由变化，如果从设置页返回，则重新加载货币偏好
    // 这是一个简化的示例，实际应用中可能有更优雅的跨页面状态同步方式
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute && route.isCurrent) {
      // 尝试在每次页面变为当前时刷新，确保从设置返回时更新
      _loadCurrencyPreference();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeContent() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 摘要卡片
            SummaryCard(
              income: provider.totalIncome,
              expense: provider.totalExpense,
              balance: provider.balance,
              currencySymbol: _currencySymbol, // 传递货币符号
            ),

            // 最近交易标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近交易',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 查看所有交易
                    },
                    child: const Text('查看全部'),
                  ),
                ],
              ),
            ),

            // 交易列表
            Expanded(
              child:
                  provider.transactions.isEmpty
                      ? const Center(child: Text('暂无交易记录，点击下方 + 按钮添加'))
                      : ListView.builder(
                        itemCount:
                            provider.transactions.length > 5
                                ? 5
                                : provider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TransactionDetailScreen(
                                        transaction: transaction,
                                      ),
                                ),
                              );
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('确认删除'),
                                      content: const Text('确定要删除这条交易记录吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmed == true) {
                                await provider.deleteTransaction(
                                  transaction.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('交易记录已删除')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
