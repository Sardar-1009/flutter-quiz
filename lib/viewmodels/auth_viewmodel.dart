import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

enum AuthState { idle, loading, authenticated, unauthenticated, error }

/// Whether the user just registered (needs onboarding) or logged in (skip).
enum AuthMode { login, register }

class AuthViewModel extends ChangeNotifier {
  final AuthService _service;
  final AnalyticsService _analytics;

  AuthViewModel({AuthService? service, AnalyticsService? analytics})
      : _service = service ?? AuthService(),
        _analytics = analytics ?? AnalyticsService() {
    // Listen to Firebase auth state
    _service.authStateChanges.listen((user) {
      if (user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  /// Tracks if the current session came from registration (to show onboarding).
  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  User? get currentUser => _service.currentUser;

  /// Mark new-user flag as consumed (after onboarding completes).
  void clearNewUserFlag() {
    _isNewUser = false;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _state = AuthState.loading;
    _errorMessage = '';
    _isNewUser = false;
    notifyListeners();

    try {
      await _service.signIn(email: email, password: password);
      await _analytics.logLogin(); // ← ANALYTICS
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      await _analytics.logAuthError(errorCode: e.code); // ← ANALYTICS
      _errorMessage = AuthService.friendlyError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Неизвестная ошибка: $e';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      await _service.register(email: email, password: password);
      await _analytics.logSignUp(); // ← ANALYTICS
      _isNewUser = true; // Flag for onboarding
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      await _analytics.logAuthError(errorCode: e.code); // ← ANALYTICS
      _errorMessage = AuthService.friendlyError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Неизвестная ошибка: $e';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _state = AuthState.unauthenticated;
    _isNewUser = false;
    notifyListeners();
  }
}
