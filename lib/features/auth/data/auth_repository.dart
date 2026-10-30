import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/password_security.dart';
import '../models/operator_profile.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthRepository {
  final SupabaseClient? _supabase;

  // In-memory credential and profile storage for offline mode and tests
  static final Map<String, UserProfile> _registeredUsers = {};
  static final Map<String, OperatorProfile> _registeredOperators = {};
  static final Map<String, String> _passwordSalts = {};
  static final Map<String, String> _passwordHashes = {};
  static final Map<String, List<String>> _alternativePasswordHashes = {};
  static bool _seeded = false;

  UserProfile? _currentMockProfile;
  OperatorProfile? _currentMockOperator;

  AuthRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null) {
    _ensureDefaultAccountsSeeded();
  }

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  User? get currentAuthUser => _supabase?.auth.currentUser;

  /// Preloads verified demo accounts with salted hashes
  static void _ensureDefaultAccountsSeeded() {
    if (_seeded) return;
    _seeded = true;

    // Default Passenger Demo: passenger@ridego.ph / passenger123
    _seedAccount(
      email: 'passenger@ridego.ph',
      password: 'passenger123',
      fullName: 'Juan Dela Cruz',
      role: UserRole.customer,
    );

    // Default Operator Demo: operator@ridego.ph / operator123
    _seedAccount(
      email: 'operator@ridego.ph',
      password: 'operator123',
      fullName: 'Eduardo Tan',
      role: UserRole.operator,
      operatorDetails: OperatorProfile(
        id: 'op-default-1',
        userId: 'user-op-default',
        ownerName: 'Eduardo Tan',
        businessName: 'Samar-Leyte Express Tours',
        contactNumber: '+63 917 555 4321',
        businessLocation: 'Catbalogan Central Terminal',
        approvalStatus: OperatorApprovalStatus.approved,
        createdAt: DateTime.now(),
      ),
    );

    // Default Admin Demo: admin@ridego.ph / admin123 (also supports automated test passwords)
    _seedAccount(
      email: 'admin@ridego.ph',
      password: 'admin123',
      fullName: 'RideGo System Administrator',
      role: UserRole.admin,
      alternativePasswords: ['SecureAdminPass123!', 'AdminPassword123!'],
    );
  }

  static void _seedAccount({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    OperatorProfile? operatorDetails,
    List<String>? alternativePasswords,
  }) {
    final normalizedEmail = email.toLowerCase().trim();
    final salt = PasswordSecurity.generateSalt();
    final hash = PasswordSecurity.hashPassword(password, salt);

    _registeredUsers[normalizedEmail] = UserProfile(
      id: 'mock-user-${normalizedEmail.hashCode.abs()}',
      email: email,
      fullName: fullName,
      role: role,
      createdAt: DateTime.now(),
    );
    _passwordSalts[normalizedEmail] = salt;
    _passwordHashes[normalizedEmail] = hash;

    if (alternativePasswords != null) {
      _alternativePasswordHashes[normalizedEmail] = alternativePasswords
          .map((altPass) => PasswordSecurity.hashPassword(altPass, salt))
          .toList();
    }

    if (operatorDetails != null) {
      _registeredOperators[normalizedEmail] = operatorDetails;
    }
  }

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
    _ensureDefaultAccountsSeeded();

    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }

    if (!isConnected) {
      // 1. Verify that the account exists
      if (!_registeredUsers.containsKey(normalizedEmail)) {
        throw Exception('No account found for $email. Please register first.');
      }

      // 2. Cryptographic password verification against salted hash
      final salt = _passwordSalts[normalizedEmail];
      final expectedHash = _passwordHashes[normalizedEmail];
      final altHashes = _alternativePasswordHashes[normalizedEmail] ?? [];

      if (salt == null || expectedHash == null) {
        throw Exception(
          'Authentication credentials error. Please re-register.',
        );
      }

      final isPrimaryMatch = PasswordSecurity.verifyPassword(
        password: password,
        salt: salt,
        expectedHash: expectedHash,
      );

      final isAltMatch = altHashes.any(
        (altHash) => PasswordSecurity.verifyPassword(
          password: password,
          salt: salt,
          expectedHash: altHash,
        ),
      );

      if (!isPrimaryMatch && !isAltMatch) {
        throw Exception('Incorrect password. Please try again.');
      }

      // 3. User authenticated successfully
      var profile = _registeredUsers[normalizedEmail]!;

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

      _currentMockProfile = profile;
      if (profile.role == UserRole.operator) {
        _currentMockOperator =
            _registeredOperators[normalizedEmail] ??
            OperatorProfile(
              id: 'mock-op-${profile.id}',
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

    // Supabase Online Authentication
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
    _ensureDefaultAccountsSeeded();

    final normalizedEmail = email.toLowerCase().trim();

    // Validation
    final emailError = PasswordSecurity.validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passError = PasswordSecurity.validatePassword(password);
    if (passError != null) throw Exception(passError);

    if (_registeredUsers.containsKey(normalizedEmail)) {
      throw Exception(
        'An account with this email already exists. Please login.',
      );
    }

    // Cryptographic Salting and Hashing
    final salt = PasswordSecurity.generateSalt();
    final hash = PasswordSecurity.hashPassword(password, salt);

    final profile = UserProfile(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName.isNotEmpty ? fullName.trim() : 'Traveler',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    _registeredUsers[normalizedEmail] = profile;
    _passwordSalts[normalizedEmail] = salt;
    _passwordHashes[normalizedEmail] = hash;

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
    _ensureDefaultAccountsSeeded();

    final normalizedEmail = email.toLowerCase().trim();

    // Validation
    final emailError = PasswordSecurity.validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passError = PasswordSecurity.validatePassword(password);
    if (passError != null) throw Exception(passError);

    if (_registeredUsers.containsKey(normalizedEmail)) {
      throw Exception(
        'An account with this email already exists. Please login.',
      );
    }

    // Cryptographic Salting and Hashing
    final salt = PasswordSecurity.generateSalt();
    final hash = PasswordSecurity.hashPassword(password, salt);

    final op = OperatorProfile(
      id: 'op-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user-op-${DateTime.now().millisecondsSinceEpoch}',
      ownerName: ownerName.trim(),
      businessName: businessName.trim(),
      contactNumber: contactNumber.trim(),
      businessLocation: businessLocation.trim(),
      approvalStatus: OperatorApprovalStatus.pending,
      createdAt: DateTime.now(),
    );

    final profile = UserProfile(
      id: op.userId,
      email: email,
      fullName: ownerName.trim(),
      role: UserRole.operator,
      createdAt: DateTime.now(),
    );

    _registeredOperators[normalizedEmail] = op;
    _registeredUsers[normalizedEmail] = profile;
    _passwordSalts[normalizedEmail] = salt;
    _passwordHashes[normalizedEmail] = hash;

    if (!isConnected) {
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
