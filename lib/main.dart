import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme_util.dart';

// ThemeProvider 用于管理应用的主题状态
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 为Web平台初始化sqflite
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // 添加 ThemeProvider
      ],
      child: Consumer<ThemeProvider>(
        // 使用 Consumer 来监听 ThemeProvider 的变化
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FinTrack',
            theme: ThemeUtil.getLightTheme(),
            darkTheme: ThemeUtil.getDarkTheme(),
            themeMode: themeProvider.themeMode, // 从 ThemeProvider 获取 themeMode
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
