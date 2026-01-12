import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agriclinichub_new/features/auth/presentation/screens/login_screen.dart';
import 'package:agriclinichub_new/features/home/presentation/screens/home_screen.dart';
import 'package:agriclinichub_new/features/auth/presentation/screens/email_verification_screen.dart';

/// AuthGate listens to Firebase auth state changes and routes users accordingly
/// - If logged in and email verified → Home
/// - If logged in but email not verified → Email Verification
/// - If not logged in → Login
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
          '🟢 [AUTH_GATE] Auth state changed: ${snapshot.data?.email}',
        );

        // Connection is active and we have a user
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            // No user logged in
            debugPrint(
              '🟢 [AUTH_GATE] No user logged in, showing Login screen',
            );
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
            return EmailVerificationScreen(user: user, email: user.email ?? '');
          }
        }

        // Loading state
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade600, Colors.green.shade400],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Agri Clinic Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Farming Assistant',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
