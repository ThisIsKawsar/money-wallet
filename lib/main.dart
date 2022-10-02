import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cashpilot/core/theme/app_theme.dart';
import 'package:cashpilot/core/router/app_router.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/debt_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CashPilotApp());
}

class CashPilotApp extends StatefulWidget {
  const CashPilotApp({super.key});

  @override
  State<CashPilotApp> createState() => _CashPilotAppState();
}

class _CashPilotAppState extends State<CashPilotApp> {
  final _settings = SettingsProvider();

  // Router created once — never recreated so navigation state is preserved.
  final _router = createRouter();

  @override
  void initState() {
    super.initState();
    _settings.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'CashPilot',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}
