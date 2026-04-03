import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInCancelledException implements Exception {
  final String message;
  SignInCancelledException([this.message = 'Sign in was cancelled.']);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Email/Password Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
    return credential;
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign In (v7 API)
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    try {
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException {
      throw SignInCancelledException('Google sign in was cancelled.');
    }
  }

  // Apple Sign In
  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final userCredential =
        await _firebaseAuth.signInWithCredential(oauthCredential);

    // Apple only sends name on first sign in
    if (appleCredential.givenName != null && userCredential.user != null) {
      final name =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
      if (name.isNotEmpty) {
        await userCredential.user!.updateDisplayName(name);
      }
    }
    return userCredential;
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore — user may not have signed in with Google
    }
  }

  // Re-authenticate before sensitive operations
  Future<void> reauthenticate() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final providerIds = user.providerData.map((p) => p.providerId).toList();

    if (providerIds.contains('google.com')) {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await user.reauthenticateWithCredential(credential);
    } else if (providerIds.contains('apple.com')) {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(oauthCredential);
    }
    // For email/password, reauthentication needs password — handled via dialog
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await user.delete();
  }

  // Check if Apple Sign In is available (only on iOS 13+)
  bool get isAppleSignInAvailable => Platform.isIOS;
}
