import 'package:flutter/material.dart';
import 'package:agriclinichub_new/core/services/auth_service.dart';
import 'package:agriclinichub_new/features/auth/presentation/screens/login_screen.dart';
import 'package:agriclinichub_new/features/home/presentation/screens/home_screen.dart';
import 'package:agriclinichub_new/features/auth/presentation/screens/email_verification_screen.dart';

/// AuthGate listens to local auth state changes and routes users accordingly
/// - If logged in and email verified → Home
/// - If logged in but email not verified → Email Verification
/// - If not logged in → Login
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Subscribe to auth state changes
    AuthService.subscribe(_onAuthStateChanged);
  }

  @override
  void dispose() {
    AuthService.unsubscribe(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged(LocalUser? user) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();

    if (user == null) {
      // No user logged in
      debugPrint('🟢 [AUTH_GATE] No user logged in, showing Login screen');
      return const LoginScreen();
    } else if (user.emailVerified) {
      // User logged in and email verified
      debugPrint('🟢 [AUTH_GATE] User verified, showing Home screen');
      return const HomeScreen();
    } else {
      // User logged in but email not verified
      debugPrint(
        '🟢 [AUTH_GATE] User not verified, showing Email Verification',
      );
      return EmailVerificationScreen(email: user.email);
    }
  }
}
