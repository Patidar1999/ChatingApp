import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported message types (extensible for future media support)
enum MessageType { text }

/// Represents a single chat message.
/// Stored in Firestore: chats/{chatRoomId}/messages/{messageId}
class MessageModel {
  final String messageId;    // Unique ID for this message
  final String senderId;     // UID of the sender
  final String receiverId;   // UID of the receiver
  final String content;      // Message text content
  final MessageType type;    // text (extendable: image, audio, etc.)
  final DateTime sentAt;     // When the message was sent
  final bool isRead;         // Read receipt flag

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.sentAt,
    this.isRead = false,
  });

  /// Convert to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,       // Stores 'text', 'image', etc.
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  /// Create MessageModel from a Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
