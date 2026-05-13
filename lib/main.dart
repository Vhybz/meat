import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'screens/admin/butcher_analytics_screen.dart';
import 'screens/cashier/cashier_pos.dart';
import 'screens/butcher/butcher_shell.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'services/theme_provider.dart';
import 'services/sync_provider.dart';
import 'core/supabase_config.dart';

import 'screens/admin/super_admin_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // Enable edge-to-edge support
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Explicitly check for configuration before calling the config class
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('Supabase Environment Variables not found in build. Attempting .env file fallback...');
      await SupabaseConfig.initialize();
    } else {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }

    runApp(
      const ProviderScope(
        child: MeatShopApp(),
      ),
    );
  } catch (e) {
    debugPrint('CRITICAL INITIALIZATION FAILURE: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            color: const Color(0xFF6B1111), // App Maroon
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Failure',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The application failed to start because the Supabase configuration is missing in the production build.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Action Required:\nAdd SUPABASE_URL and SUPABASE_ANON_KEY to Netlify Environment Variables AND update the build command to use --dart-define.',
                      style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MeatShopApp extends ConsumerWidget {
  const MeatShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    // Initialize background sync
    ref.watch(syncProvider);

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
        '/admin/butcher': (context) => const ButcherAnalyticsScreen(),
        '/admin/settings': (context) => const SystemSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/cashier': (context) => const CashierPOS(),
        '/butcher': (context) => const ButcherShell(),
      },
    );
  }
}
