import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyEmail = 'auth_email';
  static const _keyPhoto = 'auth_photo';
  static const _keyFullName = 'auth_full_name';
  static const _keyPhone = 'auth_phone';
  static const _keyProfileComplete = 'auth_profile_complete';

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
  bool get needsProfileSetup =>
      _user != null && !_user!.profileComplete;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();

    try {
      await _initGoogle();
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
      // Keep going with empty session.
    } finally {
      _loading = false;
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

  /// Sign in with Gmail / Google. Falls back to a demo session if Google
  /// OAuth is not configured yet (frontend testing).
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
          // Frontend placeholder until Google Cloud client IDs are added.
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

    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    if (photoUrl != null) {
      await prefs.setString(_keyPhoto, photoUrl);
    } else {
      await prefs.remove(_keyPhoto);
    }
    if (!alreadyComplete) {
      await prefs.setBool(_keyProfileComplete, false);
      if (name.isNotEmpty) {
        await prefs.setString(_keyFullName, name);
      }
    }
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
      final prefs = await SharedPreferences.getInstance();
      final updated = _user!.copyWith(
        fullName: name,
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        profileComplete: true,
      );
      _user = updated;
      await prefs.setString(_keyFullName, updated.fullName);
      if (updated.phone != null) {
        await prefs.setString(_keyPhone, updated.phone!);
      } else {
        await prefs.remove(_keyPhone);
      }
      await prefs.setBool(_keyProfileComplete, true);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, false);
      // Keep profile fields so returning Google user can be recognized,
      // but require login again. Clear session user.
      _user = null;
      _error = null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Clears everything — useful to retest first-time onboarding.
  Future<void> clearLocalAccount() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
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
