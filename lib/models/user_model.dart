import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a registered user in the app.
/// This model maps to a Firestore document in the 'users' collection.
class UserModel {
  final String uid;          // Firebase Auth UID
  final String phone;        // Phone number (used as unique identifier)
  final String name;         // Display name
  final String? photoUrl;    // Profile photo URL from Firebase Storage
  final DateTime createdAt;  // Account creation timestamp

  const UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.photoUrl,
    required this.createdAt,
  });

  /// Convert UserModel to a Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a UserModel from a Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? 'Unknown',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy of the model with updated fields
  UserModel copyWith({
    String? name,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      phone: phone,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
