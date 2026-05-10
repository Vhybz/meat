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
import 'screens/admin/expense_management_screen.dart';
import 'screens/admin/customer_management_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/cashier/cashier_pos.dart';
import 'screens/butcher/butcher_shell.dart';
import 'screens/settings_screen.dart';
import 'services/theme_provider.dart';
import 'core/supabase_config.dart';

import 'screens/admin/super_admin_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('Initializing Supabase...');
    await SupabaseConfig.initialize();
    debugPrint('Supabase initialized successfully.');

    runApp(
      const ProviderScope(
        child: MeatShopApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('ERROR DURING INIT: $e');
    debugPrint('STACKTRACE: $stack');
    // Fallback to error screen if needed
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Initialization Error: $e')))));
  }
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
        '/admin/expenses': (context) => const ExpenseManagementScreen(),
        '/admin/customers': (context) => const CustomerManagementScreen(),
        '/admin/debts': (context) => const DebtManagementScreen(),
        '/admin/stock': (context) => const InventoryControlScreen(),
        '/admin/users': (context) => const UserManagementScreen(),
        '/admin/settings': (context) => const SystemSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/cashier': (context) => const CashierPOS(),
        '/butcher': (context) => const ButcherShell(),
      },
    );
  }
}
