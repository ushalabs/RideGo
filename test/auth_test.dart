import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/core/utils/password_security.dart';
import 'package:ridego/features/auth/data/auth_repository.dart';
import 'package:ridego/features/auth/models/operator_profile.dart';
import 'package:ridego/features/auth/models/user_profile.dart';
import 'package:ridego/features/auth/models/user_role.dart';

void main() {
  group('Phase 2: Authentication & User Roles Tests', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = AuthRepository();
    });

    test('Customer registration returns customer role', () async {
      final user = await authRepository.signUpCustomer(
        email: 'customer.samar@ridego.ph',
        password: 'Password123!',
        fullName: 'Catbalogan Commuter',
      );

      expect(user.email, 'customer.samar@ridego.ph');
      expect(user.fullName, 'Catbalogan Commuter');
      expect(user.role, UserRole.customer);
    });

    test('Operator registration sets pending status and prevents premature approval', () async {
      final operator = await authRepository.registerOperator(
        email: 'operator@grandtours.ph',
        password: 'Password123!',
        ownerName: 'Eduardo Tan',
        businessName: 'GrandTours Samar',
        contactNumber: '+63 917 555 4321',
        businessLocation: 'Catbalogan City',
      );

      expect(operator.ownerName, 'Eduardo Tan');
      expect(operator.businessName, 'GrandTours Samar');
      expect(operator.approvalStatus, OperatorApprovalStatus.pending);
      expect(operator.isApproved, isFalse);
      expect(operator.isPending, isTrue);
    });

    test('Role resolution defaults to customer when unassigned', () {
      expect(UserRole.fromString(null), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('operator'), UserRole.operator);
    });

    test('UserProfile JSON serialization preserves data integrity', () {
      final profile = UserProfile(
        id: 'user-uuid-1234',
        email: 'leyte.rider@ridego.ph',
        fullName: 'Tacloban Rider',
        role: UserRole.customer,
        createdAt: DateTime(2026, 10, 30),
      );

      final json = profile.toJson();
      expect(json['id'], 'user-uuid-1234');
      expect(json['full_name'], 'Tacloban Rider');
    });

    test('Sign in as Admin resolves to admin role and portal access', () async {
      final adminUser = await authRepository.signIn(
        email: 'admin@ridego.ph',
        password: 'SecureAdminPass123!',
      );

      expect(adminUser.role, UserRole.admin);
      expect(adminUser.role.displayName, 'Administrator');
    });

    test('Password Security: salted cryptographic hash verification', () {
      final salt = PasswordSecurity.generateSalt();
      final hash = PasswordSecurity.hashPassword('MySecretPass456!', salt);

      // Plaintext should never equal the hash
      expect(hash, isNot('MySecretPass456!'));

      // Correct password verification
      expect(
        PasswordSecurity.verifyPassword(
          password: 'MySecretPass456!',
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );

      // Wrong password verification strictly fails
      expect(
        PasswordSecurity.verifyPassword(
          password: 'WrongPassword!',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
    });

    test('Password Security: password validation requirements', () {
      expect(PasswordSecurity.validatePassword(null), isNotNull);
      expect(PasswordSecurity.validatePassword(''), isNotNull);
      expect(PasswordSecurity.validatePassword('12345'), isNotNull);
      expect(PasswordSecurity.validatePassword('123456'), isNull);
      expect(PasswordSecurity.validatePassword('ComplexPass123!'), isNull);

      expect(PasswordSecurity.validateEmail('invalid-email'), isNotNull);
      expect(PasswordSecurity.validateEmail('valid@user.com'), isNull);
    });

    test('Strict Authentication: rejects wrong password on sign in', () async {
      // 1. Register user
      await authRepository.signUpCustomer(
        email: 'secure.user@ridego.ph',
        password: 'RealSecretPassword99',
        fullName: 'Secure Commuter',
      );

      // 2. Try signing in with wrong password -> MUST throw exception
      expect(
        () async => await authRepository.signIn(
          email: 'secure.user@ridego.ph',
          password: 'WrongPasswordNonsense',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Incorrect password'),
          ),
        ),
      );

      // 3. Try signing in with correct password -> MUST succeed
      final user = await authRepository.signIn(
        email: 'secure.user@ridego.ph',
        password: 'RealSecretPassword99',
      );
      expect(user.fullName, 'Secure Commuter');
      expect(user.email, 'secure.user@ridego.ph');
    });

    test('Strict Authentication: rejects unregistered email', () async {
      expect(
        () async => await authRepository.signIn(
          email: 'ghost.user.random@ridego.ph',
          password: 'SomePassword123',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No account found'),
          ),
        ),
      );
    });
  });
}
