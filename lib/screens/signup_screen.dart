import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';
import '../services/auth_service.dart';
import '../services/sms_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _selectedDob;
  String? _selectedGender;
  UserRole _selectedRole = UserRole.cashier;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _phoneExists = false;
  Timer? _debounce;
  final _authService = AuthService();

  double _strength = 0;
  String _strengthLabel = 'None';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _phoneController.removeListener(_onPhoneChanged);
    _debounce?.cancel();
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final pass = _passwordController.text;
    double score = 0;

    if (pass.isEmpty) {
      setState(() {
        _strength = 0;
        _strengthLabel = 'None';
        _strengthColor = Colors.grey;
      });
      return;
    }

    if (pass.length >= 6) score += 0.25;
    if (pass.length >= 10) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(pass)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score += 0.1;

    setState(() {
      _strength = score;
      if (score <= 0.25) {
        _strengthLabel = 'Weak';
        _strengthColor = Colors.red;
      } else if (score <= 0.6) {
        _strengthLabel = 'Fair';
        _strengthColor = Colors.orange;
      } else if (score <= 0.8) {
        _strengthLabel = 'Good';
        _strengthColor = Colors.blue;
      } else {
        _strengthLabel = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  void _onPhoneChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final phone = _phoneController.text.trim();
      if (phone.length == 10) {
        final exists = await ref.read(userProvider.notifier).checkPhoneExists(phone);
        if (mounted) {
          setState(() {
            _phoneExists = exists;
          });
        }
      } else {
        if (_phoneExists) {
          setState(() {
            _phoneExists = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryMaroon,
              Color(0xFF4A0808),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.l),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixed Header Section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.1), width: 4),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        const Text(
                          'Staff Registration',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.primaryMaroon,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Text(
                          'Apply for a Mi Corazon team account', 
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable Form Section
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_firstNameController, 'First Name', Icons.person_outline, isName: true)),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(child: _buildTextField(_surnameController, 'Surname', Icons.person_outline, isName: true)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.m),
                            
                            _buildTextField(_emailController, 'Email Address', Icons.email_outlined, isEmail: true),
                            const SizedBox(height: AppSpacing.m),
                            
                            _buildTextField(_phoneController, 'Phone Number', Icons.phone_android_outlined, isPhone: true),
                            if (_phoneExists) ...[
                              const SizedBox(height: 4),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'This phone number is already in use. Please contact Admin.',
                                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.m),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), prefixIcon: Icon(Icons.wc)),
                                    items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (v) => setState(() => _selectedGender = v),
                                    validator: (v) => v == null ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime(2000),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                      );
                                      if (picked != null) setState(() => _selectedDob = picked);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.cake_outlined, size: 20, color: AppColors.textLight),
                                          const SizedBox(width: 8),
                                          Text(_selectedDob == null ? 'Date of Birth' : DateFormat('yyyy-MM-dd').format(_selectedDob!), 
                                            style: TextStyle(fontSize: 12, color: _selectedDob == null ? AppColors.textLight : AppColors.textDark)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.m),
                            
                            DropdownButtonFormField<UserRole>(
                              value: _selectedRole,
                              decoration: const InputDecoration(labelText: 'Applying For Role', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work_outline)),
                              items: [UserRole.cashier, UserRole.butcher, UserRole.admin].map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                              onChanged: (v) => setState(() => _selectedRole = v!),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            
                            _buildTextField(_passwordController, 'Password', Icons.lock_outline, isPassword: true),
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Strength: ', style: TextStyle(fontSize: 12)),
                                      Text(_strengthLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _strengthColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: _strength,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.m),
                            _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_reset_outlined, isPassword: true),
                            
                            const SizedBox(height: AppSpacing.xl),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryMaroon,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                                ),
                                child: _isLoading 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: AppSpacing.l),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?'),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false, bool isPassword = false, bool isPhone = false, bool isName = false}) {
    bool obscure = false;
    if (isPassword) {
      if (controller == _passwordController) {
        obscure = _obscurePassword;
      } else if (controller == _confirmPasswordController) {
        obscure = _obscureConfirmPassword;
      }
    }

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : (isName ? TextInputType.name : TextInputType.text)),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Strict: No whitespace allowed in any field
        if (isName) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')), // Names: Letters only
        if (isPhone) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () {
                  setState(() {
                    if (controller == _passwordController) {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
        filled: true,
        fillColor: Colors.grey.shade50,
        hintText: isPhone ? '10 digits' : null,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
        if (isPassword) {
           if (v.length < 6) return 'Min 6 characters';
           if (controller == _confirmPasswordController && v != _passwordController.text) return 'Passwords do not match';
        }
        if (isPhone) {
          if (v.length != 10) return 'Exactly 10 digits required';
          if (_phoneExists) return 'Phone number already exists';
        }
        if (isName && v.length < 2) return 'Too short';
        return null;
      },
    );
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your Date of Birth.')));
        return;
      }

      if (_phoneExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number already in use. Please contact Admin.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authResponse = await _authService.signUp(_emailController.text, _passwordController.text);
        
        if (authResponse.user != null) {
          final userNotifier = ref.read(userProvider.notifier);
          final adminExists = userNotifier.isAdminExists;
          final isFirstAdmin = !adminExists && _selectedRole == UserRole.admin;
          
          final newUser = UserAccount(
            id: authResponse.user!.id,
            firstName: _firstNameController.text,
            surname: _surnameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            gender: _selectedGender,
            dob: _selectedDob,
            role: _selectedRole,
            status: isFirstAdmin ? AccountStatus.approved : AccountStatus.pending,
            enabledPermissions: isFirstAdmin 
              ? {
                  '/admin', 
                  '/admin/sales', 
                  '/admin/expenses', 
                  '/admin/customers', 
                  '/admin/debts', 
                  '/admin/stock', 
                  '/admin/users', 
                  '/cashier', 
                  '/butcher', 
                  '/settings'
                } 
              : {'/settings'},
          );

          try {
            await userNotifier.addAccount(newUser);
            
            // Send confirmation SMS to the user
            await SmsService.sendSignupConfirmationSms(newUser, isFirstAdmin);

            if (!isFirstAdmin) {
              final allUsers = ref.read(userProvider);
              await SmsService.sendApprovalRequestSms(newUser, allUsers);
            }

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
                  title: Text(isFirstAdmin ? 'Registration Successful' : 'Application Submitted'),
                  content: Text(isFirstAdmin 
                    ? 'Your account has been created and approved as the primary administrator. You can now sign in.' 
                    : 'Your registration is pending administrator approval. You will be notified once approved.'),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              );
            }
          } catch (dbError) {
            // Rollback: Sign out user if profile creation fails
            await _authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile creation failed: $dbError'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
