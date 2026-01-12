import 'package:flutter/foundation.dart';

/// SmsOtpService handles SMS-based OTP sending and verification
/// Uses Firebase Cloud Functions (backend) to send actual SMS
class SmsOtpService {
  static final SmsOtpService _instance = SmsOtpService._internal();

  factory SmsOtpService() {
    return _instance;
  }

  SmsOtpService._internal();

  // In-memory storage for OTPs (for demo/testing)
  // In production, this would be validated against backend-sent codes
  static final Map<String, String> _phoneOtpStorage = {};
  static final Map<String, DateTime> _otpExpiry = {};

  // OTP validity duration (5 minutes)
  static const Duration _otpValidityDuration = Duration(minutes: 5);

  /// Send a 6-digit OTP via SMS
  /// In production, this calls a Firebase Cloud Function that sends actual SMS
  Future<void> sendSmsOtp({required String phoneNumber}) async {
    try {
      debugPrint('🟢 [SMS_OTP_SERVICE] Sending SMS OTP to $phoneNumber');

      // Generate a 6-digit OTP
      final random = (DateTime.now().millisecondsSinceEpoch % 1000000)
          .toString()
          .padLeft(6, '0');
      final otp = random;

      // Store OTP with expiry time
      _phoneOtpStorage[phoneNumber] = otp;
      _otpExpiry[phoneNumber] = DateTime.now().add(_otpValidityDuration);

      debugPrint(
        '🟢 [SMS_OTP_SERVICE] OTP for $phoneNumber: $otp (expires in 5 minutes)',
      );

      // In production, you would call a Cloud Function like:
      // await _firebaseCloudFunctions.httpsCallable('sendSmsOtp').call({
      //   'phoneNumber': phoneNumber,
      //   'otp': otp,
      // });

      // For now, log it for development/testing
      // In a real app, the backend should send this via SMS service (e.g., Twilio, AWS SNS)
    } catch (e) {
      debugPrint('🔴 [SMS_OTP_SERVICE] Error sending OTP: $e');
      throw Exception('Failed to send SMS OTP: $e');
    }
  }

  /// Verify the SMS OTP
  /// Returns true if OTP is valid and not expired
  Future<bool> verifySmsOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      debugPrint('🟢 [SMS_OTP_SERVICE] Verifying OTP for $phoneNumber');

      // Check if OTP exists
      if (!_phoneOtpStorage.containsKey(phoneNumber)) {
        debugPrint('🔴 [SMS_OTP_SERVICE] No OTP found for $phoneNumber');
        return false;
      }

      // Check if OTP has expired
      final expiry = _otpExpiry[phoneNumber];
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        debugPrint('🔴 [SMS_OTP_SERVICE] OTP expired for $phoneNumber');
        _phoneOtpStorage.remove(phoneNumber);
        _otpExpiry.remove(phoneNumber);
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Verify OTP
      final storedOtp = _phoneOtpStorage[phoneNumber];
      if (storedOtp == otp) {
        debugPrint('✅ [SMS_OTP_SERVICE] SMS OTP verified for $phoneNumber');

        // Clear OTP after successful verification
        _phoneOtpStorage.remove(phoneNumber);
        _otpExpiry.remove(phoneNumber);

        return true;
      }

      debugPrint('🔴 [SMS_OTP_SERVICE] Invalid OTP for $phoneNumber');
      return false;
    } catch (e) {
      debugPrint('🔴 [SMS_OTP_SERVICE] Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Resend OTP
  Future<void> resendSmsOtp({required String phoneNumber}) async {
    try {
      // Clear old OTP and send new one
      _phoneOtpStorage.remove(phoneNumber);
      _otpExpiry.remove(phoneNumber);

      await sendSmsOtp(phoneNumber: phoneNumber);
    } catch (e) {
      debugPrint('🔴 [SMS_OTP_SERVICE] Error resending OTP: $e');
      rethrow;
    }
  }

  /// Get remaining time for OTP expiry
  Duration? getOtpExpiryTime(String phoneNumber) {
    final expiry = _otpExpiry[phoneNumber];
    if (expiry == null) return null;

    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return null;

    return remaining;
  }

  /// Clear all stored OTPs (for logout or testing)
  void clearAllOtps() {
    _phoneOtpStorage.clear();
    _otpExpiry.clear();
    debugPrint('🟢 [SMS_OTP_SERVICE] All OTPs cleared');
  }
}
