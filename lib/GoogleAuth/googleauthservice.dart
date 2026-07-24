import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> signInWithGoogle() async {
    debugPrint('[GoogleAuthService] ── signInWithGoogle() START ──');
    try {
      // Force a clean slate before every sign-in so the picker always
      // shows, instead of silently reusing a cached account.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[GoogleAuthService] ❌ User cancelled sign-in');
        return null;
      }
      debugPrint('[GoogleAuthService] ✅ Account selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken(true);

      debugPrint('[GoogleAuthService] ── signInWithGoogle() END (success) ──');
      return idToken;
    } catch (e, stack) {
      debugPrint('[GoogleAuthService] ❌ Error: $e');
      debugPrint('[GoogleAuthService] Stack trace: $stack');
      return null;
    }
  }

  Future<void> signOut() async {
    debugPrint('[GoogleAuthService] ── signOut() START ──');
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('[GoogleAuthService] ⚠️ disconnect() failed: $e');
    }
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    debugPrint('[GoogleAuthService] ── signOut() END ──');
  }
}
