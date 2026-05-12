
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// Handles all Firebase Authentication operations.
/// Uses phone number + OTP for login/signup.
class AuthService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get currently logged-in user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Stream that emits user state changes (login/logout events)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ──────────────────────────────────────────────
  // STEP 1: Send OTP to phone number
  // ──────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,

        // Called when OTP is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },

        // Called if verification fails
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed. Try again.');
        },

        // Called on Android if SMS is auto-detected
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },

        // Called when the verification code expires (usually 60 seconds)
        codeAutoRetrievalTimeout: (String verificationId) {
          // OTP expired — user must request a new one
        },

        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  // ──────────────────────────────────────────────
  // STEP 2: Verify OTP entered by user
  // ──────────────────────────────────────────────
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    // Create a credential using the verification ID and OTP
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    // Sign in with the credential
    return await _auth.signInWithCredential(credential);
  }

  // ──────────────────────────────────────────────
  // Create or update user in Firestore after login
  // ──────────────────────────────────────────────
  Future<void> saveUserToFirestore({
    required String uid,
    required String phone,
    required String name,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      // New user — create their profile
      final user = UserModel(
        uid: uid,
        phone: phone,
        name: name,
        createdAt: DateTime.now(),
      );
      await docRef.set(user.toMap());
    }
    // If user already exists, we don't overwrite their profile
  }

  // ──────────────────────────────────────────────
  // Fetch current user's profile from Firestore
  // ──────────────────────────────────────────────
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Sign out the current user
  // ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
