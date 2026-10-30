import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/operator_profile.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthRepository {
  final SupabaseClient? _supabase;

  // In-memory session fallback for tests and offline preview
  static final Map<String, UserProfile> _registeredUsers = {};
  static final Map<String, OperatorProfile> _registeredOperators = {};
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
      if (_currentMockProfile != null) return _currentMockProfile!;
      final normalizedEmail = email.toLowerCase().trim();
      if (_registeredUsers.containsKey(normalizedEmail)) {
        return _registeredUsers[normalizedEmail]!;
      }
      return UserProfile(
        id: userId,
        email: email.isNotEmpty ? email : 'customer@ridego.ph',
        fullName: email.isNotEmpty ? email.split('@').first : 'Traveler',
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
    UserRole? preferredRole,
  }) async {
    if (!isConnected) {
      final normalizedEmail = email.toLowerCase().trim();
      UserProfile profile;

      if (_registeredUsers.containsKey(normalizedEmail)) {
        profile = _registeredUsers[normalizedEmail]!;
        if (preferredRole == UserRole.operator &&
            profile.role == UserRole.customer) {
          profile = UserProfile(
            id: profile.id,
            email: profile.email,
            fullName: profile.fullName,
            role: UserRole.operator,
            createdAt: profile.createdAt,
          );
          _registeredUsers[normalizedEmail] = profile;
        }
      } else {
        // Offline / Demo authentication
        final role =
            preferredRole ??
            (email.contains('admin')
                ? UserRole.admin
                : (email.contains('operator')
                      ? UserRole.operator
                      : UserRole.customer));

        String derivedName = 'Traveler';
        if (email.contains('admin')) {
          derivedName = 'Administrator';
        } else if (email.contains('operator')) {
          derivedName = 'Eduardo Tan';
        } else if (email.contains('@')) {
          final prefix = email
              .split('@')
              .first
              .replaceAll(RegExp(r'[._0-9]'), ' ')
              .trim();
          derivedName = prefix.isNotEmpty
              ? prefix
                    .split(' ')
                    .map(
                      (w) => w.isNotEmpty
                          ? '${w[0].toUpperCase()}${w.substring(1)}'
                          : '',
                    )
                    .join(' ')
                    .trim()
              : 'Traveler';
        }

        profile = UserProfile(
          id: 'mock-user-${email.hashCode}',
          email: email,
          fullName: derivedName.isNotEmpty ? derivedName : 'Traveler',
          role: role,
          createdAt: DateTime.now(),
        );
        _registeredUsers[normalizedEmail] = profile;
      }

      _currentMockProfile = profile;
      if (profile.role == UserRole.operator) {
        _currentMockOperator =
            _registeredOperators[normalizedEmail] ??
            OperatorProfile(
              id: 'mock-op-1',
              userId: profile.id,
              ownerName: profile.fullName,
              businessName: 'Samar-Leyte Express Tours',
              contactNumber: '+63 917 555 4321',
              businessLocation: 'Catbalogan Central Terminal',
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
    final profile = UserProfile(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName.isNotEmpty ? fullName : 'Traveler',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    _registeredUsers[email.toLowerCase().trim()] = profile;

    if (!isConnected) {
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
      final profile = UserProfile(
        id: op.userId,
        email: email,
        fullName: ownerName,
        role: UserRole.operator,
        createdAt: DateTime.now(),
      );
      _registeredOperators[email.toLowerCase().trim()] = op;
      _registeredUsers[email.toLowerCase().trim()] = profile;
      _currentMockOperator = op;
      _currentMockProfile = profile;
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
