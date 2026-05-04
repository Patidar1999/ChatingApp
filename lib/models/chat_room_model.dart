import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between two users.
/// Stored in Firestore: chats/{chatRoomId}
class ChatRoomModel {
  final String chatRoomId;         // Unique ID = phone1_phone2 (sorted)
  final List<String> participants; // UIDs of the two users
  final String lastMessage;        // Preview text for home screen
  final DateTime lastMessageTime;  // For sorting conversations
  final String lastMessageSenderId; // Who sent the last message

  const ChatRoomModel({
    required this.chatRoomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      chatRoomId: map['chatRoomId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
    );
  }
}
