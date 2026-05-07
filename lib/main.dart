import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/sales_reports_screen.dart';
import 'screens/admin/debt_management_screen.dart';
import 'screens/admin/inventory_control_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/cashier/cashier_pos.dart';
import 'screens/butcher/butcher_shell.dart';
import 'services/theme_provider.dart';

import 'screens/admin/super_admin_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MeatShopApp(),
    ),
  );
}

class MeatShopApp extends ConsumerWidget {
  const MeatShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Mi Corazon Freshmeat Butchery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/super': (context) => const SuperAdminScreen(),
        '/admin/sales': (context) => const SalesReportsScreen(),
        '/admin/debts': (context) => const DebtManagementScreen(),
        '/admin/stock': (context) => const InventoryControlScreen(),
        '/admin/users': (context) => const UserManagementScreen(),
        '/admin/settings': (context) => const SystemSettingsScreen(),
        '/cashier': (context) => const CashierPOS(),
        '/butcher': (context) => const ButcherShell(),
      },
    );
  }
}
