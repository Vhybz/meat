import 'package:flutter/material.dart';
import '../core/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.l),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon, size: 64),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Meat Shop Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
              ),
              const Text('Please login to your account', style: TextStyle(color: AppColors.textLight)),
              const SizedBox(height: AppSpacing.xl),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Butcher Dashboard for demo
                    Navigator.pushReplacementNamed(context, '/butcher');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Select Demo Role:', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/admin'), child: const Text('Admin')),
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/cashier'), child: const Text('Cashier')),
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/butcher'), child: const Text('Butcher')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
