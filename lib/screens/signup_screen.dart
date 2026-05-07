import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.cashier;

  void _handleSignup() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    // Create the account via Riverpod provider
    final newUser = UserAccount(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
      status: AccountStatus.pending, // Always pending on signup
    );

    ref.read(userProvider.notifier).addAccount(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration submitted! Awaiting administrator approval.'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
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
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
                const Text('Join the Meat Shop Management System', style: TextStyle(color: AppColors.textLight)),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Desired Role',
                    prefixIcon: Icon(Icons.assignment_ind_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                    DropdownMenuItem(value: UserRole.butcher, child: Text('Butcher')),
                    DropdownMenuItem(value: UserRole.cashier, child: Text('Cashier')),
                  ],
                  onChanged: (role) => setState(() => _selectedRole = role!),
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    ),
                    child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(color: AppColors.textLight)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
