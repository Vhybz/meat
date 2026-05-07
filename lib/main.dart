import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/cashier/cashier_pos.dart';
import 'screens/butcher/butcher_shell.dart';
import 'screens/admin/user_management_screen.dart';
import 'services/theme_provider.dart';

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
      title: 'Meat Shop Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/users': (context) => const UserManagementScreen(),
        '/cashier': (context) => const CashierPOS(),
        '/butcher': (context) => const ButcherShell(),
      },
    );
  }
}
