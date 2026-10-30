import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/password_security.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/ridego_logo.dart';
import '../../auth/presentation/auth_providers.dart';

class OperatorRegisterScreen extends ConsumerStatefulWidget {
  const OperatorRegisterScreen({super.key});

  @override
  ConsumerState<OperatorRegisterScreen> createState() =>
      _OperatorRegisterScreenState();
}

class _OperatorRegisterScreenState
    extends ConsumerState<OperatorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitOperatorRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(authNotifierProvider.notifier)
            .registerOperator(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              ownerName: _ownerNameController.text.trim(),
              businessName: _businessNameController.text.trim(),
              contactNumber: _phoneController.text.trim(),
              businessLocation: _locationController.text.trim(),
            );
        // Sign out so the user is forced to sign in with their newly created account
        await ref.read(authNotifierProvider.notifier).signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Operator account registered! Please sign in with your credentials.',
              ),
              backgroundColor: AppColors.statusConfirmed,
              duration: Duration(seconds: 4),
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration error: $e'),
              backgroundColor: AppColors.statusCancelled,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operator Registration'),
        backgroundColor: AppColors.headerNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: RideGoLogo(size: 80, showText: false)),
                const SizedBox(height: 12),
                const Text(
                  'Register Your Transport Business',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headerNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join Samar & Leyte registered operator network',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),

                // Business Name
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business / Shop / Co-op Name',
                    prefixIcon: Icon(
                      Icons.storefront,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter business name'
                      : null,
                ),
                const SizedBox(height: 14),

                // Owner Name
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Owner / Authorized Representative Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter owner name'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Business Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: PasswordSecurity.validateEmail,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: PasswordSecurity.validatePassword,
                ),
                const SizedBox(height: 14),

                // Contact Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number (+63)',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter contact number'
                      : null,
                ),
                const SizedBox(height: 14),

                // Business Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText:
                        'Base Terminal / City (e.g. Catbalogan, Tacloban)',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.headerNavy,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter business location'
                      : null,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'SUBMIT APPLICATION',
                  isLoading: _isLoading,
                  onPressed: _submitOperatorRegistration,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
