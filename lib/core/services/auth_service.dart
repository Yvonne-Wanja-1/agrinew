import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// User model for local authentication
class LocalUser {
  final String uid;
  final String email;
  final bool emailVerified;
  final String? phoneNumber;
  final bool phoneVerified;

  LocalUser({
    required this.uid,
    required this.email,
    this.emailVerified = false,
    this.phoneNumber,
    this.phoneVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'emailVerified': emailVerified,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      phoneNumber: map['phoneNumber'],
      phoneVerified: map['phoneVerified'] ?? false,
    );
  }

  LocalUser copyWith({
    String? uid,
    String? email,
    bool? emailVerified,
    String? phoneNumber,
    bool? phoneVerified,
  }) {
    return LocalUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
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

/// Local Authentication Service - replaces Firebase Auth
/// Stores user accounts and authentication state in local storage
class AuthService {
  static late SharedPreferences _prefs;
  static LocalUser? _currentUser;
  static final List<Function(LocalUser?)> _listeners = [];

  // Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCurrentUser();
  }

  // Load current user from local storage
  static void _loadCurrentUser() {
    final userJson = _prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = LocalUser.fromMap(jsonDecode(userJson));
      debugPrint(
        '✅ [AUTH_SERVICE] Current user loaded: ${_currentUser?.email}',
      );
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
  }) async {
    try {
      email = email.trim().toLowerCase();
      password = password.trim();

      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      // Check if email already exists
      if (_userExists(email)) {
        throw AuthException(
          code: 'email-already-in-use',
          message: 'Email already in use. Please try another email.',
        );
      }

      // Create new user
      final uid = _generateUID();
      final hashedPassword = _hashPassword(password);

      final user = LocalUser(uid: uid, email: email, emailVerified: false);

      // Store user credentials and profile
      await _storeUserCredentials(email, hashedPassword);
      await _storeUserProfile(user);

      _currentUser = user;
      await _saveCurrentUser();
      _notifyListeners();

      debugPrint('✅ [AUTH_SERVICE] User signed up: $email');
      return user;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Sign up failed: $e');
      rethrow;
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

      // Retrieve user
      final userJson = _prefs.getString('user_profile_$email');
      if (userJson == null) {
        throw AuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // Verify password
      final storedHash = _prefs.getString('user_password_$email');
      if (storedHash == null || !_verifyPassword(password, storedHash)) {
        throw AuthException(
          code: 'wrong-password',
          message: 'Invalid password',
        );
      }

      _currentUser = LocalUser.fromMap(jsonDecode(userJson));
      await _saveCurrentUser();
      _notifyListeners();

      debugPrint('✅ [AUTH_SERVICE] User logged in: $email');
      return _currentUser!;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Login failed: $e');
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
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

      final email = _currentUser!.email;

      // Verify password before deletion
      final storedHash = _prefs.getString('user_password_$email');
      if (storedHash == null || !_verifyPassword(password, storedHash)) {
        throw AuthException(
          code: 'wrong-password',
          message: 'Invalid password',
        );
      }

      // Delete user data
      await _prefs.remove('user_profile_$email');
      await _prefs.remove('user_password_$email');
      _currentUser = null;
      await _prefs.remove('current_user');
      _notifyListeners();

      debugPrint('✅ [AUTH_SERVICE] Account deleted: $email');
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Account deletion failed: $e');
      rethrow;
    }
  }

  // Get user email
  static String? getUserEmail() {
    return _currentUser?.email;
  }

  // Send password reset email (local implementation)
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      email = email.trim().toLowerCase();

      if (!_userExists(email)) {
        throw AuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // In production, you would send an actual email here
      // For now, we'll just mark the user for password reset
      await _prefs.setString(
        'password_reset_requested_$email',
        DateTime.now().toIso8601String(),
      );

      debugPrint('✅ [AUTH_SERVICE] Password reset requested for: $email');
    } catch (e) {
      throw AuthException(
        code: 'reset-email-failed',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
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
        await _storeUserProfile(_currentUser!);
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
        await _storeUserProfile(_currentUser!);
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

  static bool _userExists(String email) {
    return _prefs.containsKey('user_profile_${email.toLowerCase()}');
  }

  static String _generateUID() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
  }

  static String _hashPassword(String password) {
    // Simple hash using base64 (for demo purposes only)
    // In production, use a proper password hashing library like bcrypt
    return base64Encode(utf8.encode(password));
  }

  static bool _verifyPassword(String password, String hash) {
    try {
      final decoded = utf8.decode(base64Decode(hash));
      return decoded == password;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _storeUserCredentials(
    String email,
    String passwordHash,
  ) async {
    await _prefs.setString(
      'user_password_${email.toLowerCase()}',
      passwordHash,
    );
  }

  static Future<void> _storeUserProfile(LocalUser user) async {
    await _prefs.setString(
      'user_profile_${user.email.toLowerCase()}',
      jsonEncode(user.toMap()),
    );
  }

  static Future<void> _saveCurrentUser() async {
    if (_currentUser != null) {
      await _prefs.setString('current_user', jsonEncode(_currentUser!.toMap()));
    }
  }
}
