import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cashpilot/core/theme/app_theme.dart';
import 'package:cashpilot/core/router/app_router.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/database/demo_data.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SettingsProvider();
  await settings.loadSettings();
  runApp(CashPilotApp(settings: settings));
}

class CashPilotApp extends StatefulWidget {
  final SettingsProvider settings;

  const CashPilotApp({super.key, required this.settings});

  @override
  State<CashPilotApp> createState() => _CashPilotAppState();
}

class _CashPilotAppState extends State<CashPilotApp> {
  late final GoRouter _router;
  int? _lastAccent;

  /// Brand colours are read from AppColors at build time, so after an accent
  /// change every element must rebuild to pick up the new colour.
  void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }
    (context as Element).visitChildren(visit);
  }

  @override
  void initState() {
    super.initState();
    _router = createRouter(
      initialLocation:
          widget.settings.hasSeenOnboarding ? '/' : '/onboarding',
    );
    if (const bool.fromEnvironment('TOUR')) _tour();
  }

  Future<void> _tour() async {
    final s = widget.settings;
    final origTheme = s.themeMode, origAccent = s.accentIndex;
    await Future.delayed(const Duration(seconds: 3));
    await DemoData.seed();
    await s.setDeveloperMode(true);
    await s.setAppearance(ThemeMode.light, 1); // Blue
    const routes = ['/', '/settings', '/settings/about', '/analytics', '/budgets', 'export'];
    for (final r in routes) {
      if (r == 'export') {
        final ctx = _router.routerDelegate.navigatorKey.currentContext!;
        final size = MediaQuery.of(ctx).size;
        try {
          await DataTransfer.shareFile('cashpilot_test.csv', 'Date,Type,Amount\n2026-11-25,expense,10.00\n',
              origin: Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 2, height: 2));
        } catch (e) {
          // ignore: avoid_print
          print('EXPORT_ERROR $e');
        }
      } else {
        _router.go(r);
      }
      // ignore: avoid_print
      print('TOUR:${r.replaceAll('/', '_')}');
      await Future.delayed(const Duration(seconds: 6));
    }
    await s.setAppearance(origTheme, origAccent);
    await DemoData.clear();
    await s.setDeveloperMode(false);
    _router.go('/');
    // ignore: avoid_print
    print('TOUR:done');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (_lastAccent != null && _lastAccent != settings.accentIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
          }
          _lastAccent = settings.accentIndex;
          return MaterialApp.router(
          title: 'CashPilot',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: _router,
          );
        },
      ),
    );
  }
}
