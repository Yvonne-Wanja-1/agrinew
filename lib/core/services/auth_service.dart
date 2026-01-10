import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService handles Firebase Authentication ONLY
/// Uses FirebaseAuth.instance.currentUser (single User, not a list)
/// No Firestore or Realtime Database dependencies
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current authenticated user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is authenticated
  static bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Email/Password Sign Up
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use. Please try another email.',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'signup-failed',
        message: 'Signup failed: ${e.toString()}',
      );
    }
  }

  // Email/Password Login
  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Google Sign In
  static Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-signin-cancelled',
          message: 'Google sign-in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'logout-failed',
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  // Delete account
  static Future<void> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No user logged in',
        );
      }

      // Re-authenticate user before deleting account
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'account-deletion-failed',
        message: 'Account deletion failed: ${e.toString()}',
      );
    }
  }

  // Get user email
  static String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'reset-email-failed',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  // Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
