import 'package:baatkaro/features/auth/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/providers/shared_providers.dart';

// Auth Repository Provider
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = ref.watch(dioProvider);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthRepository(dio, prefs);
});

// Auth Controller State
class AuthState {
  final bool isLoading;
  final String? error;
  final bool otpSent;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.otpSent = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? otpSent,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
      user: user ?? this.user,
    );
  }
}

// Auth Controller
class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthState());

  // Send OTP
  Future<void> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = await _ref.read(authRepositoryProvider.future);
      await repository.sendOtp(email);
      state = state.copyWith(isLoading: false, otpSent: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Verify OTP (only email and OTP)
  Future<User?> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = await _ref.read(authRepositoryProvider.future);
      final user = await repository.verifyOtp(email, otp);
      
      state = state.copyWith(isLoading: false, user: user);
      
      // Invalidate auth state to trigger navigation check
      _ref.invalidate(authStateProvider);
      
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  // Complete Onboarding (with optional profile photo)
  Future<bool> completeOnboarding(String name, {String? profilePhoto}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = await _ref.read(authRepositoryProvider.future);
      final user = await repository.completeOnboarding(
        name,
        profilePhoto: profilePhoto,
      );
      
      state = state.copyWith(isLoading: false, user: user);
      
      // Invalidate auth state to trigger navigation
      _ref.invalidate(authStateProvider);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final repository = await _ref.read(authRepositoryProvider.future);
      await repository.logout();
      
      state = AuthState(); // Reset state
      _ref.invalidate(authStateProvider);
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Reset OTP state (for back navigation)
  void resetOtpState() {
    state = AuthState();
  }
}

// Auth Controller Provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});