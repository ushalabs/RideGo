import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/operator_profile.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserProfile> signIn(
    String email,
    String password, {
    UserRole? preferredRole,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(
        email: email,
        password: password,
        preferredRole: preferredRole,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUpCustomer(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<OperatorProfile> registerOperator({
    required String email,
    required String password,
    required String ownerName,
    required String businessName,
    required String contactNumber,
    required String businessLocation,
  }) async {
    try {
      final op = await _repo.registerOperator(
        email: email,
        password: password,
        ownerName: ownerName,
        businessName: businessName,
        contactNumber: contactNumber,
        businessLocation: businessLocation,
      );
      await checkCurrentUser();
      return op;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthNotifier(repo);
    });

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authNotifierProvider).value;
});
