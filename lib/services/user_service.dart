import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// Handles user profile read/write operations.
/// Separating this from AuthService keeps each service focused.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ──────────────────────────────────────────────
  // Get a user's profile by their UID
  // ──────────────────────────────────────────────
  Future<UserModel?> getUserById(String uid) async {
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
  // Get a user's profile by their phone number
  // ──────────────────────────────────────────────
  Future<UserModel?> getUserByPhone(String phone) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Update user's display name
  // ──────────────────────────────────────────────
  Future<void> updateUserName(String uid, String newName) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'name': newName});
  }

  // ──────────────────────────────────────────────
  // Upload profile photo and update Firestore
  // ──────────────────────────────────────────────
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    // Define storage path for this user's profile image
    final ref = _storage
        .ref()
        .child(AppConstants.profileImagesPath)
        .child('$uid.jpg');

    // Upload the file
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Get the download URL
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Save the URL to Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'photoUrl': downloadUrl});

    return downloadUrl;
  }

  // ──────────────────────────────────────────────
  // Real-time stream of a user's profile (for live updates)
  // ──────────────────────────────────────────────
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }
}
