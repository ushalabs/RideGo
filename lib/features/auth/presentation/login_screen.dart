import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/ridego_logo.dart';
import '../models/user_role.dart';
import 'auth_providers.dart';

enum LoginType { customer, operator }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  LoginType _selectedType = LoginType.customer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final profile = await ref
            .read(authNotifierProvider.notifier)
            .signIn(
              _emailController.text.trim(),
              _passwordController.text,
              preferredRole: _selectedType == LoginType.operator
                  ? UserRole.operator
                  : UserRole.customer,
            );

        if (mounted) {
          setState(() => _isLoading = false);

          // Route based on role and portal
          if (profile.role == UserRole.admin) {
            context.go('/admin/dashboard');
          } else if (_selectedType == LoginType.operator ||
              profile.role == UserRole.operator) {
            final op = await ref
                .read(authRepositoryProvider)
                .getOperatorProfile(profile.id);
            if (mounted) {
              if (op != null && !op.isApproved) {
                context.go('/operator/pending');
              } else {
                context.go('/operator/dashboard');
              }
            }
          } else {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login failed: ${e.toString().replaceAll("Exception:", "").trim()}',
              ),
              backgroundColor: AppColors.statusCancelled,
            ),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your registered email address to receive password reset instructions.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonTeal,
            ),
            onPressed: () {
              ref
                  .read(authRepositoryProvider)
                  .sendPasswordReset(resetController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password reset instructions sent if email exists.',
                  ),
                  backgroundColor: AppColors.headerNavy,
                ),
              );
            },
            child: const Text(
              'Send Reset Link',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _fillDemoCredentials(LoginType type) {
    if (type == LoginType.customer) {
      _emailController.text = 'passenger@ridego.ph';
      _passwordController.text = 'passenger123';
      setState(() => _selectedType = LoginType.customer);
    } else {
      _emailController.text = 'operator@ridego.ph';
      _passwordController.text = 'operator123';
      setState(() => _selectedType = LoginType.operator);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;
    final isOperator = _selectedType == LoginType.operator;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? (size.width - 440) / 2 : 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const Center(child: RideGoLogo(size: 110)),
                  const SizedBox(height: 20),

                  // Two-Way Role Segmented Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardSubtle,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.buttonTeal.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = LoginType.customer;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: !isOperator
                                    ? AppColors.buttonTeal
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 18,
                                      color: !isOperator
                                          ? Colors.white
                                          : AppColors.headerNavy,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Passenger',
                                      style: TextStyle(
                                        color: !isOperator
                                            ? Colors.white
                                            : AppColors.headerNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = LoginType.operator;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isOperator
                                    ? AppColors.headerNavy
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.airport_shuttle,
                                      size: 18,
                                      color: isOperator
                                          ? Colors.white
                                          : AppColors.headerNavy,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Vehicle Provider',
                                      style: TextStyle(
                                        color: isOperator
                                            ? Colors.white
                                            : AppColors.headerNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    isOperator
                        ? 'Vehicle Provider & Fleet Sign In'
                        : 'Passenger & Commuter Sign In',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOperator
                        ? 'Manage your transport fleet, terminals, fares & bookings'
                        : 'Book buses, vans and motorcycle rides across Samar & Leyte',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: isOperator ? 'Operator Email' : 'Email Address',
                      prefixIcon: Icon(
                        isOperator ? Icons.business : Icons.email_outlined,
                        color: AppColors.headerNavy,
                      ),
                      fillColor: Colors.white.withOpacity(0.95),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!val.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.headerNavy,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      fillColor: Colors.white.withOpacity(0.95),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.headerNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login Button
                  CustomButton(
                    text: 'LOGIN',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 18),

                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOperator
                            ? 'Need to register your fleet? '
                            : "Don't have an account? ",
                        style: const TextStyle(
                          color: AppColors.headerNavy,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (isOperator) {
                            context.push('/operator/register');
                          } else {
                            context.push('/register');
                          }
                        },
                        child: Text(
                          isOperator ? 'Register Operator' : 'Sign Up',
                          style: TextStyle(
                            color: isOperator
                                ? AppColors.headerNavy
                                : AppColors.buttonTeal,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white38),
                  const SizedBox(height: 8),

                  // Quick Demo Switchers
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.person, size: 14),
                        label: const Text('Passenger Demo'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.buttonTeal,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          _fillDemoCredentials(LoginType.customer);
                          _handleLogin();
                        },
                      ),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      TextButton.icon(
                        icon: const Icon(Icons.airport_shuttle, size: 14),
                        label: const Text('Operator Demo'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.headerNavy,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          _fillDemoCredentials(LoginType.operator);
                          _handleLogin();
                        },
                      ),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => context.push('/admin/dashboard'),
                        child: const Text('Admin'),
                      ),
                    ],
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
