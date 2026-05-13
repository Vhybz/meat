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
      await Supabase.initialize(
        url: url, 
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
      );
    }

    runApp(
      const ProviderScope(
        child: MeatShopApp(),
      ),
    );
  } catch (e) {
    debugPrint('CRITICAL INITIALIZATION FAILURE: $e');
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InitializationErrorScreen(),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF6B1111), // App Maroon
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 80),
                const SizedBox(height: 32),
                const Text(
                  'Configuration Missing',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'The application cannot connect to the database because the Supabase configuration is missing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                ),
                const SizedBox(height: 40),
                _buildErrorBox(
                  'LOCAL DEVELOPMENT (VS Code/Android Studio)',
                  'Ensure you have a .env file in the root folder with:\nSUPABASE_URL=your_url\nSUPABASE_ANON_KEY=your_key',
                ),
                const SizedBox(height: 16),
                _buildErrorBox(
                  'PRODUCTION/WEB DEPLOYMENT',
                  'Provide these as environment variables during build using --dart-define or --dart-define-from-file.',
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _showManualConfigDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6B1111),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ENTER CONFIG MANUALLY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'After updating configuration, please restart the app or refresh your browser.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  Widget _buildErrorBox(String title, String content) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

void _showManualConfigDialog(BuildContext context) {
  final urlController = TextEditingController();
  final keyController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Manual Supabase Config'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Supabase URL', hintText: 'https://xxx.supabase.co'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: keyController,
            decoration: const InputDecoration(labelText: 'Anon Key'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () async {
            if (urlController.text.isNotEmpty && keyController.text.isNotEmpty) {
              try {
                await Supabase.initialize(
                  url: urlController.text.trim(),
                  anonKey: keyController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  // Since we are in a minimal MaterialApp, just showing success
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Config saved! Please refresh the page.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Initialization failed: $e')),
                  );
                }
              }
            }
          },
          child: const Text('INITIALIZE'),
        ),
      ],
    ),
  );
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
