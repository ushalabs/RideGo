import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cryptographic password security and validation service.
/// Uses salted SHA-256 hashing with secure random salts and a system pepper.
class PasswordSecurity {
  static const String _systemPepper = 'RideGo_Transport_SecureSalt_2026';

  /// Generates a cryptographically secure random salt encoded in Base64
  static String generateSalt([int byteLength = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Hashes a plaintext password using a per-account salt, pepper, and SHA-256
  static String hashPassword(String password, String salt) {
    final payload = '$salt:$_systemPepper:$password';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
  }

  /// Verifies that a plaintext password matches the stored salted hash
  static bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    if (password.isEmpty || salt.isEmpty || expectedHash.isEmpty) {
      return false;
    }
    final computedHash = hashPassword(password, salt);
    return computedHash == expectedHash;
  }

  /// Validates password strength and requirements
  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Validates email address syntax
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }
}
