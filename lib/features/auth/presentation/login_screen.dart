import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/ridego_logo.dart';
import '../models/user_role.dart';
import 'auth_providers.dart';

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
            .signIn(_emailController.text.trim(), _passwordController.text);

        if (mounted) {
          setState(() => _isLoading = false);

          // Route based on role
          switch (profile.role) {
            case UserRole.admin:
              context.go('/admin/dashboard');
              break;
            case UserRole.operator:
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
              break;
            case UserRole.customer:
              context.go('/home');
              break;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

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
                  const Center(child: RideGoLogo(size: 130)),
                  const SizedBox(height: 32),

                  // Email input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
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
                  const SizedBox(height: 14),

                  // Login Button
                  CustomButton(
                    text: 'LOGIN',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.headerNavy,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.buttonTeal,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: Colors.white38),
                  const SizedBox(height: 12),

                  // Portal and Operator registration shortcuts
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.business,
                          size: 16,
                          color: AppColors.headerNavy,
                        ),
                        label: const Text(
                          'Register Operator',
                          style: TextStyle(
                            color: AppColors.headerNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => context.push('/operator/register'),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: AppColors.headerNavy,
                        ),
                        label: const Text(
                          'Admin Portal',
                          style: TextStyle(
                            color: AppColors.headerNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => context.push('/admin/dashboard'),
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
