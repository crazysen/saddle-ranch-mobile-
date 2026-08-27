import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/google_auth_config.dart';
import '../models/app_user.dart';
import '../models/register_status.dart';
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
  String? _pendingVerificationEmail;
  bool _requiresEmailVerification = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get needsProfileSetup => _user != null && !_user!.profileComplete;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get requiresEmailVerification => _requiresEmailVerification;
  bool get googleReady => _googleReady;

  /// Ensures Google Sign-In SDK is initialized (needed before web GIS button).
  Future<bool> ensureGoogleReady() async {
    if (!_googleReady) {
      await _initGoogle();
    }
    return _googleReady;
  }

  Future<void> bootstrap() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _initGoogle();

      // Only restore a session when a Sanctum token is valid.
      // Never trust prefs-only "demo" users (e.g. Juan Dela Cruz).
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
          await _apiService.clearToken();
        }
      }

      // Clear stale local demo/profile leftovers from older builds.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoggedIn);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPhoto);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyProfileComplete);
      _user = null;
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
    _requiresEmailVerification = false;
    _pendingVerificationEmail = null;
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
      if (e.requiresEmailVerification) {
        _requiresEmailVerification = true;
        _pendingVerificationEmail =
            e.email ?? email.trim().toLowerCase();
      }
      return false;
    } catch (e) {
      _error = 'Unable to connect to Saddle Ranch server. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Register customer account, then always continue to 6-digit email verification.
  /// Never auto-login after signup (even if the live API still returns a user payload).
  Future<RegisterStatus> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _busy = true;
    _error = null;
    _requiresEmailVerification = false;
    _pendingVerificationEmail = null;
    notifyListeners();

    try {
      final cleanedEmail = email.trim().toLowerCase();
      final regResponse = await _apiService.register(
        name: name.trim(),
        email: cleanedEmail,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      // Clear any token the old register API may have stored — signup must verify first.
      try {
        await _apiService.clearToken();
      } catch (_) {}

      _user = null;
      _pendingVerificationEmail =
          regResponse['email']?.toString() ?? cleanedEmail;
      _requiresEmailVerification = true;
      _error = null;

      // If the old register endpoint didn't email a code, try resend (once deployed).
      if (regResponse['requires_email_verification'] != true) {
        try {
          await _apiService.resendVerification(email: _pendingVerificationEmail!);
        } catch (_) {
          // Verify / resend may not be on Render yet — UI still shows the code screen.
        }
      }

      return RegisterStatus.needsEmailVerification;
    } on ApiException catch (e) {
      if (e.requiresEmailVerification) {
        _requiresEmailVerification = true;
        _pendingVerificationEmail = e.email ?? email.trim().toLowerCase();
        _error = null;
        return RegisterStatus.needsEmailVerification;
      }
      _error = e.message;
      return RegisterStatus.failed;
    } catch (e) {
      _error = 'Registration failed. Please check your connection and try again.';
      return RegisterStatus.failed;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Confirm signup with the 6-digit email code, then establish Sanctum session.
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.verifyEmail(email: email, code: code);

      // Do not log in the user directly — clear any session and require login
      try {
        await _apiService.clearToken();
      } catch (_) {}

      _user = null;
      _pendingVerificationEmail = null;
      _requiresEmailVerification = false;
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to verify email. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Resend the 6-digit verification email.
  Future<String?> resendVerificationCode({required String email}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.resendVerification(email: email);
      final message = response['message']?.toString() ??
          'A new verification code has been sent.';
      _error = null;
      return message;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Unable to resend code. Please try again.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Request a 6-digit password reset code by email.
  /// Returns a user-facing success message on success.
  Future<String?> requestPasswordReset({required String email}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email: email);
      final message = response['message']?.toString() ??
          'If that email is registered, a 6-digit reset code has been sent.';
      _error = null;
      return message;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Unable to send reset code. Please try again.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Reset password with email + 6-digit code, then sign in.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final cleanedEmail = email.trim().toLowerCase();
      final response = await _apiService.resetPassword(
        email: cleanedEmail,
        code: code,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      Map<String, dynamic> session = response;
      final token =
          response['token'] ?? response['access_token'] ?? response['data']?['token'];

      if (token == null || token.toString().isEmpty) {
        session = await _apiService.login(
          email: cleanedEmail,
          password: password,
        );
      }

      AppUser user;
      if (session['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(session['user'] as Map<String, dynamic>);
      } else if (session['data'] is Map<String, dynamic> &&
          (session['data'] as Map<String, dynamic>)['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(
            (session['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      } else if (session['data'] is Map<String, dynamic> &&
          (session['data'] as Map<String, dynamic>).containsKey('id')) {
        user = AppUser.fromJson(session['data'] as Map<String, dynamic>);
      } else if (response['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
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
    } catch (_) {
      _error = 'Unable to reset password. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _initGoogle() async {
    try {
      final serverClientId = GoogleAuthConfig.serverClientId.trim();
      final iosClientId = GoogleAuthConfig.iosClientId.trim();

      // Web requires the Web OAuth client as `clientId`.
      // Mobile uses platform config / iOS client ID; `serverClientId` requests an ID token.
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb
            ? (serverClientId.isEmpty ? null : serverClientId)
            : (iosClientId.isEmpty ? null : iosClientId),
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _googleReady = true;
    } catch (_) {
      _googleReady = false;
    }
  }

  /// Google Sign-In → verify ID token on Laravel → Sanctum session.
  /// Failures surface as errors (no local demo user).
  Future<bool> signInWithGoogle() async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      if (!_googleReady) {
        await _initGoogle();
      }

      if (!GoogleAuthConfig.isConfigured) {
        _error =
            'Google Sign-In is not configured. Run with --dart-define=GOOGLE_SERVER_CLIENT_ID=...';
        return false;
      }

      if (!_googleReady) {
        _error = 'Google Sign-In failed to initialize.';
        return false;
      }

      // Chrome/web cannot call authenticate() — use the GIS renderButton instead.
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        _error =
            'On web, use the Google button below (GIS). Custom Continue with Google is for mobile.';
        return false;
      }

      try {
        final account = await GoogleSignIn.instance.authenticate();
        return await _completeGoogleAccountSignIn(account);
      } catch (e) {
        _error = 'Google sign-in failed. $e';
        return false;
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Used by web GIS `renderButton` via authenticationEvents.
  Future<bool> completeGoogleSignInFromAccount(GoogleSignInAccount account) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (!_googleReady) {
        await _initGoogle();
      }
      if (!_googleReady) {
        _error = 'Google Sign-In failed to initialize.';
        return false;
      }
      return await _completeGoogleAccountSignIn(account);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _completeGoogleAccountSignIn(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      _error =
          'Google did not return an ID token. Check that GOOGLE_SERVER_CLIENT_ID is your Web client ID.';
      return false;
    }

    try {
      final response = await _apiService.loginWithGoogle(idToken: idToken);

      AppUser user;
      if (response['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic> &&
          (response['data'] as Map<String, dynamic>)['user']
              is Map<String, dynamic>) {
        user = AppUser.fromJson(
          (response['data'] as Map<String, dynamic>)['user']
              as Map<String, dynamic>,
        );
      } else {
        user = await _apiService.getProfile();
      }

      if ((user.photoUrl == null || user.photoUrl!.isEmpty) &&
          account.photoUrl != null) {
        user = user.copyWith(photoUrl: account.photoUrl);
      }

      _user = user;
      await _persistLocalUserData(user);
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to sign in with Google. Please try again.';
      return false;
    }
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

  /// Instant signOut - clears session first so AuthGate returns to login immediately.
  /// Google / secure-storage cleanup is best-effort with short timeouts (can hang on web).
  Future<void> signOut() async {
    _busy = false;
    _error = null;
    _user = null;
    notifyListeners();

    await Future.wait<void>([
      () async {
        try {
          await GoogleSignIn.instance
              .signOut()
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
      }(),
      () async {
        try {
          await _apiService.clearToken().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }(),
      () async {
        try {
          final prefs = await SharedPreferences.getInstance()
              .timeout(const Duration(seconds: 2));
          await Future.wait([
            prefs.remove(_keyLoggedIn),
            prefs.remove(_keyEmail),
            prefs.remove(_keyPhoto),
            prefs.remove(_keyFullName),
            prefs.remove(_keyPhone),
            prefs.remove(_keyProfileComplete),
          ]).timeout(const Duration(seconds: 2));
        } catch (_) {}
      }(),
    ]);

    _busy = false;
    notifyListeners();
  }

  Future<void> clearLocalAccount() async {
    await signOut();
  }
}
