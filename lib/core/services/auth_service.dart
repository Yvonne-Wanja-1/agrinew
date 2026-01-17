import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// User model (mirrors Supabase auth.users + farmers profile)
class LocalUser {
  final String uid;
  final String email;
  final bool emailVerified;
  final String? fullName;
  final String? phoneNumber;
  final bool phoneVerified;
  final String? county;

  LocalUser({
    required this.uid,
    required this.email,
    this.emailVerified = false,
    this.fullName,
    this.phoneNumber,
    this.phoneVerified = false,
    this.county,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'emailVerified': emailVerified,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'county': county,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      phoneVerified: map['phoneVerified'] ?? false,
      county: map['county'],
    );
  }

  LocalUser copyWith({
    String? uid,
    String? email,
    bool? emailVerified,
    String? fullName,
    String? phoneNumber,
    bool? phoneVerified,
    String? county,
  }) {
    return LocalUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      county: county ?? this.county,
    );
  }
}

/// Exception for authentication errors
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}

/// Supabase Authentication Service
/// Uses Supabase Auth for identity + farmers table for profile
class AuthService {
  static late SharedPreferences _prefs;
  static LocalUser? _currentUser;
  static final List<Function(LocalUser?)> _listeners = [];
  static late SupabaseClient _supabase;

  // Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _supabase = Supabase.instance.client;

    // Check if user is already logged in via Supabase session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserFromSupabase(session.user.id);
    } else {
      _currentUser = null;
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserFromSupabase(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _prefs.remove('current_user');
        _notifyListeners();
      }
    });

    debugPrint('✅ [AUTH_SERVICE] Initialized with Supabase Auth');
  }

  // Load user from Supabase and cache locally
  static Future<void> _loadUserFromSupabase(String uid) async {
    try {
      final response = await _supabase
          .from('farmers')
          .select()
          .eq('user_id', uid)
          .single();

      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null) {
        _currentUser = LocalUser(
          uid: uid,
          email: supabaseUser.email ?? '',
          emailVerified: supabaseUser.emailConfirmedAt != null,
          fullName: response['full_name'],
          phoneNumber: response['phone'],
          phoneVerified: false,
          county: response['county'],
        );

        await _saveCurrentUser();
        _notifyListeners();
        debugPrint('✅ [AUTH_SERVICE] User loaded: ${_currentUser?.email}');
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH_SERVICE] Failed to load user from Supabase: $e');
      // Still keep the user logged in, just without profile data yet
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null) {
        _currentUser = LocalUser(
          uid: uid,
          email: supabaseUser.email ?? '',
          emailVerified: supabaseUser.emailConfirmedAt != null,
        );
        await _saveCurrentUser();
        _notifyListeners();
      }
    }
  }

  // Get current authenticated user
  static LocalUser? getCurrentUser() {
    return _currentUser;
  }

  // Check if user is authenticated
  static bool isUserAuthenticated() {
    return _currentUser != null;
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _currentUser?.uid;
  }

  // Email/Password Sign Up
  static Future<LocalUser> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    String? county,
  }) async {
    try {
      email = email.trim().toLowerCase();
      password = password.trim();

      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException(
          code: 'signup-failed',
          message: 'Failed to create user',
        );
      }

      // Create farmer profile in farmers table
      await _supabase.from('farmers').insert({
        'user_id': user.id,
        'email': email,
        'full_name': fullName ?? '',
        'phone': phoneNumber,
        'county': county,
      });

      // Load user from Supabase
      await _loadUserFromSupabase(user.id);

      debugPrint('✅ [AUTH_SERVICE] User signed up: $email');
      return _currentUser!;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Sign up failed: $e');
      throw AuthException(code: 'signup-error', message: e.toString());
    }
  }

  // Email/Password Login
  static Future<LocalUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      email = email.trim().toLowerCase();
      password = password.trim();

      // Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException(code: 'login-failed', message: 'Failed to sign in');
      }

      // Load user from Supabase
      await _loadUserFromSupabase(user.id);

      debugPrint('✅ [AUTH_SERVICE] User logged in: $email');
      return _currentUser!;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Login failed: $e');
      throw AuthException(code: 'login-error', message: e.toString());
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      await _prefs.remove('current_user');
      _notifyListeners();
      debugPrint('✅ [AUTH_SERVICE] User logged out');
    } catch (e) {
      throw AuthException(
        code: 'logout-failed',
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  // Delete account
  static Future<void> deleteAccount({required String password}) async {
    try {
      if (_currentUser == null) {
        throw AuthException(code: 'no-user', message: 'No user logged in');
      }

      // Delete user from Supabase Auth (this also cascades to farmers table via FK)
      await _supabase.auth.admin.deleteUser(_currentUser!.uid);

      _currentUser = null;
      await _prefs.remove('current_user');
      _notifyListeners();

      debugPrint('✅ [AUTH_SERVICE] Account deleted: ${_currentUser?.email}');
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Account deletion failed: $e');
      throw AuthException(
        code: 'delete-account-failed',
        message: 'Failed to delete account: $e',
      );
    }
  }

  // Get user email
  static String? getUserEmail() {
    return _currentUser?.email;
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      email = email.trim().toLowerCase();
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ [AUTH_SERVICE] Password reset email sent to: $email');
    } catch (e) {
      throw AuthException(
        code: 'reset-email-failed',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  // Reset password (after user receives reset email)
  static Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      email = email.trim().toLowerCase();
      newPassword = newPassword.trim();

      if (newPassword.isEmpty) {
        throw AuthException(
          code: 'invalid-password',
          message: 'Password cannot be empty',
        );
      }

      if (newPassword.length < 6) {
        throw AuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters',
        );
      }

      // Send reset email via Supabase
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ [AUTH_SERVICE] Password reset email sent for: $email');
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Password reset failed: $e');
      rethrow;
    }
  }

  // Listen to auth state changes
  static Stream<LocalUser?> authStateChanges() {
    return Stream.periodic(Duration(milliseconds: 500), (_) => _currentUser);
  }

  // Subscribe to auth state changes
  static void subscribe(Function(LocalUser?) listener) {
    _listeners.add(listener);
  }

  // Unsubscribe from auth state changes
  static void unsubscribe(Function(LocalUser?) listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners of auth state change
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_currentUser);
    }
  }

  // Phone OTP verification (demo implementation)
  static final Map<String, String> _phoneOtpStorage = {};

  // Send phone OTP via SMS (demo implementation)
  static Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      phoneNumber = phoneNumber.trim();

      // Generate a random 6-digit OTP
      final random = DateTime.now().millisecondsSinceEpoch % 1000000;
      final otp = random.toString().padLeft(6, '0');

      // Store OTP in memory
      _phoneOtpStorage[phoneNumber] = otp;

      debugPrint('🟢 [AUTH_SERVICE] OTP for $phoneNumber: $otp (demo mode)');
      // In production, you would call an SMS service here like:
      // await _smsService.sendOtp(phoneNumber, otp);
    } catch (e) {
      throw AuthException(
        code: 'phone-otp-failed',
        message: 'Failed to send phone OTP: $e',
      );
    }
  }

  // Verify phone OTP
  static Future<bool> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      phoneNumber = phoneNumber.trim();
      otp = otp.trim();

      // For demo: accept any 6-digit code
      if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
        // In production, verify against stored OTP
        final storedOtp = _phoneOtpStorage[phoneNumber];
        if (storedOtp == otp) {
          debugPrint('✅ [AUTH_SERVICE] Phone OTP verified successfully');
          _phoneOtpStorage.remove(phoneNumber);
          return true;
        }

        // For demo, accept any 6-digit code
        debugPrint('✅ [AUTH_SERVICE] Phone OTP verified (demo mode)');
        _phoneOtpStorage.remove(phoneNumber);
        return true;
      }
      return false;
    } catch (e) {
      throw AuthException(
        code: 'otp-verification-failed',
        message: 'Failed to verify phone OTP: $e',
      );
    }
  }

  // Check if email is verified
  static Future<bool> isEmailVerified() async {
    try {
      if (_currentUser == null) {
        return false;
      }
      return _currentUser!.emailVerified;
    } catch (e) {
      throw AuthException(
        code: 'verification-check-failed',
        message: 'Failed to check email verification status: $e',
      );
    }
  }

  // Mark email as verified
  static Future<void> markEmailAsVerified() async {
    try {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(emailVerified: true);
        await _saveCurrentUser();
        _notifyListeners();
        debugPrint('✅ [AUTH_SERVICE] Email marked as verified');
      }
    } catch (e) {
      throw AuthException(
        code: 'verification-update-failed',
        message: 'Failed to update email verification status: $e',
      );
    }
  }

  // Check if phone is verified
  static bool isPhoneVerified() {
    return _currentUser?.phoneVerified ?? false;
  }

  // Mark phone as verified
  static Future<void> markPhoneAsVerified(String phoneNumber) async {
    try {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          phoneNumber: phoneNumber,
          phoneVerified: true,
        );
        await _saveCurrentUser();

        // Update in farmers table
        try {
          await _supabase
              .from('farmers')
              .update({'phone': phoneNumber})
              .eq('user_id', _currentUser!.uid);
        } catch (e) {
          debugPrint('⚠️ [AUTH_SERVICE] Failed to update phone in farmers: $e');
        }

        _notifyListeners();
        debugPrint('✅ [AUTH_SERVICE] Phone marked as verified');
      }
    } catch (e) {
      throw AuthException(
        code: 'phone-verification-update-failed',
        message: 'Failed to update phone verification status: $e',
      );
    }
  }

  // === Helper Methods ===

  static Future<void> _saveCurrentUser() async {
    if (_currentUser != null) {
      await _prefs.setString('current_user', jsonEncode(_currentUser!.toMap()));
    }
  }
}
