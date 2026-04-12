import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

class AuthRepository {
  final FirebaseAuth _auth;
  bool _isGoogleSignInInitialized = false;

  AuthRepository(this._auth);

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() async {
    if (!kIsWeb && !_isGoogleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

  Future<void> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      if (kIsWeb) {
        // Firebase Auth natively supports Web Google Sign-In with its own popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        // Android / iOS native Google Sign-In
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          // Cross-feature call (repository using provider is tricky, usually done in controller or passed ref)
          // For now, we'll implement a simple Firestore call or assume the repository has access.
          // Better: pass the userRepository as a dependency to AuthRepository.
        }
      }
    } catch (e) {
      // Handles cancellations and other errors natively thrown by authenticate()
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
