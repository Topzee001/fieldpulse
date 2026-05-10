import 'package:fieldpulse/src/app/providers/dio_provider.dart';
import 'package:fieldpulse/src/features/auth/models/user.dart';
import 'package:fieldpulse/src/features/auth/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.read(dioProvider), ref.read(secureStorageProvider)),
);

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  AuthNotifier(this._authRepo) : super(AuthState()) {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final user = await _authRepo.getCurrentUser();
    if (user != null && await _authRepo.getAccessToken() != null) {
      state = AuthState(user: user);
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final result = await _authRepo.login(email, password);
      state = AuthState(user: result.user, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false, user: null);
      return false;
    }
  }

  Future<bool> biometricLogin() async {
    state = AuthState(isLoading: true);
    try {
      final result = await _authRepo.biometricLogin();
      state = AuthState(user: result.user, isLoading: false, error: null);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false, user: null);
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState(isLoading: true);
    await _authRepo.logout();
    state = AuthState();
  }
}
