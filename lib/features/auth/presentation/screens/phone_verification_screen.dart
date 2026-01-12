import 'package:flutter/material.dart';
import 'package:agriclinichub_new/core/services/sms_otp_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const PhoneVerificationScreen({Key? key, this.phoneNumber}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _smsOtpService = SmsOtpService();
  bool _isLoading = false;
  bool _isResending = false;
  bool _phoneEntered = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      _phoneController.text = phoneNumber!;
      _phoneEntered = true;
    }
  }

  String? get phoneNumber => widget.phoneNumber;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Add +254 if it's a Kenya number starting with 7, 6, 1
    if (digits.length >= 9 && !digits.startsWith('254')) {
      if (digits.startsWith('0')) {
        return '+254${digits.substring(1)}';
      } else if (digits.length == 9) {
        return '+254$digits';
      }
    }

    if (!digits.startsWith('+')) {
      return '+$digits';
    }

    return digits;
  }

  bool _isValidPhoneNumber(String phone) {
    final formatted = _formatPhoneNumber(phone);
    // Check if it's a valid format (at least +254 and 9 more digits)
    return RegExp(r'^\+\d{10,15}$').hasMatch(formatted);
  }

  Future<void> _sendPhoneOtp() async {
    if (!_isValidPhoneNumber(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Color.fromARGB(255, 244, 67, 54),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      debugPrint('🟢 [PHONE_OTP] Sending OTP to $formattedPhone');

      // Send SMS OTP
      await _smsOtpService.sendSmsOtp(phoneNumber: formattedPhone);

      debugPrint('✅ [PHONE_OTP] OTP sent successfully');

      if (mounted) {
        setState(() => _phoneEntered = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('6-digit code sent via SMS'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 [PHONE_OTP] Error sending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code must be 6 digits')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      debugPrint('🟢 [PHONE_OTP] Verifying OTP for $formattedPhone');

      // Verify the OTP
      final isValid = await _smsOtpService.verifySmsOtp(
        phoneNumber: formattedPhone,
        otp: _otpController.text,
      );

      if (isValid) {
        debugPrint('✅ [PHONE_OTP] Phone verified successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to home after a short delay
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      debugPrint('🔴 [PHONE_OTP] Verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      await _smsOtpService.resendSmsOtp(phoneNumber: formattedPhone);
      setState(() => _resendCountdown = 60);
      _otpController.clear();

      // Countdown timer
      for (int i = 60; i > 0; i--) {
        if (mounted) {
          setState(() => _resendCountdown = i);
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _skipVerification() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Skip Phone Verification?'),
        content: const Text(
          'You can verify your phone number later from settings. Continue without verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade600, Colors.green.shade400],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                              Icons.phone_outlined,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Verify Your Phone',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We\'ll send a verification code via SMS',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (!_phoneEntered) ...[
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            enabled: !_isLoading,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '+254 712 345 678',
                              hintStyle: TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendPhoneOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Send Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Verification Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpController,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 4,
                            ),
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyPhoneOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Verify Phone',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Didn\'t receive code?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                if (_resendCountdown > 0)
                                  Text(
                                    'Resend in ${_resendCountdown}s',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: _isResending ? null : _resendOtp,
                                    child: Text(
                                      'Resend Code',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skipVerification,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Skip for Now'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}