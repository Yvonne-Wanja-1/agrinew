import 'package:flutter/foundation.dart';
import 'dart:async';

/// EmailOtpService handles email-based OTP sending and verification
/// Generates and validates OTPs locally for testing
/// For production, integrate with email service (SendGrid, Mailgun, etc.)
class EmailOtpService {
  static final EmailOtpService _instance = EmailOtpService._internal();

  factory EmailOtpService() {
    return _instance;
  }

  EmailOtpService._internal();

  // In-memory storage for OTPs (for demo/testing)
  // In production, this would be validated against backend-sent codes
  static final Map<String, String> _emailOtpStorage = {};
  static final Map<String, DateTime> _otpExpiry = {};

  // OTP validity duration (5 minutes)
  static const Duration _otpValidityDuration = Duration(minutes: 5);

  /// Send a 4-digit OTP via email
  /// In production, integrate with an email service
  Future<void> sendEmailOtp({required String email}) async {
    try {
      debugPrint('🟢 [EMAIL_OTP_SERVICE] Sending 4-digit OTP to $email');

      // Generate a 4-digit OTP
      final random = (DateTime.now().millisecondsSinceEpoch % 10000)
          .toString()
          .padLeft(4, '0');
      final otp = random;

      // Store OTP with expiry time
      _emailOtpStorage[email] = otp;
      _otpExpiry[email] = DateTime.now().add(_otpValidityDuration);

      debugPrint(
        '🟢 [EMAIL_OTP_SERVICE] OTP for $email: $otp (expires in 5 minutes)',
      );

      // In production, you would call a Cloud Function like:
      // await _firebaseCloudFunctions.httpsCallable('sendEmailOtp').call({
      //   'email': email,
      //   'otp': otp,
      // });

      // For now, log it for development/testing
      // In a real app, the backend should send this via email service (e.g., SendGrid, Mailgun)
    } catch (e) {
      debugPrint('🔴 [EMAIL_OTP_SERVICE] Error sending OTP: $e');
      throw Exception('Failed to send email OTP: $e');
    }
  }

  /// Verify the email OTP
  /// Returns true if OTP is valid and not expired
  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      debugPrint('🟢 [EMAIL_OTP_SERVICE] Verifying OTP for $email');

      // Check if OTP exists
      if (!_emailOtpStorage.containsKey(email)) {
        debugPrint('🔴 [EMAIL_OTP_SERVICE] No OTP found for $email');
        return false;
      }

      // Check if OTP has expired
      final expiry = _otpExpiry[email];
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        debugPrint('🔴 [EMAIL_OTP_SERVICE] OTP expired for $email');
        _emailOtpStorage.remove(email);
        _otpExpiry.remove(email);
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Verify OTP
      final storedOtp = _emailOtpStorage[email];
      if (storedOtp == otp) {
        debugPrint('✅ [EMAIL_OTP_SERVICE] Email OTP verified for $email');

        // Clear OTP after successful verification
        _emailOtpStorage.remove(email);
        _otpExpiry.remove(email);

        return true;
      }

      debugPrint('🔴 [EMAIL_OTP_SERVICE] Invalid OTP for $email');
      return false;
    } catch (e) {
      debugPrint('🔴 [EMAIL_OTP_SERVICE] Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Resend OTP with cooldown period
  Future<void> resendEmailOtp({
    required String email,
    required User user,
  }) async {
    try {
      // Clear old OTP and send new one
      _emailOtpStorage.remove(email);
      _otpExpiry.remove(email);

      await sendEmailOtp(email: email, user: user);
    } catch (e) {
      debugPrint('🔴 [EMAIL_OTP_SERVICE] Error resending OTP: $e');
      rethrow;
    }
  }

  /// Get remaining time for OTP expiry
  Duration? getOtpExpiryTime(String email) {
    final expiry = _otpExpiry[email];
    if (expiry == null) return null;

    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return null;

    return remaining;
  }

  /// Clear all stored OTPs (for logout or testing)
  void clearAllOtps() {
    _emailOtpStorage.clear();
    _otpExpiry.clear();
    debugPrint('🟢 [EMAIL_OTP_SERVICE] All OTPs cleared');
  }
}
