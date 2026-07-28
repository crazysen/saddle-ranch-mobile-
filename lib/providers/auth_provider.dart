import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyEmail = 'auth_email';
  static const _keyPhoto = 'auth_photo';
  static const _keyFullName = 'auth_full_name';
  static const _keyPhone = 'auth_phone';
  static const _keyProfileComplete = 'auth_profile_complete';

  final ApiService _apiService;

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  AppUser? _user;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _googleReady = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get needsProfileSetup => _user != null && !_user!.profileComplete;

  Future<void> bootstrap() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _initGoogle();

      // Check if Sanctum token exists in secure storage first
      final token = await _apiService.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final profile = await _apiService.getProfile();
          _user = profile;
          await _persistLocalUserData(profile);
          _loading = false;
          notifyListeners();
          return;
        } catch (_) {
          // Invalid or expired token
          await _apiService.clearToken();
        }
      }

      // Fallback to local shared preferences if previously saved
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      if (loggedIn) {
        final email = prefs.getString(_keyEmail);
        if (email != null && email.isNotEmpty) {
          _user = AppUser(
            email: email,
            photoUrl: prefs.getString(_keyPhoto),
            fullName: prefs.getString(_keyFullName) ?? '',
            phone: prefs.getString(_keyPhone),
            profileComplete: prefs.getBool(_keyProfileComplete) ?? false,
          );
        }
      }
    } catch (_) {
      // Keep going with guest session.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password via Laravel Sanctum REST API
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email: email, password: password);
      
      // Extract user from API response or fetch profile
      AppUser user;
      if (response['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>)['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson((response['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      } else {
        user = await _apiService.getProfile();
      }

      _user = user;
      await _persistLocalUserData(user);
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Unable to connect to Saddle Ranch server. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Register customer account via Laravel Sanctum REST API
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      AppUser user;
      if (response['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>)['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson((response['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      } else {
        user = await _apiService.getProfile();
      }

      _user = user;
      await _persistLocalUserData(user);
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Registration failed. Please check your connection and try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _initGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    } catch (_) {
      _googleReady = false;
    }
  }

  /// Google Sign-In helper
  Future<bool> signInWithGoogle({bool allowDemoFallback = true}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      if (_googleReady && GoogleSignIn.instance.supportsAuthenticate()) {
        try {
          final account = await GoogleSignIn.instance.authenticate();
          await _persistNewGoogleUser(
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          );
          return true;
        } catch (e) {
          if (!allowDemoFallback) {
            _error = 'Google sign-in failed. Check OAuth setup.';
            return false;
          }
          await _persistNewGoogleUser(
            email: 'guest@gmail.com',
            displayName: '',
            photoUrl: null,
          );
          return true;
        }
      }

      if (!allowDemoFallback) {
        _error = 'Google sign-in is not available on this device.';
        return false;
      }

      await _persistNewGoogleUser(
        email: 'guest@gmail.com',
        displayName: '',
        photoUrl: null,
      );
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persistNewGoogleUser({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sameEmail = prefs.getString(_keyEmail) == email;
    final alreadyComplete =
        sameEmail && (prefs.getBool(_keyProfileComplete) ?? false);
    final existingName = prefs.getString(_keyFullName) ?? '';
    final name = (displayName ?? '').trim();

    _user = AppUser(
      email: email,
      photoUrl: photoUrl,
      fullName: alreadyComplete ? existingName : name,
      phone: alreadyComplete ? prefs.getString(_keyPhone) : null,
      profileComplete: alreadyComplete,
    );

    await _persistLocalUserData(_user!);
  }

  Future<void> _persistLocalUserData(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, user.email);
    if (user.photoUrl != null) {
      await prefs.setString(_keyPhoto, user.photoUrl!);
    } else {
      await prefs.remove(_keyPhoto);
    }
    await prefs.setString(_keyFullName, user.fullName);
    if (user.phone != null) {
      await prefs.setString(_keyPhone, user.phone!);
    } else {
      await prefs.remove(_keyPhone);
    }
    await prefs.setBool(_keyProfileComplete, user.profileComplete);
  }

  Future<void> completeProfile({
    required String fullName,
    String? phone,
  }) async {
    if (_user == null) return;
    final name = fullName.trim();
    if (name.isEmpty) {
      _error = 'Full name is required.';
      notifyListeners();
      return;
    }

    _busy = true;
    notifyListeners();

    try {
      final updated = _user!.copyWith(
        fullName: name,
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        profileComplete: true,
      );
      _user = updated;
      await _persistLocalUserData(updated);
      _error = null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    notifyListeners();
    try {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      await _apiService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, false);
      _user = null;
      _error = null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> clearLocalAccount() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhoto);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyProfileComplete);
    _user = null;
    notifyListeners();
  }
}
