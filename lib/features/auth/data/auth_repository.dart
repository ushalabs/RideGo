import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/operator_profile.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthRepository {
  final SupabaseClient? _supabase;

  // In-memory session fallback for tests and offline preview
  UserProfile? _currentMockProfile;
  OperatorProfile? _currentMockOperator;

  AuthRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  User? get currentAuthUser => _supabase?.auth.currentUser;

  Future<UserProfile?> getCurrentUser() async {
    if (!isConnected) {
      return _currentMockProfile;
    }

    final user = _supabase!.auth.currentUser;
    if (user == null) return null;

    return await getUserProfile(user.id, user.email ?? '');
  }

  Future<UserProfile> getUserProfile(String userId, [String email = '']) async {
    if (!isConnected) {
      return _currentMockProfile ??
          UserProfile(
            id: userId,
            email: email.isNotEmpty ? email : 'customer@ridego.ph',
            fullName: 'Kiya Vance',
            role: UserRole.customer,
            createdAt: DateTime.now(),
          );
    }

    try {
      final res = await _supabase!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      final roleRes = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final roleStr = roleRes?['role'] as String?;
      final role = UserRole.fromString(roleStr);

      if (res != null) {
        return UserProfile.fromJson(res, email: email, role: role);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching profile from Supabase: $e');
    }

    return UserProfile(
      id: userId,
      email: email,
      fullName: 'Commuter',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
  }

  Future<OperatorProfile?> getOperatorProfile(String userId) async {
    if (!isConnected) {
      return _currentMockOperator;
    }

    try {
      final res = await _supabase!
          .from('operators')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        return OperatorProfile.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching operator profile: $e');
    }
    return null;
  }

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConnected) {
      // Offline / Demo authentication
      final role = email.contains('admin')
          ? UserRole.admin
          : (email.contains('operator')
                ? UserRole.operator
                : UserRole.customer);

      final profile = UserProfile(
        id: 'mock-user-${email.hashCode}',
        email: email,
        fullName: email.contains('admin')
            ? 'Administrator'
            : (email.contains('operator') ? 'Eduardo Tan' : 'Kiya Vance'),
        role: role,
        createdAt: DateTime.now(),
      );

      _currentMockProfile = profile;
      if (role == UserRole.operator) {
        _currentMockOperator = OperatorProfile(
          id: 'mock-op-1',
          userId: profile.id,
          ownerName: 'Eduardo Tan',
          businessName: 'GrandTours Samar',
          contactNumber: '+63 917 555 4321',
          businessLocation: 'Catbalogan, Samar',
          approvalStatus: OperatorApprovalStatus.approved,
          createdAt: DateTime.now(),
        );
      }

      return profile;
    }

    final res = await _supabase!.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Authentication failed. No user returned.');
    }

    return await getUserProfile(user.id, user.email ?? email);
  }

  Future<UserProfile> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!isConnected) {
      final profile = UserProfile(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
      _currentMockProfile = profile;
      return profile;
    }

    final res = await _supabase!.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'customer'},
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Registration failed.');
    }

    return UserProfile(
      id: user.id,
      email: email,
      fullName: fullName,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
  }

  Future<OperatorProfile> registerOperator({
    required String email,
    required String password,
    required String ownerName,
    required String businessName,
    required String contactNumber,
    required String businessLocation,
  }) async {
    if (!isConnected) {
      final op = OperatorProfile(
        id: 'mock-op-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'mock-user-op',
        ownerName: ownerName,
        businessName: businessName,
        contactNumber: contactNumber,
        businessLocation: businessLocation,
        approvalStatus: OperatorApprovalStatus.pending,
        createdAt: DateTime.now(),
      );
      _currentMockOperator = op;
      _currentMockProfile = UserProfile(
        id: op.userId,
        email: email,
        fullName: ownerName,
        role: UserRole.operator,
        createdAt: DateTime.now(),
      );
      return op;
    }

    final res = await _supabase!.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': ownerName,
        'role': 'operator',
        'business_name': businessName,
        'contact_number': contactNumber,
        'business_location': businessLocation,
      },
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Operator registration failed.');
    }

    return OperatorProfile(
      id: 'op-${user.id}',
      userId: user.id,
      ownerName: ownerName,
      businessName: businessName,
      contactNumber: contactNumber,
      businessLocation: businessLocation,
      approvalStatus: OperatorApprovalStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    if (isConnected) {
      await _supabase!.auth.resetPasswordForEmail(email);
    }
  }

  Future<void> signOut() async {
    if (isConnected) {
      await _supabase!.auth.signOut();
    }
    _currentMockProfile = null;
    _currentMockOperator = null;
  }
}
