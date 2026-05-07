import 'package:flutter/material.dart';
import '../core/constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    final username = _emailController.text.trim();
    final password = _passwordController.text;

    // Hardcoded Super Admin Login
    if (username == 'admin' && password == 'admin123') {
      Navigator.pushReplacementNamed(context, '/admin/super');
      return;
    }

    // Check against registered users
    final users = ref.read(userProvider);
    try {
      final user = users.firstWhere(
        (u) => u.email == username || u.name == username,
      );

      if (user.status == AccountStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is awaiting administrator approval.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (user.status == AccountStatus.suspended) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been suspended.'), backgroundColor: Colors.red),
        );
        return;
      }

      // Successful "demo" login
      switch (user.role) {
        case UserRole.admin:
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case UserRole.butcher:
          Navigator.pushReplacementNamed(context, '/butcher');
          break;
        case UserRole.cashier:
          Navigator.pushReplacementNamed(context, '/cashier');
          break;
        case UserRole.superAdmin:
          Navigator.pushReplacementNamed(context, '/admin/super');
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials or account not found.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.l),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  child: Image.asset(
                    'assets/logo/logo.jpg',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                const Text(
                  'Mi CORAZON',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
                const Text(
                  'FRESHMEAT BUTCHERY',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryMaroon, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text('Sign in with your credentials', style: TextStyle(color: AppColors.textLight)),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?', style: TextStyle(color: AppColors.textLight)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('Register Here', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('TEST ACCESS', style: TextStyle(color: AppColors.textLight, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _testAccessButton('Admin', '/admin', Colors.blue),
                    _testAccessButton('Cashier', '/cashier', Colors.green),
                    _testAccessButton('Butcher', '/butcher', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _testAccessButton(String label, String route, Color color) {
    return OutlinedButton(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
