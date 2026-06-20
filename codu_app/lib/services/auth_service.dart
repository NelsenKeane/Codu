import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Private constructor for singleton pattern
  AuthService._internal();

  // The single instance of AuthService
  static final AuthService _instance = AuthService._internal();

  // Factory constructor to return the singleton instance
  factory AuthService() => _instance;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up user with Email and Password, and update their display name profile
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user display name profile after successful sign up
      if (credential.user != null) {
        await credential.user!.updateDisplayName(fullName.trim());
        await credential.user!.reload();
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected signup error occurred: $e');
    }
  }

  /// Sign in user with Email and Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected login error occurred: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('An error occurred during logout: $e');
    }
  }
}
