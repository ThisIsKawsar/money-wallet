import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/screens/dashboard/dashboard_screen.dart';
import 'package:cashpilot/screens/transactions/transactions_screen.dart';
import 'package:cashpilot/screens/add_transaction/add_transaction_screen.dart';
import 'package:cashpilot/screens/accounts/accounts_screen.dart';
import 'package:cashpilot/screens/accounts/account_detail_screen.dart';
import 'package:cashpilot/screens/accounts/transfer_screen.dart';
import 'package:cashpilot/screens/analytics/analytics_screen.dart';
import 'package:cashpilot/screens/budgets/budgets_screen.dart';
import 'package:cashpilot/screens/settings/settings_screen.dart';
import 'package:cashpilot/screens/settings/currency_picker_screen.dart';
import 'package:cashpilot/screens/settings/category_management_screen.dart';
import 'package:cashpilot/screens/settings/debt_tracker_screen.dart';
import 'package:cashpilot/screens/settings/reminders_screen.dart';
import 'package:cashpilot/screens/passcode/passcode_screen.dart';
import 'package:cashpilot/widgets/main_shell.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

// Create router once — do NOT call inside a build/Consumer or it resets on every rebuild.
GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TransactionsScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BudgetsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionScreen(
            initialType: extra?['type'],
            transaction: extra?['transaction'],
          );
        },
      ),
      GoRoute(
        path: '/accounts',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/accounts/:id',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) =>
            AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transfer',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/settings/currency',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const CurrencyPickerScreen(),
      ),
      GoRoute(
        path: '/settings/categories',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/settings/debts',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const DebtTrackerScreen(),
      ),
      GoRoute(
        path: '/settings/reminders',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/passcode-lock',
        parentNavigatorKey: _rootNavKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PasscodeScreen(mode: extra?['mode'] ?? PasscodeMode.verify);
        },
      ),
    ],
  );
}
