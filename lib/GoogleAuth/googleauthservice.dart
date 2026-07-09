// google_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;

      // If a Google account is already cached, use it silently (no picker)
      final currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        googleUser = currentUser;
        debugPrint(
          '[GoogleAuthService] Using cached Google account: ${googleUser.email}',
        );
      } else {
        // No cached account → show the account picker
        googleUser = await _googleSignIn.signIn();
      }
 
      if (googleUser == null) {
        debugPrint('[GoogleAuthService] User cancelled sign-in');
        return null;
      }

      // Always get a fresh auth token (handles expiry automatically)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // Get fresh Firebase ID token to send to your backend
      final String? idToken = await userCredential.user?.getIdToken(true);
      debugPrint('[GoogleAuthService] Firebase idToken obtained');

      return idToken;
    } catch (e) {
      debugPrint('[GoogleAuthService] Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    debugPrint('[GoogleAuthService] Signed out from Google + Firebase');
  }
}
